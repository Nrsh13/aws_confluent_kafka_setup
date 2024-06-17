# Secure Confluent Cluster Requirements for Producer & Consumer

- Just run below and it will display all required options:
```
python confluent-kafka-producer.py -h
``` 

- Required Permissions on Schema Registry Subject, Topic and Consumer Group is required. 
	- if you have used, confluent_kafka_setup_secure folder for the setup, these permissions are already setup.
	- Refer aws_confluent_kafka_setup/confluent_kafka_setup_secure/all.yml (last section - set_permissions) and aws_confluent_kafka_setup/confluent_kafka_setup_secure/scripts_and_others/setup-initial-permissions.sh

Below will Provide full permissions to SR, Group, Topic to kafka-connect-lab01.nrsh13-hadoop.com
```
#All Schema
/usr/local/bin/confluent iam rbac role-binding create --principal User:ANONYMOUS --role DeveloperRead --resource Subject:* --kafka-cluster-id NNF36VtuQYGyvBSF_iMrIA --schema-registry-cluster-id schema-registry
/usr/local/bin/confluent iam rbac role-binding create --principal User:ANONYMOUS --role DeveloperWrite --resource Subject:* --kafka-cluster-id NNF36VtuQYGyvBSF_iMrIA --schema-registry-cluster-id schema-registry
# All Topic mytopic* - 
/usr/local/bin/confluent iam rbac role-binding create --principal User:kafka-connect-lab01.nrsh13-hadoop.com --role ResourceOwner --resource Topic:mytopic --kafka-cluster-id NNF36VtuQYGyvBSF_iMrIA --prefix
# All Consumer Group starting with mytopic
/usr/local/bin/confluent iam rbac role-binding create --principal User:kafka-connect-lab01.nrsh13-hadoop.com --role ResourceOwner --resource Group:mytopic --kafka-cluster-id NNF36VtuQYGyvBSF_iMrIA --prefix
```

- To Provide individual permissions like Develoer Read/Write etc using Control Center UI-

Producers -

	- Falied to Create Topic mytopic-avro: KafkaError{code=TOPIC_AUTHORIZATION_FAILED,val=29,str="Authorization failed."} => 

```
Access => Cluster => Topics => Use PREFIX (not LITERAL)
	
	Resource ID => Role => Principal type =>  Principal name
	mytopic* => DeveloperWrite => User => kafka-connect-lab01.nrsh13-hadoop.com
```

	- Exception happened : KafkaError{code=_VALUE_SERIALIZATION,val=-161,str="User is denied operation Write on Subject: mytopic-avro-value (HTTP status code 403, SR code 40301)"}

```
Access => Schema Registry => Subjects => 

	Resource ID => Role => Principal type =>  Principal name
	* => DeveloperWrite => User => ANONYMOUS
	* => DeveloperRead => User => ANONYMOUS
	* => DeveloperWrite => User => kafka-connect-lab01.nrsh13-hadoop.com  # => This does not work. Reason - The schema registry component needs to be setup to support mTLS, we haven't gotten around to it yet. You can use basic and provide the service account credentials in the client and set that user to have developer write
```

	
Consumers -

```
Exception happened : KafkaError{code=TOPIC_AUTHORIZATION_FAILED,val=29,str="Fetch from broker 1 failed: Broker: Topic authorization failed"} /var/log/kafka/kafka-authorizer.log => [2022-07-20 17:27:20,470] INFO Principal = User:kafka-connect-lab01.nrsh13-hadoop.com is Denied Operation = Read from host = 10.86.113.95 on resource = Topic:LITERAL:mytopic-avro (kafka.authorizer.logger)
```
Access => Topics =>
	
	Resource ID => Role => Principal type =>  Principal name
	mytopic* => DeveloperRead => User => kafka-connect-lab01.nrsh13-hadoop.com


```
Exception happened : KafkaError{code=GROUP_AUTHORIZATION_FAILED,val=30,str="FindCoordinator response error: Group authorization failed."}

/var/log/kafka/kafka-authorizer.log => [2022-07-20 17:29:36,945] INFO Principal = User:kafka-connect-lab01.nrsh13-hadoop.com is Denied Operation = Describe from host = 10.86.113.95 on resource = Group:LITERAL:kafka-connect-lab01.nrsh13-hadoop.com (kafka.authorizer.logger)
```

Here kafka-connect-lab01.nrsh13-hadoop.com is the CN from the certificates used in security section of the code.

Access => Cluster => Group =>
	
	Resource ID => Role => Principal type => Principal name
	kafka-connect-lab01.nrsh13-hadoop.com => DeveloperRead => User => kafka-connect-lab01.nrsh13-hadoop.com