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

The git repo backing this track is available here: https://github.com/vuldin/redpanda-ansible-tls-sasl-instruqt

All startup commands can be found in the following two scripts (which have been ran one after the other automatically in this environment):
1. https://github.com/vuldin/redpanda-ansible-tls-sasl-instruqt/blob/main/track_scripts/setup-server
2. https://github.com/vuldin/redpanda-ansible-tls-sasl-instruqt/blob/main/01-day2-ansible-overview/setup-server

Redpanda
===============

Identical rpk profile are created on the ansible server (first tab), as well as each of the Redpanda brokers (other tabs). You can run rpk commands in any terminal without requiring any additional requirements. For example, you can run the following commands in any terminal:

```bash,run
rpk cluster info
rpk cluster health
```

You have reached the end of the cluster overview assignment. Please click the 'Next' button below to continue.
