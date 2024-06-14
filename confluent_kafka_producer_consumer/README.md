# Confluent Kafka Python Producer & Consumer

## Description

This project contains a Confluent Kafka Python Producer and Consumer code. This will work for Secure and Nonsecure Kafka Cluster.

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

[root@ansible ~]# python3.9 /tmp/confluent-kafka-any-topic-producer.py -h


usage: confluent-kafka-any-topic-producer.py [-h] [-t TOPIC] [-kb KAFKA_SERVER] [-sr SCHEMA_REGISTRY] [-cid CLIENTID] -sdt SERIALIZER_DESERIALIZER_TYPE [-secure] [-asyncapi]

Required Details For Kafka:

options:
  -h, --help            show this help message and exit
  -t TOPIC              Topic name - Brand new if serializer_deserializer_type is changed
  -kb KAFKA_SERVER      Kafka Broker with port - hostname:9092
  -sr SCHEMA_REGISTRY   Schema Registry full URL - https://hostname:18081
  -cid CLIENTID         Client ID having access to consume from topic
  -sdt SERIALIZER_DESERIALIZER_TYPE
                        Serializer Deserializer Type - avro, json or none
  -secure               Kafka Cluster is Secure
  -asyncapi             Kafka topics using asyncapi

# Help for Consumer

[root@ansible ~]#  python3.9 /tmp/confluent-kafka-any-topic-consumer.py -h

usage: confluent-kafka-any-topic-consumer.py [-h] [-t TOPIC] [-kb KAFKA_SERVER] [-sr SCHEMA_REGISTRY] [-cid CLIENTID] -sdt SERIALIZER_DESERIALIZER_TYPE [-secure] [-asyncapi]

Required Details For Kafka:

options:
  -h, --help            show this help message and exit
  -t TOPIC              Topic name - Brand new if serializer_deserializer_type is changed
  -kb KAFKA_SERVER      Kafka Broker with port - hostname:9092
  -sr SCHEMA_REGISTRY   Schema Registry full URL - https://hostname:18081
  -cid CLIENTID         Client ID having access to consume from topic
  -sdt SERIALIZER_DESERIALIZER_TYPE
                        Serializer Deserializer Type - avro, json or none
  -secure               Kafka Cluster is Secure
  -asyncapi             Kafka topics using asyncapi
```

- Running Producer
```
Avro: python3.9 /tmp/confluent-kafka-any-topic-producer.py -p avro -t mytopic_avro -n 5 -s ansi-lab01-01.nrsh13-hadoop.com -secure False
JSON: python3.9 /tmp/confluent-kafka-any-topic-producer.py -p json -t mytopic_json -n 5 -s ansi-lab01-01.nrsh13-hadoop.com -secure False
None: python3.9 /tmp/confluent-kafka-any-topic-producer.py -p none -t mytopic -n 5 -s ansi-lab01-01.nrsh13-hadoop.com -secure False

[root@ansible ~]# python3.9 /tmp/confluent-kafka-any-topic-producer.py -p json -t mytopic -n 5 -s ansi-lab01-01.nrsh13-hadoop.com -secure False


        Dependencies - python3.9 -m pip install confluent-kafka[avro] confluent-kafka boto3 jsonschema

        ALERT: This Script assumes All Services are running on same Machine ansi-lab01-01.nrsh13-hadoop.com !!
        if NOT, Update the required Details in Main() section of the Script.

INFO: Kakfa Connection Details:

        Kafka Broker     :  ansi-lab01-01.nrsh13-hadoop.com:9092
        Zookeeper        :  ansi-lab01-01.nrsh13-hadoop.com:2181
        Topic            :  mytopic_json
        Serializer Type  :  json
        Secure Cluster   :  False

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
Avro: python3.9 /tmp/confluent-kafka-any-topic-consumer.py -p avro -t mytopic_avro -s ansi-lab01-01.nrsh13-hadoop.com -secure False
JSON: python3.9 /tmp/confluent-kafka-any-topic-consumer.py -p json -t mytopic_json -s ansi-lab01-01.nrsh13-hadoop.com -secure False
None: python3.9 /tmp/confluent-kafka-any-topic-consumer.py -p none -t mytopic -s ansi-lab01-01.nrsh13-hadoop.com -secure False

[root@ansible ~]# python3.9 /tmp/confluent-kafka-any-topic-consumer.py -p json -t mytopic_json -s ansi-lab01-01.nrsh13-hadoop.com -secure False


        Dependencies - python3.9 -m pip install confluent-kafka[avro] confluent-kafka boto3 jsonschema

        ALERT: This Script assumes All Services are running on same Machine ansi-lab01-01.nrsh13-hadoop.com !!
        if NOT, Update the required Details in Main() section of the Script.

INFO: Kakfa Connection Details:

        Kafka Broker     :  ansi-lab01-01.nrsh13-hadoop.com:9092
        Zookeeper        :  ansi-lab01-01.nrsh13-hadoop.com:2181
        Topic            :  mytopic_json
        Serializer Type  :  json
        Secure Cluster   :  False

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
