#!/bin/bash

component=$1
environment=$2
numhosts=$3
hostDomain=$4
sshUser=$5

## here we will prepare /etc/hosts files which will include all 3 kafka ec2s + active directory ec2. Then we will copy this to each host so that all are reachable to each other.

echo "\n --- ALERT: Public IP of the Machines will KEEP on changing after reboot. DONT Forget to update it wherever required ----"
echo "\ninfo: Prepare /etc/hosts for Corporate (Ec2s in Private Subnet) - Uses EC2s Private IP\n"
rm -f ../../scripts/etchosts*	  

echo "$(aws ec2 describe-instances --region ap-southeast-2 --filters "Name=tag-value,Values=active-directory" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text)\tactive-directory${4}\tactive-directory" > ../../scripts/etchostsPrivateIP

for i in $(seq 1 $3); do
    hostName=${1}-${2}-0${i}
    echo Checking ${hostName}${4}
    echo "$(aws ec2 describe-instances --region ap-southeast-2 --filters "Name=instance-state-name,Values=running" "Name=tag-value,Values=${hostName}" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text)\t${hostName}${4}\t\t${hostName}" >> ../../scripts/etchostsPrivateIP	  
done

## output - ../../scripts/etchostsPrivateIP 
# 172.31.9.32	active-directory.nrsh13-hadoop.com	active-directory
# 172.31.24.35	ansi-lab01-01.nrsh13-hadoop.com	ansi-lab01-01
# 172.31.37.81	ansi-lab01-02.nrsh13-hadoop.com	ansi-lab01-02
# 172.31.3.195	ansi-lab01-03.nrsh13-hadoop.com	ansi-lab01-03

echo "\ninfo: Prepare /etc/hosts for non Corporate (Ec2s in Public Subnet) - Uses EC2s Public IP\n"
# echo "\ninfo: Prepare C:\Windows\System32\drivers\etc\hosts for Windows - Uses EC2s Public IP (Corporate)"

echo "$(aws ec2 describe-instances --region ap-southeast-2 --filters "Name=tag-value,Values=active-directory" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text)\tactive-directory${4}\tactive-directory" > ../../scripts/etchostsPublicIP

for i in $(seq 1 $3); do
    hostName=${1}-${2}-0${i}
    echo Checking ${hostName}${4}
    echo "$(aws ec2 describe-instances --region ap-southeast-2 --filters "Name=instance-state-name,Values=running" "Name=tag-value,Values=${hostName}" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text)\t${hostName}${4}\t\t${hostName}" >> ../../scripts/etchostsPublicIP	  
done

## output - ../../scripts/etchostsPublicIP 
# 3.24.139.80	active-directory.nrsh13-hadoop.com	active-directory
# 3.26.181.154	ansi-lab01-01.nrsh13-hadoop.com	ansi-lab01-01
# 3.25.118.19	ansi-lab01-02.nrsh13-hadoop.com	ansi-lab01-02
# 3.27.162.43	ansi-lab01-03.nrsh13-hadoop.com	ansi-lab01-03

echo "\ninfo: Prepare /etc/hosts on macOS - assuming passwordless sudo for `whoami` - ONLY PUBLIC IP CAN BE USED FOR SSH"
cp /etc/hosts ../../scripts/
sed -i '' -e '/ansi/d' -e '/active-directory/d' -e '/^$/d' ../../scripts/hosts
echo "" >> ../../scripts/hosts
cat ../../scripts/etchostsPublicIP >> ../../scripts/hosts
sudo cp ../../scripts/hosts /etc/hosts
rm -f ../../scripts/hosts

echo "\ninfo: SCP the etchostsPrivateIP to all EC2s - ONLY USE PRIVATE IP FOR NODES INTERNAL COMMUNICATION"
# https://stackoverflow.com/questions/30940981/zookeeper-error-cannot-open-channel-to-x-at-election-address/30993130#30993130?newreg=08fbe3fd0a464f8ebaf41b598b19f2dc
for i in $(seq 1 $3); do
    hostName=${1}-${2}-0${i}
    echo "\ninfo: Checking ${hostName}${4}\n"
    scp -q -o "StrictHostKeyChecking=no" ../../scripts/etchostsPrivateIP ${sshUser}@${hostName}${4}:/tmp/
    ssh -q -o "StrictHostKeyChecking=no" ${sshUser}@${hostName}${4} "sudo hostnamectl set-hostname ${hostName}${4}; sudo cp /etc/hosts /tmp/hosts; sudo chmod 777 /tmp/hosts; sudo sed -i -e '/ansi/d' -e '/active-directory/d' -e '/^$/d' /tmp/hosts; sudo echo \"\" >> /tmp/hosts; sudo cat /tmp/etchostsPrivateIP >> /tmp/hosts; sudo cp /tmp/hosts /etc/hosts; cat /etc/hosts"
done

rm -f ../../scripts/etchosts*