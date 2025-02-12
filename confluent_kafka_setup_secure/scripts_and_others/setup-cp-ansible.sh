
## Print the Usage

scripts_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#THIS_DIR=$(echo $PWD)

#echo $THIS_SCRIPT_DIR $scripts_dir

usage="
Usage: sh $0 --set-controller yes|no|default-no --cp-versino 7.x.x-post|default-7.2.5-post"

playbook_usage="

    - Use content from selfSignedCertificates and tokenKeypairDir (generated as result of this script) and update in ../roles/secrets/defaults/secret.yml
    
    - Refer inventory/DummyInventory.yml and Create|Update inventory/hostsInventory.yml

    - Comment proxy settings for non corporate setup.

    - All certs/creds/passwords will be used from $scripts_dir/../roles/secrets

    - Without $scripts_dir/../roles/secrets: All certs/creds/passwords were coming from inventory/hostsInventory.yml - Refer scripts_and_others/without_roles_secrets_settings.sh

	Refer roles/secrets/defaults/DummySecret.yml and Create|Update roles/secrets/defaults/secret.yml
	Update Passwords, Host Cert, Private Key, Root CA, tokenKeypairDir/TokenKeyPair.pem and tokenKeypairDir/public.pem in roles/secrets/default/secret.yml

    - Install collections - takes 15 mins in installation - goes in ~/.ansible/ folder. Collection keywords are confluent.platform, alternatives - used in ansible code
    ansible-galaxy collection install ansible.posix community.general community.crypto

    - Encrypt roles/secrets/defaults/secret.yml using below.

	ansible-vault encrypt roles/secrets/defaults/secret.yml 

    - Run Playbook

	ansible-playbook all.yml --ask-vault-pass

"

while [ "X${1}" != "X" ]; do
    case $1 in
        --set-controller )  shift
            CONTROLLER=$1
        ;;
        --cp-version )  shift
            CPVERSION=$1
        ;;
        -h|h|--help|help )
            echo "$usage"
            exit 1
        ;;
        * ) echo  "$(date) Invalid options in $0\n"
            echo "$usage"
            exit 1
    esac
    shift
done

ansible_installation() {
  sudo yum erase -y ansible 
  sudo yum install -y python39 vim
  sudo rm -f /etc/alternatives/python3 /usr/bin/vi
  sudo ln -s /usr/bin/python3.9 /etc/alternatives/python3
  sudo ln -s /usr/bin/vim /usr/bin/vi
  sudo python -m pip install ansible

#   # on mac
#   brew uninstall python@3.10 python@3.12
#   brew install python@3.11
#   rm -f /usr/local/bin/python3 /usr/local/bin/python
#   sudo ln -s /usr/local/bin/python3.11 /usr/local/bin/python3
#   sudo ln -s /usr/local/bin/python3.11 /usr/local/bin/python

#   pip install --no-cache-dir ansible-core==2.15.0

}

if [[ -z ${CONTROLLER} ]] ; then
    echo "\nINFO: Set Controller (installing ansible) is NO."
    echo "$usage"
    CONTROLLER=no
else
    echo "\nINFO: Set Controller (installing ansible) is ${CONTROLLER}."
    #echo "$usage"
fi

if [[ ${CONTROLLER} == "yes" ]]; then
    echo "\nINFO: Installing Ansible and Python"
    ansible_installation
fi   


if [[ -z ${CPVERSION} ]] ; then
    echo "\nINFO: Choosing Default CP Version - 7.2.5-post"
    echo "$usage"
    CPVERSION="7.2.5-post"
fi

echo "\nINFO: Check if ${CPVERSION} CP Version Exists"
if [ $(git ls-remote https://github.com/confluentinc/cp-ansible.git ${CPVERSION} | wc -l) == 0 ]; then
  echo "\nERROR: CP Version $CPVERSION does not Exists!!"
  echo "\nERROR: Existing Now. Pass a Valid CP Version from below - \n"
  git ls-remote https://github.com/confluentinc/cp-ansible.git | grep post | tail -20 | awk -F'/' '{print $3}'
  echo "\n\n"
else
  echo "\nINFO: CP Version $CPVERSION Exists"
fi

echo "\nINFO: Clone cp-ansible"
rm -rf $scripts_dir/cp-ansible && mkdir $scripts_dir/cp-ansible
git clone https://github.com/confluentinc/cp-ansible.git $scripts_dir/cp-ansible --quiet
cd $scripts_dir/cp-ansible
git checkout ${CPVERSION}
cp playbooks/tasks/certificate_authority.yml $scripts_dir/../roles/common/tasks/ # all.yml refers to this file


echo "\nINFO: Remove confluent.platform from roles/* - To Avoid collections installation"
sed -i '' -e "s/confluent.platform.//g" roles/**/*/*.yml
sed -i '' -e "s/confluent.platform.//g" roles/**/*/*.j2

echo "\nINFO: Comment deploy_connectors.yml in roles/kafka_connect/tasks/main.yml - Causes Syntax Error "
sed -i '' -e '/deploy_connectors.yml/ s/^#*/#/' roles/kafka_connect/tasks/main.yml
sed -i '' -e '/Deploy Connectors/ s/^#*/#/' roles/kafka_connect/tasks/main.yml

echo "\nINFO: Change MDS Keys Source from src to content in roles/kafka_broker/tasks/rbac.yml - will be reading from roles/secrets/default/secret.yml"
sed -i '' -e 's/src: "{{token_services_public_pem_file}}"/content: "{{token_services_public_pem_filecontent}}"/' roles/kafka_broker/tasks/rbac.yml
sed -i '' -e 's/src: "{{token_services_private_pem_file}}"/content: "{{token_services_private_pem_filecontent}}"/' roles/kafka_broker/tasks/rbac.yml

echo "\nINFO: Change Certs Source from src to content in roles/ssl/tasks/custom_certs.yml - will be reading from roles/secrets/default/secret.yml"
sed -i '' -e 's/src: "{{ssl_ca_cert_filepath}}"/content: "{{ssl_ca_cert_filecontent}}"/' roles/ssl/tasks/custom_certs.yml
sed -i '' -e 's/src: "{{ssl_signed_cert_filepath}}"/content: "{{ssl_signed_cert_filecontent}}"/' roles/ssl/tasks/custom_certs.yml
sed -i '' -e 's/src: "{{ssl_key_filepath}}"/content: "{{ssl_key_filecontent}}"/' roles/ssl/tasks/custom_certs.yml
sed -i '' -e '/remote_src: "{{ssl_custom_certs_remote_src}}"/ s/^#*/#/' roles/ssl/tasks/custom_certs.yml

# remove config_validation as we are NOT using /var/ssl/private folder for Certs location.
# kafka broker null pointer error - MDS not starting.
echo "\nINFO: Remove MDS Public pem and Token Key location depedency on controller - roles/kafka_broker/tasks/rbac.yml"
sed -i '' -e '/- name: Config Validations/,+5d' roles/common/tasks/main.yml
sed -i '' -e  '/broker_public_pem_file/d' roles/kafka_broker/tasks/rbac.yml
sed -i '' -e  '/broker_private_pem_file/d' roles/kafka_broker/tasks/rbac.yml

echo "\nINFO: Copy roles and Filter Plugins to root folder and remove cp-ansible "
cp $scripts_dir/cp-ansible/plugins/filter/filters.py $scripts_dir/../filter_plugins/
rm -rf $scripts_dir/../roles
cp -pr $scripts_dir/cp-ansible/roles $scripts_dir/../
rm -rf $scripts_dir/cp-ansible


# Define the directory where the token key pair should be generated
token_keypair_dir="$scripts_dir/tokenKeypairDir"

# Check if the directory does not exist
if [ ! -d "$token_keypair_dir" ]; then
    echo "\nINFO: Generate MDS Token KeyPair in $token_keypair_dir"

    # Create the directory and generate the token key pair silently
    mkdir -p "$token_keypair_dir" && cd "$token_keypair_dir" \
        && openssl genrsa -out tokenKeypair.pem 2048 &>/dev/null \
        && openssl rsa -in tokenKeypair.pem -outform PEM -pubout -out public.pem &>/dev/null

    cd ../
    # Uncomment the following line to list the files in the directory (for debugging purposes)
    # ls -lthr "$token_keypair_dir"
else
    echo "\nINFO: MDS Token Keypair already exists in $token_keypair_dir. Skipping token key pair generation."
fi

# Define the directory where the certificates are stored
cert_dir="$scripts_dir/selfSignedCertificates"

# Check if the directory exists and contains .crt or .key files
if [ ! -d "$cert_dir" ] || [ ! "$(ls $cert_dir/*.crt 2>/dev/null)" ] || [ ! "$(ls $cert_dir/*.key 2>/dev/null)" ]; then
    echo "\nINFO: Generate Hosts Self Signed Certificates in $cert_dir"
    sh "$scripts_dir/generate_self_signed_cert.sh" > /dev/null 2>&1
else
    echo "\nINFO: Certificates already exist in $cert_dir. Skipping certificate generation."
fi

#echo "\nINFO: Update Host Cert, Private Key, Root CA, MDS TokenKeyPair.pem and public.pem in $scripts_dir/../roles/secrets/default/secret.yml"
echo "\n\n\n--------- IMPORTANT: Copying secrets_role/secrets to roles/secrets - Here we are storing all variables/secrets/keys/passwords ---------"
cp -pr $scripts_dir/secrets_role/secrets $scripts_dir/../roles/

echo "\nINFO: Ready for Deployment $playbook_usage\n"
