
## Print the Usage

scripts_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#THIS_DIR=$(echo $PWD)

#echo $THIS_SCRIPT_DIR $scripts_dir

usage="
Usage: sh $0 --set-controller yes|no|default-no --cp-versino 7.x.x-post|default-7.2.5-post"

playbook_usage="

    - Refer inventory/DummyInventory.yml and Create|Update inventory/hostsInventory.yml

    - With $scripts_dir/../roles/secrets: All certs/creds/passwords coming from $scripts_dir/../roles/secrets

	Refer roles/secrets/defaults/DummySecret.yml and Create|Update roles/secrets/defaults/secret.yml
	Update Passwords, Host Cert, Private Key, Root CA, tokenKeypairDir/TokenKeyPair.pem and tokenKeypairDir/public.pem in roles/secrets/default/secret.yml

    - Without $scripts_dir/../roles/secrets: All certs/creds/passwords coming from inventory/hostsInventory.yml - Refer scripts_and_others/without_roles_secrets_settings.sh

    - Encrypt roles/secrets/defaults/secret.yml using below. Ignore when proceeding without $scripts_dir/../roles/secrets-

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
            echo -e "$usage"
            exit 1
        ;;
        * ) echo  "$(date) Invalid options in $0\n"
            echo -e "$usage"
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
}

if [[ -z ${CONTROLLER} ]] ; then
    echo -e "\nINFO: Set Controller (installing ansible) is NO."
    echo -e "$usage"
    CONTROLLER=no
else
    echo -e "\nINFO: Set Controller (installing ansible) is ${CONTROLLER}."
    #echo -e "$usage"
fi

if [[ ${CONTROLLER} == "yes" ]]; then
    echo -e "\nINFO: Installing Ansible and Python"
    ansible_installation
fi   


if [[ -z ${CPVERSION} ]] ; then
    echo -e "\nINFO: Choosing Default CP Version - 7.2.5-post"
    echo -e "$usage"
    CPVERSION="7.2.5-post"
fi

echo -e "\nINFO: Check if ${CPVERSION} CP Version Exists"
if [ $(git ls-remote https://github.com/confluentinc/cp-ansible.git ${CPVERSION} | wc -l) == 0 ]; then
  echo -e "\nERROR: CP Version $CPVERSION does not Exists!!"
  echo -e "\nERROR: Existing Now. Pass a Valid CP Version from below - \n"
  git ls-remote https://github.com/confluentinc/cp-ansible.git | grep post | tail -20 | awk -F'/' '{print $3}'
  echo -e "\n\n"
else
  echo -e "\nINFO: CP Version $CPVERSION Exists"
fi

echo -e "\nINFO: Clone cp-ansible"
rm -rf $scripts_dir/cp-ansible && mkdir $scripts_dir/cp-ansible
git clone https://github.com/confluentinc/cp-ansible.git $scripts_dir/cp-ansible --quiet
cd $scripts_dir/cp-ansible
git checkout ${CPVERSION}

echo -e "\nINFO: Remove confluent.platform from roles/* - To Avoid collections installation"
sed -i -e "s/confluent.platform.//g" roles/**/*/*.yml
sed -i -e "s/confluent.platform.//g" roles/**/*/*.j2

echo -e "\nINFO: Comment deploy_connectors.yml in roles/kafka_connect/tasks/main.yml - Causes Syntax Error "
sed -e '/deploy_connectors.yml/ s/^#*/#/' -i roles/kafka_connect/tasks/main.yml
sed -e '/Deploy Connectors/ s/^#*/#/' -i roles/kafka_connect/tasks/main.yml

echo -e "\nINFO: Change MDS Keys Source from src to content in roles/kafka_broker/tasks/rbac.yml - will be reading from roles/secrets/default/secret.yml"
sed -i -e 's/src: "{{token_services_public_pem_file}}"/content: "{{token_services_public_pem_filecontent}}"/' roles/kafka_broker/tasks/rbac.yml
sed -i -e 's/src: "{{token_services_private_pem_file}}"/content: "{{token_services_private_pem_filecontent}}"/' roles/kafka_broker/tasks/rbac.yml

echo -e "\nINFO: Change Certs Source from src to content in roles/ssl/tasks/custom_certs.yml - will be reading from roles/secrets/default/secret.yml"
sed -i -e 's/src: "{{ssl_ca_cert_filepath}}"/content: "{{ssl_ca_cert_filecontent}}"/' roles/ssl/tasks/custom_certs.yml
sed -i -e 's/src: "{{ssl_signed_cert_filepath}}"/content: "{{ssl_signed_cert_filecontent}}"/' roles/ssl/tasks/custom_certs.yml
sed -i -e 's/src: "{{ssl_key_filepath}}"/content: "{{ssl_key_filecontent}}"/' roles/ssl/tasks/custom_certs.yml
sed -e '/remote_src: "{{ssl_custom_certs_remote_src}}"/ s/^#*/#/' -i roles/ssl/tasks/custom_certs.yml

echo -e "\nINFO: Copy roles and Filter Plugins to root folder and remove cp-ansible "
cp $scripts_dir/cp-ansible/plugins/filter/filters.py $scripts_dir/../filter_plugins/
rm -rf $scripts_dir/../roles
cp -pr $scripts_dir/cp-ansible/roles $scripts_dir/../
rm -rf $scripts_dir/cp-ansible


echo -e "\nINFO: Generate MDS Token KeyPair in scripts_and_others/tokenKeypairDir"
rm -rf $scripts_dir/tokenKeypairDir && mkdir $scripts_dir/tokenKeypairDir && cd $scripts_dir/tokenKeypairDir && openssl genrsa -out tokenKeypair.pem 2048 &>/dev/null
openssl rsa -in tokenKeypair.pem -outform PEM -pubout -out public.pem &>/dev/null
#ls -lthr $scripts_dir/tokenKeypairDir

#echo -e "\nINFO: Update Host Cert, Private Key, Root CA, MDS TokenKeyPair.pem and public.pem in $scripts_dir/../roles/secrets/default/secret.yml"
echo -e "\n\n\nIMPORTANT: Copying secrets_role/secrets to roles/secrets - Here we are storing all variables/secrets/keys/passwords"
cp -pr $scripts_dir/secrets_role/secrets $scripts_dir/../roles/

echo -e "\nINFO: Ready for Deployment $playbook_usage\n"
