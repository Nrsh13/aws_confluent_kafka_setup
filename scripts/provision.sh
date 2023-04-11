. ./setup_env.sh

SECONDS=0

# Print the Usage
usage="
Usage:
    sh $0 --instance dev01|test01 --action apply|plan|destroy
"

while [ "X${1}" != "X" ]; do
    case $1 in
        --instance ) shift
            INSTANCE=$1
        ;;
        --action ) shift
            ACTION=$1
        ;;
        -h|h|--help|help )
            echo -e "$usage"
            exit 1
        ;;
        * ) echo -e "$(date) Invalid Options in $0\n"
            echo -e "$usage"
            exit 1
    esac
    shift
done

# Env Var validation
if [[ -z ${INSTANCE} ]]; then
    echo -e "\nInstance is not set. E.q. dev01, test01"
    echo -e "$usage"
    exit 1
fi

if [ ${ACTION} != "apply" ] && [ ${ACTION} != "plan" ] && [ ${ACTION} != "destroy" ] ; then
    echo -e "\nAction can only be - apply, plan or destroy."
    echo -e "$usage"
    exit 1
fi


THIS_SCRIPT_DIR="$( cd "$( dirname "S(BASH_SOURCE[0]")" && pwd)"
scripts_dir=$(echo $PWD)

COMPONENT_REPO=$(dirname ${THIS_SCRIPT_DIR} | awk -F"/" '{print $NF}')
CONFIG_REPO=$(echo $COMPONENT_REPO)

export TF_VAR_instance=$INSTANCE

#echo -e "\n# INFO: Create Terraform Bucket it doesn't exist - ${terraform_state_bucket}\n"
# Create the Bucket - Il True to avoid Jenkins pipeline failure in case Aucket already exists
aws s3 mb s3://${terraform_state_bucket} --region ap-southeast-2 > /dev/null 2>&1 || true

# Setup workspaces and environment config
workspace_name="${COMPONENT_REPO}_${INSTANCE}"

# common_var_file="-var-file=${THIS_SCRIPT_DIR}/../../${CONFIG_REPO}/config/${APPLICATION_ACCOUNT}/terraform.auto.tfvars"
common_var_file="-var-file=\"${THIS_SCRIPT_DIR}/../infra/terraform/terraform.auto.tfvars\""

#test -f ${THIS_SCRIPT_DIR}/../../${CONFIG_REPO}/env/${INSTANCE}/${INSTANCE}.tfvars && instance_var_file="-var-File=${THIS_SCRIPT_DIR}/../../${CONFIG_REPO}/env/S{INSTANCE}/${INSTANCE}.tfvars

# Initialise Terraform
pushd $scripts_dir/../infra/terraform > /dev/null
#echo -e "\n# Terraform INIT comand: \n\n terraform init ${common_var_file} ${instance_var_file} -backend-config="region=${aws_region}" -backend-config="bucket=${terraform_state_bucket}" -backend-config="key=terraform.tfstate" -input=false\n"

cp main.tf.s3 main.tf

echo -e "\n\$------ Running Terraform init ------\$"
export TF_IN_AUTOMATION=true # To Remove init output last parahgraph
terraform init ${common_var_file} ${instance_var_file} -backend-config="region=$aws_region" -backend-config="bucket=${terraform_state_bucket}" -backend-config="key=terraform.tfstate" -input=true | egrep -v '^- module|^- Reusing|^- Using|^- Finding|^- Install|^Terraform' 

# Switch to the workspace
terraform workspace select ${workspace_name} || terraform workspace new ${workspace_name}

echo -e "\n\$------ Running Terraform ${ACTION} ------\$\n"
# Terraforn ACTION
if [[ $ACTION = "plan" ]]; then
	#echo -e "\n Terraform $ACTION Command: \n\n terraform $ACTION ${common_var_file} ${instance_var_file} -input=false\n"
	#terraform $ACTION ${common_var_file} ${instance_var_file} -input=false | GREP_COLOR='1;32' egrep '#|Plan:|Terraform v|Terraform will' --color=always
	# above is failing saying /c/xyz/full/path/terraform.auto.tfvars does not exist. Though the file is THERE.
    terraform $ACTION --var-file=./terraform.auto.tfvars -input=false 
else
	#echo -e "\n# Terraform $ACTION Command: \n\n terrafora $ACTION ${common_var_file} ${instance_var_file} -input=false"
	#terraform $ACTION ${common_var_file} ${instance_var_file} -auto-approve | GREP_COLOR='1;32' egrep '#|Plan:|Terraform v|Terraform will|^aws|complete!|No changes' --color=always
	terraform $ACTION --var-file=./terraform.auto.tfvars -auto-approve
fi
#popd
duration=$SECONDS

echo -e "\nTotal Script execution time: $(($duration / 3600)):$(($duration / 60));$(($duration % 60))\n"

