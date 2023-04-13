# Description

This project Deploys a Confluent Kafka Cluster on N number of EC2s.

## Pre-requisites

- Build required number of EC2 instances following aws_kafka_infra_setup/README.md
- Validate password less ssh to all EC2s from Ansible Controller host (where you will run the ansible-playbook from)
- Udpate hostsInventory.yml with your hostnames and test connectivity using ping module.

```
[root@ansible ~]# ansible -i hostsInventory.yml -m ping all
ansi-lab01-01.nrsh13-hadoop.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
ansi-lab01-02.nrsh13-hadoop.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
ansi-lab01-03.nrsh13-hadoop.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/libexec/platform-python"
    },
    "changed": false,
    "ping": "pong"
}
```

## How to Run 
- Run ansible playbook

```
ansible-playbook -i hostsInventory.yml all.yml
```

## Cleanup
```
ansible-playbook -i hostsInventory.yml cleanup.yml
```

## Other Info
- It will take upto 15 mins in the setup.
- Open the Control center UI at http://`hostname -i`:9021 (Loading might be slow in the beginning - check IPTables/firewalld if UI does not open)

## Contact
nrsh13@gmail.com
