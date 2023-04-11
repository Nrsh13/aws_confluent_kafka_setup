#!/bin/bash
# yum update -y
yum install -y python39 dos2unix ansible conntrack socat postgresql mariadb wget curl git jq unzip java-1.8.0-openjdk openldap* vim nc bind-utils net-tools

########### Passing Less SSH Access #########
useradd ${passwordless_ssh_user}
mkdir /home/${passwordless_ssh_user}
chown -R ${passwordless_ssh_user}:${passwordless_ssh_user} /home/${passwordless_ssh_user}

groupadd docker
usermod -aG docker ${passwordless_ssh_user}
systemctl daemon-reload

echo "${public_key}" > /tmp/authorized_keys
su - ${passwordless_ssh_user} -c "mkdir -p ~/.ssh;touch ~/.ssh/authorized_keys;chmod 700 ~/.ssh;chmod 600 ~/.ssh/authorized_keys"
su - ${passwordless_ssh_user} -c "cat /tmp/authorized_keys >> /home/${passwordless_ssh_user}/.ssh/authorized_keys"
sed -i -e '3 i +:${passwordless_ssh_user}:ALL' /etc/security/access.conf
chmod 755 /etc/sudoers
echo -e "\n${passwordless_ssh_user} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
chmod 440 /etc/sudoers

########## aws, kubectl CLI installation 
# AWS CLI 2
python3.9 -m pip uninstall -y awscli
rm -rf /opt/anaconda/bin/aws

curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install   # will install at /usr/local/bin/aws (soft link)
# Change permissions to main folder to allow non-root users to access awscli.
chmod 755 -R /usr/local/aws-cli
rm -rf ./aws
aws --version

# Kubectl 
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
mv ./kubectl /usr/local/bin/kubectl
kubectl version

# Confluent CLI -
wget -q https://packages.confluent.io/rpm/6.2/confluent-cli-6.2.2-1.x86_64.rpm
yum localinstall -y confluent-cli-6.2.2-1.x86_64.rpm
chmod +x /usr/bin/confluent

########### Packages Install ############
# For UI and Kafka setup
service iptables stop
chmod 777 /var/lib
python3.9 -m pip install confluent-kafka confluent-kafka[avro] requests dateutils fastavro jsonschema