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

pushd $scripts_dir/../infra/terraform > /dev/null

cp main.tf.remote main.tf

export TF_IN_AUTOMATION=true # To Remove init output last parahgraph
echo -e "\n\$------ Running Terraform init ------\$"
#terraform init -input=true | egrep -v '^- module|^- Reusing|^- Using|^- Finding|^- Install|^Terraform'
terraform init -input=true

echo -e "\n\$------ Running Terraform ${ACTION} ------\$\n"
# Terraforn ACTION
if [[ $ACTION = "plan" ]]; then 
    #terraform $ACTION -input=false | GREP_COLOR='1;32' egrep '#|Plan:|Terraform v|Terraform will' --color=always
    terraform $ACTION -input=false
else
    #terraform $ACTION --auto-approve | GREP_COLOR='1;32' egrep '#|Plan:|Terraform v|Terraform will|^aws|complete!|No changes' --color=always
    terraform $ACTION --auto-approve
fi
