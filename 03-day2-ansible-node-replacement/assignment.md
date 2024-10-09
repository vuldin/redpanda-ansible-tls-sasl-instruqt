---
slug: day2-ansible-node-replacement
id: skyb9xnbnin7
type: challenge
title: Replacing a node with Ansible
teaser: A short description of the challenge.
notes:
- type: text
  contents: |-
    Now we continue to the first cluster operation: replacing nodes (and decommissioning Redpanda).

    ![skate.png](../assets/skate.png)
tabs:
- id: pruxd48ojp7k
  title: Shell
  type: terminal
  hostname: server
difficulty: ""
timelimit: 600
---
This scenario focuses on adding and removing brokers within a running Redpanda cluster. One of the most common reasons for this would be to change the underlying hardware or instance/VM type for each broker. Adding or removing brokers will change the number of brokers in the cluster, and you should always consider how this could impact your cluster:

- Availability: do you have enough brokers to span across all racks and/or availability zones?
- Cost: infrastructure costs will be impacted by a change in broker count
- Data retention: storage capacity and possible retention values are determined in large part by the local disk capacity across all brokers
- Durability: you should have more brokers than your lowest partition replication factor (normally this is 3)
- Partition count: this value is determined primarily by the CPU core count of the overall cluster

See [our docs](https://docs.redpanda.com/current/manage/cluster-maintenance/decommission-brokers/) for more details on the above considerations.

## Validate new instances

We will be updating the ansible config with details for a new broker, so a VM instance must already be available prior to starting the steps in this track. We automatically brought up an additional VM when we started this environment, and details on the VMs we have available are in [this file](https://github.com/vuldin/redpanda-instruqt-day2-ansible/blob/june20-presentation-updates/config.yml).

> Note: In your environment, you would likely use Terraform to add the additional node.

## Validate Cluster Health

Verify the cluster is healthy:

```bash,run
rpk cluster health
```

Output:

```bash,nocopy
CLUSTER HEALTH OVERVIEW
=======================
Healthy:                          true
Unhealthy reasons:                []
Controller ID:                    0
All nodes:                        [0 1 2]
Nodes down:                       []
Leaderless partitions (0):        []
Under-replicated partitions (0):  []
```

## Add additional broker

We will first add an additional broker before decommissioning any existing brokers. This is primarily to ensure the cluster healthy and all partitions remain fully replicated (3 brokers are needed in order to ensure replica factor of 3 is maintained).

Create a new `hosts.ini` file that adds node-d and marks the original brokers with `skip_node=true`:

```bash,run
cd deployment-automation
IP_A=$(nslookup node-a | grep Address | tail -1 | cut -f2 -d' ')
IP_B=$(nslookup node-b | grep Address | tail -1 | cut -f2 -d' ')
IP_C=$(nslookup node-c | grep Address | tail -1 | cut -f2 -d' ')
IP_D=$(nslookup node-d | grep Address | tail -1 | cut -f2 -d' ')

cat << EOF > hosts.ini
[redpanda]
node-a ansible_user=root ansible_become=True private_ip=${IP_A} id=0 skip_node=true
node-b ansible_user=root ansible_become=True private_ip=${IP_B} id=1 skip_node=true
node-c ansible_user=root ansible_become=True private_ip=${IP_C} id=2 skip_node=true
node-d ansible_user=root ansible_become=True private_ip=${IP_D} id=3
EOF
```

Run the playbook to install the new broker:

```bash,run
export DEPLOYMENT_PREFIX=instruqt
export ANSIBLE_COLLECTIONS_PATH=$(realpath .)/artifacts/collections
export ANSIBLE_ROLES_PATH=$(realpath .)/artifacts/roles
export ANSIBLE_INVENTORY=$(realpath .)/artifacts/hosts_gcp_$DEPLOYMENT_PREFIX.ini
ansible-playbook --private-key ~/.ssh/id_rsa -v ansible/provision-cluster.yml -i hosts.ini -e redpanda_version=24.1.8-1
```

> Note: We are pinning `redpanda_version` to the same version as the other brokers (otherwise this playbook would automatically choose the latest version).

## Update rpk profile

Let's add the new broker to a temporary rpk profile, which will allow communication between rpk and all brokers. First create a file containing an updated version of the existing profile:

```bash,run
rpk profile print | yq '.kafka_api.brokers += [ "node-d:9092" ],.admin_api.addresses += [ "node-d:9644" ]' > tmp-redpanda
```

Then use this file to create a new temporary profile (for use only while this temporary broker exists):

```bash,run
rpk profile create tmp-redpanda --from-profile tmp-redpanda
```

## Verify cluster health

Ensure the cluster is healthy after adding the additional broker:

```bash,run
rpk cluster health
```

We now see 4 brokers:

```bash,nocopy
CLUSTER HEALTH OVERVIEW
=======================
Healthy:                          true
Unhealthy reasons:                []
Controller ID:                    0
All nodes:                        [0 1 2 3]
Nodes down:                       []
Leaderless partitions (0):        []
Under-replicated partitions (0):  []
```

Also get details on the advertised listeners:

```bash,run
rpk cluster info
```

We can see in this command's output that there are 4 brokers, and `node-d` is the 4th broker in the cluster.

## Decommission a broker

We will now decommission one of the original brokers. Keep in mind that our motivation for doing this is to replace the underlying hardware or VM.

```bash,run
rpk redpanda admin brokers decommission 0

```

Now check the decommission status:

```bash,run
rpk redpanda admin brokers decommission-status 0
```

Eventually you will see:

```bash,nocopy
Node 0 is decommissioned successfully.
```

## Verify cluster health

We can now verify the cluster remains healthy and that there are no under-replicated partitions:

```bash,run
rpk cluster health
```

Output:

```bash,nocopy
CLUSTER HEALTH OVERVIEW
=======================
Healthy:                          true
Unhealthy reasons:                []
Controller ID:                    1
All nodes:                        [1 2 3]
Nodes down:                       []
Leaderless partitions (0):        []
Under-replicated partitions (0):  []
```

At this point we have:
1. added a new broker to ensure the cluster remains healthy
2. removed one of the existing brokers
3. verified cluster health

With the first broker removed we would now add a new replacement broker, and continue decommissioning and then adding in a new broker until all underlying VM instances have been replaced.

Click 'Next' in the bottom right to continue to the next assignment.
