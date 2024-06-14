echo "\nINFO: Generate SSH Keys for ansible password less SSH"
rm -f ansible.pem ansible.pem.pub
ssh-keygen -b 2048 -t rsa -f ansible.pem -q -C ansible -N ""

echo "\nINFO: Copy SSH Keys to ~/.ssh/ - To Allow SSH to EC2 from local"
cat ansible.pem > ~/.ssh/id_rsa
cat ansible.pem.pub > ~/.ssh/id_rsa.pub

echo "\nINFO: Copy SSH Keys to /root/.ssh - To Allow SSH to EC2 from Bastion"

echo "\nINFO: Update teraform.auto.tfvars with ansible user Public Key"
echo "keypair_public_key = <<-EOF" > tmp.txt
cat ansible.pem.pub >> tmp.txt
echo EOF >> tmp.txt
sed -i '/keypair_public_key/d' ../infra/terraform/terraform.auto.tfvars
sed -i '/ssh-rsa/d' ../infra/terraform/terraform.auto.tfvars
sed -i '/EOF/d' ../infra/terraform/terraform.auto.tfvars

cat tmp.txt >> ../infra/terraform/terraform.auto.tfvars
rm -f tmp.txt

echo "\nINFO: Ansible user SSH Keys are ansible.pem and ansible.pem.pub. Will be used for SSH like below"

echo "\nINFO: ssh ansible@PUBLIC_IP_OF_EC2_INSTANCE\n"
