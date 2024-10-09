#!/usr/bin/env bash

# handle key-value args
declare -A params
dnsnum=0
ipnum=0
domainnum=0

# loop through the arguments passed to the script
for arg in "$@"
do
  # check if the argument is in the form key=value
  if [[ $arg == *=* ]]; then
    key=${arg%%=*}  # extract everything before '=' as key
    # determine if key is DNS or IP, add appropriate sequential num to make unique
    if [[ $key == dns ]]; then
      key=$key$dnsnum
      let "dnsnum++"
    fi
    if [[ $key == ip ]]; then
      key=$key$ipnum
      let "ipnum++"
    fi
    value=${arg#*=} # extract everything after '=' as value
    if [[ -n "${params[$key]}" ]]; then
      echo "ERROR: $key already has a value ${params[$key]} (cannot set to $value)"
      exit 1
    else
      params["$key"]="$value"
    fi
  else
    # assume args that aren't key-value pairs are a domain name
    key=domain$domainnum
    let "domainnum++"
    value=$arg
    if [[ -n "${params[$key]}" ]]; then
      echo "ERROR: $key already has a value ${params[$key]} (cannot set to $value)"
      exit 1
    else
      params["$key"]="$value"
    fi
  fi
done

mkdir certs private-ca-key

rm -f index.txt serial.txt
touch index.txt
echo '01' > serial.txt

# create the openssl certificate authority config file
cat > ca.cnf <<EOF
# OpenSSL CA configuration file
[ ca ]
default_ca = CA_default
[ CA_default ]
default_days = 365
database = index.txt
serial = serial.txt
default_md = sha256
copy_extensions = copy
unique_subject = no
# Used to create the CA certificate.
[ req ]
prompt=no
distinguished_name = distinguished_name
x509_extensions = extensions
[ distinguished_name ]
organizationName = Redpanda
commonName = Redpanda CA
[ extensions ]
keyUsage = critical,digitalSignature,nonRepudiation,keyEncipherment,keyCertSign
basicConstraints = critical,CA:true,pathlen:1
# Common policy for nodes and users.
[ signing_policy ]
organizationName = supplied
commonName = optional
# Used to sign node certificates.
[ signing_node_req ]
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
# Used to sign client certificates.
[ signing_client_req ]
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl genrsa -out private-ca-key/ca.key 2048
chmod 400 private-ca-key/ca.key

openssl req \
-new \
-x509 \
-config ca.cnf \
-key private-ca-key/ca.key \
-days 365 \
-batch \
-out certs/ca.key

openssl req \
-new -x509 \
-config ca.cnf \
-key private-ca-key/ca.key \
-days 365 \
-batch \
-out certs/ca.crt

cat > node.cnf <<EOF
# OpenSSL node configuration file
[ req ]
prompt=no
distinguished_name = distinguished_name
req_extensions = extensions
[ distinguished_name ]
organizationName = Redpanda
[ extensions ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
DNS.2 = redpanda
DNS.3 = console
DNS.4 = connect
DNS.5 = "*.redpanda.redpanda.svc.cluster.local"
DNS.6 = "*.redpanda.redpanda.svc"
DNS.7 = "*.redpanda.redpanda"
IP.1 = 127.0.0.1
EOF

dnsnum=8
ipnum=2
for key in "${!params[@]}"; do
  if [[ $key == domain* ]]; then
    echo "DNS.$dnsnum = \"*.${params[$key]}\"" >> node.cnf
    let "dnsnum++"
  fi
  if [[ $key == dns* ]]; then
    echo "DNS.$dnsnum = ${params[$key]}" >> node.cnf
    let "dnsnum++"
  fi
  if [[ $key == ip* ]]; then
    echo "IP.$ipnum = ${params[$key]}" >> node.cnf
    let "ipnum++"
  fi
done

openssl genrsa -out certs/node.key 2048
chmod 400 certs/node.key

openssl req \
-new \
-config node.cnf \
-key certs/node.key \
-out node.csr \
-batch

openssl ca \
-config ca.cnf \
-keyfile private-ca-key/ca.key \
-cert certs/ca.crt \
-policy signing_policy \
-extensions signing_node_req \
-out certs/node.crt \
-outdir certs/ \
-in node.csr \
-batch

openssl x509 -in certs/node.crt -text | grep "X509v3 Subject Alternative Name" -A 1

mv node.csr certs/
rm ca.cnf index.txt index.txt.attr index.txt.old node.cnf serial.txt serial.txt.old

