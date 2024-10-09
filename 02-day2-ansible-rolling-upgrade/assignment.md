---
slug: day2-ansible-rolling-upgrade
id: u8g6guqqdhfm
type: challenge
title: Rolling upgrade with Ansible
teaser: This section shows how to perform a rolling upgrade, and lists a few things
  to consider before kicking off this upgrade process.
notes:
- type: text
  contents: |-
    The next challenge shows how to quickly upgrade Redpanda with Ansible.

    ![skate.png](../assets/skate.png)
tabs:
- id: x7xzzkwbfywc
  title: Shell
  type: terminal
  hostname: server
difficulty: ""
timelimit: 600
---
Upgrading Redpanda with Ansible is a simple process. We will update the `redpanda_version` flag sent to the ansible playbook, and then Ansible handles the rest.

## Upgrade via the Ansible playbook

Make sure we are in the correct directory and have our environment variables properly set:

```bash,run
cd deployment-automation
export DEPLOYMENT_PREFIX=instruqt
export ANSIBLE_COLLECTIONS_PATH=$(realpath .)/artifacts/collections
export ANSIBLE_ROLES_PATH=$(realpath .)/artifacts/roles
export ANSIBLE_INVENTORY=$(realpath .)/artifacts/hosts_gcp_$DEPLOYMENT_PREFIX.ini
```

Then re-run the Ansible playbook, passing in the desired Redpanda version:

```bash,run
ansible-playbook --private-key ~/.ssh/id_rsa -v ansible/provision-cluster.yml -i hosts.ini -e redpanda_version=24.1.8-1
```

> Note: The above command is idempotent and can be ran any number of times. Also, occasionally the above command will need to be ran again in order to perform the rolling restart.

More details on upgrading a cluster with Ansible are found [in our docs](https://docs.redpanda.com/current/deploy/deployment-option/self-hosted/manual/production/production-deployment-automation/#upgrade-a-cluster.)

A rolling restart has begun. Each broker is put into maintenance mode, moving any partition leadership to other brokers. Then Redpanda is upgraded to the chosen version and the process is restarted. Then the broker is taken out of maintenance mode and the process continues to the next broker until all brokers have been upgraded. Verify the new version has eventually been applied to each broker:

```bash,run
rpk redpanda admin brokers list
```

Eventually the output will be similar to the following:

```bash,nocopy
NODE-ID  NUM-CORES  MEMBERSHIP-STATUS  IS-ALIVE  BROKER-VERSION
0        2          active             true      v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
1        2          active             true      v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
2        2          active             true      v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
```

You can also do a version check with the following command:

```bash,run
rpk version
```

Output:

```bash,nocopy
Version:     v24.1.8
Git ref:     f7ac182695
Build date:  2024-06-14T23:15:03Z
OS/Arch:     linux/amd64
Go version:  go1.22.2

Redpanda Cluster
  node-0  v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
  node-1  v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
  node-2  v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
  node-3  v24.1.8 - f7ac18269548c6711614cb19a1b00c09bd3994de
```

> Note: If the commands above show that your cluster is still on v24.1.7, then re-run the `ansible-playbook` command again.

This challenge is now complete. Click 'Next' in the bottom right to continue to the next assignment.
