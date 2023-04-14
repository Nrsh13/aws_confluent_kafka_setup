component=$1
instance=$2
numhosts=$3
hostDomain=$4
sshUser=$5

echo -e "\nINFO: Prepare /etc/hosts for Bastion/EC2/Linux"

echo -e "`aws ec2 describe-instances --filters "Name=tag-value,Values=active-directory" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text`\tactive-directory${4}\tactive-directory" > ../../scripts/etchostsBastion

for i in $(eval echo "{1..$3}")
  do 
    hostName=${1}-${2}-0${i}
    echo Checking ${hostName}${4};
    echo -e "`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag-value,Values=${hostName}" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text`\t${hostName}${4}\t${hostName}" >> ../../scripts/etchostsBastion	  
  done

echo -e "\nINFO: Prepare C:\Windows\System32\drivers\etc\hosts for Windows"

echo -e "`aws ec2 describe-instances --filters "Name=tag-value,Values=active-directory" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`\tactive-directory${4}\tactive-directory" > ../../scripts/etchostsWindows

for i in $(eval echo "{1..$3}")
  do 
    hostName=${1}-${2}-0${i}
    echo Checking ${hostName}${4};
    echo -e "`aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=tag-value,Values=${hostName}" --query 'Reservations[*].Instances[*].[PublicIpAddress]' --output text`\t${hostName}${4}\t${hostName}" >> ../../scripts/etchostsWindows	  
  done

  echo -e "\nINFO: Prepare /c/Windows/System32/drivers/etc/hosts on Windows"
  cp  /c/Windows/System32/drivers/etc/hosts ../../scripts/
  sed -i -e '/ansi/d' -e '/active-directory/d' -e '/^$/d' ../../scripts/hosts
  echo -e "\n" >> ../../scripts/hosts
  cat ../../scripts/etchostsWindows >> ../../scripts/hosts
  cp ../../scripts/hosts /c/Windows/System32/drivers/etc/hosts
  rm -f ../../scripts/hosts

  echo -e "\nINFO: SCP the etchostsBastion to all EC2s"
  for i in $(eval echo "{1..$3}")
  do 
    hostName=${1}-${2}-0${i}
    echo -e "\nINFO: Checking ${hostName}${4}";
    scp -q -o "StrictHostKeyChecking=no" ../../scripts/etchostsBastion ${sshUser}@${hostName}${4}:/tmp/
    ssh -q -o "StrictHostKeyChecking=no" ${sshUser}@${hostName}${4} "sudo hostnamectl set-hostname ${hostName}${4}; sudo cp /etc/hosts /tmp/hosts; sudo chmod 777 /tmp/hosts; sudo sed -i -e '/ansi/d' -e '/active-directory/d' /tmp/hosts; sudo echo -e \"\n\" /tmp/hosts; sudo cat /tmp/etchostsBastion >> /tmp/hosts; sudo cp /tmp/hosts /etc/hosts; cat /etc/hosts"
  done