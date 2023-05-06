#!/usr/bin/env python
# This is a simple example of the Deserializer using JSON and Avro.

# Python Modules
import random, struct, sys, os, requests
import socket, json, sys, time, random
import os, random, argparse
import datetime
from dateutil.relativedelta import relativedelta
import struct, socket

from confluent_kafka import admin
from confluent_kafka import KafkaError
from confluent_kafka import KafkaException
from confluent_kafka import Consumer
from confluent_kafka import DeserializingConsumer
from confluent_kafka.serialization import StringDeserializer
from confluent_kafka.schema_registry.avro import AvroDeserializer
from confluent_kafka.schema_registry.json_schema import JSONDeserializer
from confluent_kafka.schema_registry import SchemaRegistryClient


class User(object):
    """
    Required when we used SerializingProducer|DeserializingConsumer instead of Producer|Consumer Method.
    SerializingProducer|DeserializingProducer - includes registering|deregistring Schema in SR
    """
    def __init__(self, fname, lname, principal, email, ipaddress, passport_expiry_date, passport_make_date, mobile):
        self.fname = fname
        self.lname = lname
        self.principal = principal
        self.email = email
        self.ipaddress = ipaddress
        self.passport_expiry_date = passport_expiry_date
        self.passport_make_date = passport_make_date
        self.mobile = mobile


def dict_to_user(obj, ctx):
    """
    Converts object literal(dict) to a User instance.
    """
    if obj is None:
        return None

    return User(fname=obj['fname'],
            lname=obj['lname'],
            email=obj['email'],
            ipaddress=obj['ipaddress'],
            principal=obj['principal'],
            passport_expiry_date=obj['passport_expiry_date'],
            passport_make_date=obj['passport_make_date'],
            mobile=obj['mobile'])



# Get Schema for Value
def get_schema(SCHEMA_REGISTRY_URL,topic):
        try:
                subject = topic + '-value'
                url="{}/subjects/{}/versions".format(SCHEMA_REGISTRY_URL, subject)
                headers = { 'Content-Type': 'application/vnd.schemaregistry.v1+json',}
                cert = (ssl_certificate_location,ssl_key_location)  # Make sure Cert is mentioned before Key

                # Get Latest Version
                print ("\nINFO: Making the API Call to SR")
                versions_response = requests.get(
                        url="{}/subjects/{}/versions".format(SCHEMA_REGISTRY_URL, subject),
                        headers=headers,
                        cert=cert, # SSLV3_ALERT_BAD_CERTIFICATE
                        verify=ssl_ca_location # CERTIFICATE_VERIFY_FAILED - unable to get local issuer certificate
                )

                latest_version = versions_response.json()[-1]

                # Get Value Schema
                schema_response = requests.get(
                        url="{}/subjects/{}/versions/{}".format(SCHEMA_REGISTRY_URL, subject, latest_version),
                        headers=headers,
                        cert=cert, # SSLV3_ALERT_BAD_CERTIFICATE
                        verify=ssl_ca_location # CERTIFICATE_VERIFY_FAILED - unable to get local issuer certificate
                )

                value_schema = schema_response.json()

                print ("\nINFO: Schema Found. Returning with Details")
                return value_schema["schema"]

        except Exception as ex:
                print ("\nERROR: Failed to get any Schema", ex , '\n')
                sys.exit(1)


def deserialize_schema(SCHEMA_REGISTRY_URL, schema_str, consumer_deserializer_type = 'json'):

    schema_registry_client = SchemaRegistryClient(schema_registry_conf)

    if ( consumer_deserializer_type == 'json' ):
      json_deserializer = JSONDeserializer(schema_str, from_dict=dict_to_user)
      return json_deserializer
    # For Avro
    else:
      avro_deserializer = AvroDeserializer(schema_registry_client, schema_str, from_dict=dict_to_user)
      return avro_deserializer


def consume_messages(consumer, topic, consumer_deserializer_type='json'):

    """ Consume Messages to the Topic """
    consumer.subscribe([topic])
    while True:
        try:
            print("\nINFO: Consuming Messages - \n")
            msg = consumer.poll(0.5)
            if msg is None:
                continue

            if msg.error():
                if msg.error().code() == KafkaError._PARTITION_EOF:
                    continue
                else:
                    print(msg.error())
                    break

            user = msg.value()

            if ( consumer_deserializer_type in ['avro', 'json'] ):
              if user is not None:
                print("User record {}: \n"
                      "\tfname: {}\n"
                      "\tlname: {}\n"
                      "\temail: {}\n"
                      "\tprincipal: {}\n"
                      "\tpassport_expiry_date: {}\n"
                      "\tpassport_make_date: {}\n"
                      "\tmobile: {}\n"
                      .format(msg.key(), user.fname,
                              user.lname,
                              user.email,
                              user.principal,
                              user.passport_expiry_date,
                              user.passport_make_date,
                              user.mobile))
            else:
                print('Message Received: {}\n'.format(user))

        except Exception as ex:
           print("Exception happened :",ex)


# Main Function
if __name__ == '__main__':

        import socket
        hostnames = socket.gethostname()

        print("\n")
        parser = argparse.ArgumentParser(description="Required Details For Kafka Producer -")
        parser.add_argument('-p', dest="consumer_deserializer_type", required=True, default='none', choices=['avro', 'json', 'none'],
            help="Serializer Type - avro, json or none")
        parser.add_argument('-t', dest="topic", default="mytopic",
            help="Topic name - Brand new if consumer_deserializer_type is changed")
        parser.add_argument('-s', dest="kafka_server", required=False, default=hostnames,
            help="Kafka, ZK and Schema Registry Servers - Assuming all runs on One Machine")
        parser.add_argument('-secure', dest="secure_cluster", required=False, default=True, choices=['True', 'False'],
            help="Kafka Cluster is Secure - True or False")

        args = parser.parse_args()

        consumer_deserializer_type = args.consumer_deserializer_type
        topic = args.topic
        hostname = args.kafka_server
        secure_cluster = args.secure_cluster

        print ("""        Dependencies - python3.9 -m pip install confluent-kafka[avro] confluent-kafka boto3 jsonschema

        ALERT: This Script assumes All Services are running on same Machine {} !!
        if NOT, Update the required Details in Main() section of the Script.""".format(hostname))

        ##### Update Details Start
        kafkaBrokerServer = hostname
        zookeeperServer = hostname
        schemaRegistryServer = hostname

        if secure_cluster is True:
            kafkaBrokerPort = 9093
            zookeeperPort = 2181
            schemaRegistryPort = 18081
            SCHEMA_REGISTRY_URL = 'https://'+schemaRegistryServer+':'+str(schemaRegistryPort)
        else:
            kafkaBrokerPort = 9092
            zookeeperPort = 2181
            schemaRegistryPort = 8081
            SCHEMA_REGISTRY_URL = 'http://'+schemaRegistryServer+':'+str(schemaRegistryPort)

        zookeeper = zookeeperServer+":"+str(zookeeperPort)
        kafkaBroker = kafkaBrokerServer+":"+str(kafkaBrokerPort)

        # Security
        security_protocol = 'SSL'
        ssl_ca_location = "/var/ssl/private/ca.crt"  # Root Cert
        ssl_key_location = '/var/ssl/private/kafka_broker.key' # Priavte Key
        ssl_certificate_location = '/var/ssl/private/kafka_broker.crt' # Response Cert - kafka-connect-lab01.nrsh13-hadoop.com
        # Update Details End

        print ("""\nINFO: Kakfa Connection Details:

        Kafka Broker     :  %s
        Zookeeper        :  %s
        Topic            :  %s
        Serializer Type  :  %s
        Secure Cluster   :  %s """ %(kafkaBroker,zookeeper,topic,consumer_deserializer_type,secure_cluster))

        # Test HOW Access is sorted based on certificate CN
        if secure_cluster is True:
            kafka_conf = {
                    "bootstrap.servers": kafkaBroker,
                    "group.id": topic + "-consumer",
                    "security.protocol": security_protocol,
                    "ssl.certificate.location": ssl_certificate_location,
                    "ssl.ca.location": ssl_ca_location,
                    "ssl.key.location": ssl_key_location,
            }
            schema_registry_conf = {'url': SCHEMA_REGISTRY_URL,
                     "ssl.certificate.location": ssl_certificate_location,
                     "ssl.ca.location": ssl_ca_location,
                     "ssl.key.location": ssl_key_location,
            }
        else:
            kafka_conf = {
                    "bootstrap.servers": kafkaBroker,
                    "group.id": topic + "-consumer"
            }
            schema_registry_conf = {
                    'url': SCHEMA_REGISTRY_URL
            }

        consumer_conf = kafka_conf

        if ( consumer_deserializer_type == 'avro' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(consumer_deserializer_type, topic))
            schema_str = get_schema(SCHEMA_REGISTRY_URL,topic)
            print ("\nINFO: Deserialize Schema for Topic %s" %(topic))
            avro_deserializer = deserialize_schema(schema_registry_conf, schema_str, consumer_deserializer_type)
        elif ( consumer_deserializer_type == 'json' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(consumer_deserializer_type, topic))
            schema_str = get_schema(SCHEMA_REGISTRY_URL,topic)
            print ("\nINFO: Deserialize Schema for Topic %s" %(topic))
            json_deserializer = deserialize_schema(schema_registry_conf, schema_str, consumer_deserializer_type)
        else:
            print ("\nINFO: No Schema Pull Required for Non Serialzer topic %s" %topic)

        print ("\nINFO: Create Client obj for Kafka Connection")

        if ( consumer_deserializer_type == 'avro' ):
            consumer_conf['key.deserializer'] = StringDeserializer('utf_8')
            consumer_conf['value.deserializer'] = avro_deserializer
            consumer = DeserializingConsumer(consumer_conf)
        elif ( consumer_deserializer_type == 'json' ):
            consumer_conf['key.deserializer'] = StringDeserializer('utf_8')
            consumer_conf['value.deserializer'] = json_deserializer # without this - Exception happened : a bytes-like object is required, not 'User'
            consumer = DeserializingConsumer(consumer_conf)
        else:
            consumer = Consumer(consumer_conf)

        consume_messages(consumer, topic, consumer_deserializer_type)
