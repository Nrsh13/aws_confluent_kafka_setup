export CONFLUENT_PLATFORM_USERNAME=$1
export CONFLUENT_PLATFORM_PASSWORD=$2
export INVENTORY_HOSTNAME=$3
export USER_NEED_ACCESS_TO_MYTOPIC=$4
export CONNECT_CLUSTER_NAME=$5

mkdir ~/.confluent
cat > ~/.confluent/config.json << EOF
{
  "disable_update_check": false,
  "disable_updates": true,
  "disable_plugins": true,
  "disable_feature_flags": true
}
EOF

/usr/local/bin/confluent --version

#echo "hello ${user} ${pass}" >> /tmp/testing.txt

/usr/local/bin/confluent login --url https://${INVENTORY_HOSTNAME}:8090 --ca-cert-path /var/ssl/private/ca.crt 


## Using -k below as we have self signed certs
cid=$(curl -s -L  https://${INVENTORY_HOSTNAME}:8090/kafka/v3/clusters -u ${CONFLUENT_PLATFORM_USERNAME}:${CONFLUENT_PLATFORM_PASSWORD} -k | jq .data[0].cluster_id)

echo "/usr/local/bin/confluent iam rbac role-binding create --role SystemAdmin --principal User:${CONFLUENT_PLATFORM_USERNAME} --kafka-cluster $cid --schema-registry-cluster schema-registry" > /tmp/finalscript.sh
echo "/usr/local/bin/confluent iam rbac role-binding create --role SystemAdmin --principal User:ansible --kafka-cluster $cid --schema-registry-cluster schema-registry" >> /tmp/finalscript.sh

# Important: Allow anyone to READ the Schema. Schema Registry only works with AD users not with CNs. So if we dont pass any user, it will complain User is denied operation Read on Subject: mytopic-value; error code so we use ANONYMOUS user and allo it read access.

echo "/usr/local/bin/confluent iam rbac role-binding create --principal User:ANONYMOUS --role DeveloperRead --resource Subject:* --kafka-cluster $cid --schema-registry-cluster schema-registry" >> /tmp/finalscript.sh
echo "/usr/local/bin/confluent iam rbac role-binding create --principal User:ANONYMOUS --role DeveloperWrite --resource Subject:* --kafka-cluster $cid --schema-registry-cluster schema-registry" >> /tmp/finalscript.sh

# All Topic mytopic* -
echo "/usr/local/bin/confluent iam rbac role-binding create --principal User:${USER_NEED_ACCESS_TO_MYTOPIC} --role ResourceOwner --resource Topic:mytopic --kafka-cluster $cid --prefix" >> /tmp/finalscript.sh
# All Consumer Group starting with mytopic
echo "/usr/local/bin/confluent iam rbac role-binding create --principal User:${USER_NEED_ACCESS_TO_MYTOPIC} --role ResourceOwner --resource Group:mytopic --kafka-cluster $cid --prefix" >> /tmp/finalscript.sh

# To allow Connector submission by using user MDS Super User
echo "/usr/local/bin/confluent iam rbac role-binding create --principal User:${CONFLUENT_PLATFORM_USERNAME} --role SystemAdmin --kafka-cluster $cid --connect-cluster ${CONNECT_CLUSTER_NAME}" >> /tmp/finalscript.sh
echo "/usr/local/bin/confluent iam rbac role-binding create --principal User:ansible --role SystemAdmin --kafka-cluster $cid --connect-cluster ${CONNECT_CLUSTER_NAME}" >> /tmp/finalscript.sh

sh /tmp/finalscript.sh > /tmp/finalscript.out


# # Some Other Configurations. Use if needed.
# :'
# => Set FULL Access ON KSQL DB for any User -

# 	https://docs.confluent.io/platform/current/security/rbac/ksql-rbac.html#ksqldb-role-mappings

# ksql-cluster-id => Got from /etc/ksqldb/ksql-server.properties
	
# 	ksql.service.id=default_

# or in Chrome browser -

# 	https://ansi-lab01-01.nrsh13-hadoop.com:18088/info

# 	{"KsqlServerInfo":{"version":"6.0.6","kafkaClusterId":"NNF36VtuQYGyvBSF_iMrIA","ksqlServiceId":"default_"}}

# ```
# [root@ansi-lab01-01 ~]# /usr/local/bin/confluent iam rbac role-binding create --principal User:anyUser --role SystemAdmin --kafka-cluster-id NNF36VtuQYGyvBSF_iMrIA --ksql-cluster-id default_
# +--------------+-------------+
# | Principal    | User:anyUser |
# | Role         | SystemAdmin |
# | ResourceType | Cluster     |
# +--------------+-------------+
# ```
# '