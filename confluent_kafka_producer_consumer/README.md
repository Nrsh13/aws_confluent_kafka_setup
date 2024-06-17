# Confluent Kafka Python Producer & Consumer

## Description

This project contains Confluent Kafka Python Producer and Consumer code. This will work for Secure and Nonsecure Kafka Cluster based on the arguments passed.

## Pre-requisites

- Build required number of EC2 instances following confluent_kafka_infra_setup/README.md
- Below packages are required which will already be installed. Install below if want to use this code somewhere else.
```
    yum install -y python39
    python3.9 -m pip install confluent-kafka confluent-kafka[avro] requests dateutils fastavro jsonschema python-dotenv
```
- For Secure Kafka Cluster, Make sure the root.crt/ca.crt, kafka.crt and kafka.key are present at ${HOME}/Downloads folder. kafka.key and kafka.crt are user certs having required permissons on the topic. NO CHANGES NEED IF USING ANY OF THE KAFKA BROKER TO USE THIS CODE.


## How to Run
- Check help for required arguments
```
# Help for Producer

[root@ansible ~]# python confluent-kafka-producer.py -h


usage: confluent-kafka-producer.py [-h] [-t TOPIC] [-kb KAFKA_SERVER] [-sr SCHEMA_REGISTRY] -sdt SERIALIZER_DESERIALIZER_TYPE [-n NUM_MESG]
                                   [-secure] [-asyncapi]

Required Details below: eq. python confluent-kafka-producer.py -t mytopic -kb mykafkabroker01:9093 -sr myschemaregistry01:18081 -sdt avro
-n 10 -secure -asyncapi

# Help for Consumer

[root@ansible ~]#  python confluent-kafka-consumer.py -h


usage: confluent-kafka-consumer.py [-h] [-t TOPIC] [-kb KAFKA_SERVER] [-sr SCHEMA_REGISTRY] -sdt SERIALIZER_DESERIALIZER_TYPE
                                   [-cid CLIENTID] [-n NUM_MESG] [-secure] [-asyncapi]

for eq.: python confluent-kafka-consumer.py -t mytopic -kb mykafkabroker01:9093 -sr myschemaregistry01:18081 -sdt avro -cid mytopic-
consumer -secure -asyncapi
```

- Running Producer
```
Avro|json|none: python confluent-kafka-producer.py -t mytopic -kb mykafkabroker01:9093 -sr myschemaregistry01:18081 -sdt avro|json|non
-n 10 -secure -asyncapi

[root@ansible ~]# python confluent-kafka-producer.py -t mytopic -kb mykafkabroker01:9093 -sr myschemaregistry01:18081 -sdt avro
-n 10 -secure -asyncapi

INFO: Kakfa Connection Details:
               
        Serializer Type  :  avro
        AsyncAPI Used    :  True
        Secure Cluster   :  True
        Topic            :  mytopic
        Client ID        :  mytopic-consumer               
        Kafka Broker     :  mykafkabroker01:9093
        Schema Registry  :  myschemaregistry01:18081               
        Dependencies     :  python3.9 -m pip install confluent-kafka confluent-kafka[avro] requests dateutils fastavro jsonschema python-dotenv.


INFO: Creating connection obj for Admin Task

INFO: Check if Topic mytopic_json exists. Else Create it

INFO: Topic mytopic Exists.

INFO: Get json Schema for Topic mytopic_json

INFO: Making the API Call to SR

INFO: Schema Found in SR. Returning with Details

INFO: Set up json Schema for Topic mytopic

INFO: Create Client obj for Kafka Connection

INFO: Producing Messages -

        User record b'99807619297' successfully produced to mytopic [0] at offset 20

        User record b'9870986622' successfully produced to mytopic [0] at offset 21

        User record b'9856998479' successfully produced to mytopic [0] at offset 22

        User record b'9843800704' successfully produced to mytopic [0] at offset 23

        User record b'9852477081' successfully produced to mytopic [0] at offset 24

```

- Running Consumer
```
Avro|Json|None: python confluent-kafka-consumer.py -t mytopic -kb mykafkabroker01:9093 -sr myschemaregistry01:18081 -sdt avro|json|none -cid mytopic-
consumer -secure -asyncapi

[root@ansible ~]# python confluent-kafka-consumer.py -t mytopic -kb mykafkabroker01:9093 -sr myschemaregistry01:18081 -sdt avro -cid mytopic-
consumer -secure -asyncapi

INFO: Kakfa Connection Details:
               
        Serializer Type  :  avro
        AsyncAPI Used    :  True
        Secure Cluster   :  True
        Topic            :  mytopic
        Client ID        :  mytopic-consumer               
        Kafka Broker     :  mykafkabroker01:9093
        Schema Registry  :  myschemaregistry01:18081               
        Dependencies     :  python3.9 -m pip install confluent-kafka confluent-kafka[avro] requests dateutils fastavro jsonschema python-dotenv.


INFO: Get json Schema for Topic mytopic_json

INFO: Making the API Call to SR

INFO: Schema Found. Returning with Details

INFO: Deserialize Schema for Topic mytopic

INFO: Create Client obj for Kafka Connection

INFO: Consuming Messages -

INFO: Consuming Messages -

User record 9835242072:
        fname: Matthew
        lname: Hernandez
        email: Matthew_Hernandez@gmail.com
        principal: Matthew@EXAMPLE.COM
        passport_expiry_date: 2028-06-11
        passport_make_date: 2018-06-11
        mobile: 9835242072


INFO: Consuming Messages -

User record 9884091681:
        fname: Roy
        lname: Torres
        email: Roy_Torres@tcs.com
        principal: Roy@EXAMPLE.COM
        passport_expiry_date: 2028-06-11
        passport_make_date: 2018-06-11
        mobile: 9884091681
```

## Contact
nrsh13@gmail.com
