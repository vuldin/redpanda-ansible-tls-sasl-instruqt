---
slug: day2-ansible-overview
id: ldu00oyxorh8
type: challenge
title: Overview
teaser: This section provides an overview of the initial state of the cluster and
  how this configuration was done, along with an overview of tools we will use throughout
  the lab.
notes:
- type: text
  contents: |-
    This track makes use of a 3-broker Redpanda cluster. You will walk through the configuration for Ansible, Redpanda, networking, and the various tools to interact with this environment.

    Please wait while the VMs are deployed and the Redpanda cluster is started and configured.

    ![skate.png](../assets/skate.png)
tabs:
- id: 4imyedroi4ro
  title: server
  type: terminal
  hostname: server
- id: fhow5m89a7rg
  title: node-a
  type: terminal
  hostname: node-a
- id: crxvajo1qdjj
  title: node-b
  type: terminal
  hostname: node-b
- id: mru6wznjeix2
  title: node-c
  type: terminal
  hostname: node-c
difficulty: ""
timelimit: 600
---
This track focused on ansible-based deployments, making use of the [deployment-automation](https://github.com/redpanda-data/deployment-automation/) project. For detailed information about this deployment approach, see the [Redpanda documentation](https://docs.redpanda.com/current/deploy/deployment-option/self-hosted/manual/production/production-deployment-automation/).

This assignment (or challenge if you are familiar with Instruqt) is here to explain how this environment was configured and deployed. There are no required commands; instead you will be given commands to run that will verify the cluster and peripheral environment is in working order.

Expand each section to view details, then click 'Next' at the bottom right once you have gone through all the content.

Tools
===============

The following tools are already installed in your environment:
- `rpk`: lets you manage your entire Redpanda cluster without the need to run a separate script for each function, as with Apache Kafka. The `rpk` commands handle everything from configuring nodes and kernel tuning to acting as a client to produce and consume data.
- `yq`: a lightweight and portable command-line YAML processor written in Go
- `ansible`: a collection of CLIs used to deploy applications (like Redpanda), including `ansible-galaxy` and `ansible-playbook`
- `ssh`: Used to open a remote terminal on the Redpanda brokers

> Note: In a real environment, you'll need password-less SSH access from your Ansible host to your cluster nodes. Here in the Instruqt environment, SSH is already configured.

Ansible
===============

Ansible requires a few environment variables in order to work properly. The following commands are ran to set the variable values:

```bash,nocopy
export DEPLOYMENT_PREFIX=instruqt
export ANSIBLE_COLLECTIONS_PATH=$(realpath .)/artifacts/collections
export ANSIBLE_ROLES_PATH=$(realpath .)/artifacts/roles
export ANSIBLE_INVENTORY=$(realpath .)/artifacts/hosts_gcp_$DEPLOYMENT_PREFIX.ini
```

These environment variables are set for this environment prior to deployment in [this script](https://github.com/vuldin/redpanda-instruqt-day2-ansible/blob/june20-presentation-updates/01-deploying-a-cluster-with-ansible/setup-server#L9-L12).

> Note: The paths are found within the deployment-automation project. If you are running the above commands in your own environment, make sure to run the above commands from within the `deployment-automation` folder. More details are in [our docs](https://docs.redpanda.com/current/deploy/deployment-option/self-hosted/manual/production/production-deployment-automation/#prerequisites).

In this environment we have deployed Redpand with the [provision-cluster](https://github.com/redpanda-data/deployment-automation/blob/main/ansible/provision-cluster.yml) playbook. There are a few different playbooks to choose from when you deploy Redpanda, and each can be found in the `ansible` folder:

```bash,run
cd deployment-automation
find ansible/ -name "*.yml" | sort
```

Output:

```bash,nocopy
ansible/airgap/bundle-deb-for-airgap.yml
ansible/airgap/bundle-rpm-for-airgap.yml
ansible/airgap/provision-private-proxied-cluster-airgap-deb.yml
ansible/airgap/provision-private-proxied-cluster-airgap-rpm.yml
ansible/deploy-connect-tls.yml
ansible/deploy-connect.yml
ansible/deploy-console-tls.yml
ansible/deploy-console.yml
ansible/deploy-monitor-tls.yml
ansible/deploy-monitor.yml
ansible/provision-cluster-tiered-storage.yml
ansible/provision-cluster-tls.yml
ansible/provision-cluster.yml
ansible/proxy/provision-private-proxied-cluster.yml
```

Redpanda
===============

> Note: This environment was deployed and configured by running a set of scripts, which can be found in [this repo](https://github.com/vuldin/redpanda-instruqt-day2-ansible).

The Redpanda cluster in this environment has three brokers. You can verify the broker count, connectivity, as well as view some other basic information related to the cluster with the following command:

```bash,run
rpk cluster info
```

Output:

```bash,nocopy
CLUSTER
=======
redpanda.e67b0094-f715-4ed9-853e-1cb4a6ad3247

BROKERS
=======
ID    HOST    PORT
0*    node-a  9092
1     node-b  9092
2     node-c  9092

TOPICS
======
NAME  PARTITIONS  REPLICAS
log1  3           3
log2  3           3
log3  3           3
log4  3           3
log5  3           3
```

This Redpanda cluster is deployed via ansible and configured out-of-the box in a number of ways that make it possible to run the above command successfully, which is basically a Kafka client making an external connection to Redpanda. Redpanda is also [pinned to a specific version](https://github.com/vuldin/redpanda-instruqt-day2-ansible/blob/june20-presentation-updates/01-deploying-a-cluster-with-ansible/setup-server#L23) to ensure any upgrades are a deliberate (rather than accidental) process.

## rpk

rpk is the CLI for Redpanda that lets you configure, manage, and tune Redpanda clusters. It also let you manage topics, groups, and access control lists (ACLs). More details on rpk and its capabilities are in [our docs](https://docs.redpanda.com/current/reference/rpk/).

rpk is installed by default wherever Redpanda is installed (ie. on each broker in the cluster). While you could connect to the brokers to use rpk, the approach taken in these instructions is to use a local install of rpk that connects into the remote cluster. You can verify this configuration by running the following command:

```bash,run
rpk profile print
```

Output:

```bash,nocopy
name: redpanda
description: ""
prompt: ""
from_cloud: false
kafka_api:
    brokers:
        - node-a:9092
        - node-b:9092
        - node-c:9092
admin_api:
    addresses:
        - node-a:9644
        - node-b:9644
        - node-c:9644
schema_registry: {}
```

The configuration for connecting to this cluster is stored in the "redpanda" profile shown above. You can create multiple profiles within rpk, and switch between them to connect to various clusters. More details on rpk profiles [here](https://docs.redpanda.com/current/reference/rpk/rpk-profile/rpk-profile/).

## Monitoring

Redpanda provides prometheus metrics through endpoints on the admin API. These instructions focus on the recommended `/public_metrics` endpoint. More details on how to access this metric and definitions for each metric available are [here](https://docs.redpanda.com/current/reference/public-metrics-reference/). You can see the output from this endpoint with curl:

```bash,run
curl node-a:9644/public_metrics
```

Prometheus (or some other metrics tool) must be configured to scrape this endpoint. An example `prometheus.yaml` is below:

```bash,nocopy
global:
  scrape_interval: 10s
  evaluation_interval: 10s
scrape_configs:
- job_name: redpanda
  static_configs:
  - targets:
    - node-a:9644
    - node-b:9644
    - node-c:9644
  metrics_path: /public_metrics
```

The above section configures Prometheus to scrape from the admin port on each of the Redpanda brokers. More details on configuring Prometheus and Grafana will be covered in the 4th track.

You have reached the end of the cluster overview assignment. Please click the 'Next' button below to continue.
