# Description

This project Deploys a Secure Confluent Kafka Cluster on N number of EC2s. NOTE: Code will work fine for 3 Nodes cluster. For Single node, there are TOPICs Replication releated chagnes which should be done.

## Pre-requisites

- Make sure you have the right ansible and python version - https://docs.confluent.io/ansible/current/ansible-requirements.html#general-requirements
- Have your AD/LDAP details ready.
- Build required number of EC2 instances following confluent_kafka_infra_setup/README.md
- Validate password less ssh to all EC2s from Ansible Controller host (where you will run the ansible-playbook from)
- Have your response.crt and private.key ready. Make sure your certificate has your kafka servers entries as SAN. Will put these cert and key in roles/secrets/defaults/secret.yml
```
For Eq. I got - CN=kafka-connect-lab01.nrsh13-hadoop.com and the SANs has hostname entries 
dns: ansi-lab01-01.nrsh13-hadoop.com
dns: ansi-lab01-02.nrsh13-hadoop.com
dns: ansi-lab01-03.nrsh13-hadoop.com
dns: ansi-lab01-04.nrsh13-hadoop.com
dns: ansi-lab01-05.nrsh13-hadoop.com
dns: ansi-lab01-06.nrsh13-hadoop.com
```
- Execute scripts_and_others/setup-cp-ansible.sh which clones and setup cp-ansible code.
```
cd confluent_kafka_setup_secure/
sh scripts_and_others/setup-cp-ansible.sh
```
- Read console output of above script execution (mainly the bottom ones).

- Copy confluent_kafka_setup_secure/roles/secrets/default/dummySecret.yml to confluent_kafka_setup_secure/roles/secrets/default/secret.yml and update all required details. This will include all your credentials and certificates.

- Once the MDS keypair, along with Host/Root certs and required credentials are updated/created in roles/secrets/defaults/secret.yml file, Encrypt the secret.yml file. Note - I used same cert for all machine as the SNS has each EC2 hostname in it which is required for secure confluent cluster.
```
[root@ansible ~/aws_confluent_kafka_setup/confluent_kafka_setup_secure]# ansible-vault encrypt roles/secrets/defaults/secret.yml
New Vault password:
Confirm New Vault password:
Encryption successful
```

## How to Run 

- Copy inventory/dummyhostsInventory.yml to inventory/hostsInventory.yml and update as per your details.Once ready Test connectivity using ping module.

```
[root@ansible ~]# ansible -i inventory/hostsInventory.yml -m ping all
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

- Run ansible playbook - Either Pass Vault password from command line using --ask-vault-password or define the vault creds file location in ansible.cfg
```
ansible-playbook all.yml --ask-vault-pass
or to run a specific component
ansible-playbook all.yml --tags kafka_brokers --ask-vault-pass
```


## Cleanup
```
ansible-playbook scripts_and_others/cleanup.yml
```


## Other Info
- The last part in all.yml will set up required permissions. Refer scripts_and_others/setup-initial-permissions.sh
    - To all your MDS Super User to see all details(like Connect Cluster, Ksql DB, Roles Management etc) in Control Center.
    - Read access to ALL on Schema Registry
    - Required Permissions to your Cert CN (kafka-connect-lab01.nrsh13-hadoop.com) so that it can producer/consume messages to/from mytopic Topic.
```
- name: Post setup Permissions
  hosts: set_permissions
  become: true
  tags: set_permissions
```
- It will take upto 20 mins in the setup.
- Login to the ansi-lab01-01 host and keep checking the packages installed.
- Open the User interfaces at (Loading might be slow in the beginning - check IPTables if UI does not open):
```
Control Center:		https://ansi-lab01-01.nrsh13-hadoop.com:9021
Connect Cluster: 	https://ansi-lab01-01.nrsh13-hadoop.com:18083
Schema Registry: 	https://ansi-lab01-01.nrsh13-hadoop.com:18081
KSql:               https://ansi-lab01-01.nrsh13-hadoop.com:18088/info
```


## Contact
nrsh13@gmail.com