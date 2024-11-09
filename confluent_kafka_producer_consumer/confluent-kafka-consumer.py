#!/usr/bin/env python
# This is a simple example of the Deserializer using JSON and Avro.

# Python Modules
import random, struct, sys, os, requests
import socket, json, sys, time, random
import os, random, argparse
import datetime
from dateutil.relativedelta import relativedelta
import struct, socket
from dotenv import load_dotenv

from confluent_kafka import admin
from confluent_kafka import KafkaError
from confluent_kafka import KafkaException
from confluent_kafka import Consumer
from confluent_kafka import DeserializingConsumer
from confluent_kafka.serialization import StringDeserializer
from confluent_kafka.schema_registry.avro import AvroDeserializer
from confluent_kafka.schema_registry.json_schema import JSONDeserializer
from confluent_kafka.schema_registry import SchemaRegistryClient

# Global variable declaration
asyncapi = False

class User(object):
    """
    Required when we used SerializingProducer|DeserializingConsumer instead of Producer|Consumer Method.
    SerializingProducer|DeserializingProducer - includes registering|deregistring Schema in SR
    """
    def __init__(self, metadata=None, data=None, **kwargs):
        if asyncapi:
            self.metadata = metadata
            self.data = data
        else:
            self.fname = kwargs.get('fname')
            self.lname = kwargs.get('lname')
            self.principal = kwargs.get('principal')
            self.email = kwargs.get('email')
            self.ipaddress = kwargs.get('ipaddress')
            self.passport_expiry_date = kwargs.get('passport_expiry_date')
            self.passport_make_date = kwargs.get('passport_make_date')
            self.mobile = kwargs.get('mobile')

def dict_to_user(obj, ctx):
    """
    Converts object literal(dict) to a User instance.
    """
    if obj is None:
        return None

    if asyncapi:
        return User(obj['metadata'],
            obj['data'])
    else:
        return User(fname=obj['fname'],
            lname=obj['lname'],
            email=obj['email'],
            ipaddress=obj['ipaddress'],
            principal=obj['principal'],
            passport_expiry_date=obj['passport_expiry_date'],
            passport_make_date=obj['passport_make_date'],
            mobile=obj['mobile'])



# Get Schema for Value
def get_schema(schemaRegistryUrl,topic):
        try:
                subject = topicSubjectInSR
                url="{}/subjects/{}/versions".format(schemaRegistryUrl, subject)
                headers = { 'Content-Type': 'application/vnd.schemaregistry.v1+json',}
                cert = (ssl_certificate_location,ssl_key_location)  # Make sure Cert is mentioned before Key

                # Get Latest Version
                print ("\nINFO: Making the API Call to SR")
                versions_response = requests.get(
                        url="{}/subjects/{}/versions".format(schemaRegistryUrl, subject),
                        headers=headers,
                        cert=cert if secure_cluster else None, # SSLV3_ALERT_BAD_CERTIFICATE
                        verify=ssl_ca_location if secure_cluster else None # CERTIFICATE_VERIFY_FAILED - unable to get local issuer certificate
                )

                latest_version = versions_response.json()[-1]

                # Get Value Schema
                schema_response = requests.get(
                        url="{}/subjects/{}/versions/{}".format(schemaRegistryUrl, subject, latest_version),
                        headers=headers,
                        cert=cert if secure_cluster else None, # SSLV3_ALERT_BAD_CERTIFICATE
                        verify=ssl_ca_location if secure_cluster else None # CERTIFICATE_VERIFY_FAILED - unable to get local issuer certificate
                )

                value_schema = schema_response.json()

                print ("\nINFO: Schema Found. Returning with Details")
                return value_schema["schema"]

        except Exception as ex:
                print ("\nERROR: Failed to get any Schema", ex , '\n')
                sys.exit(1)


def deserialize_schema(schemaRegistryUrl, schema_str, serializer_deserializer_type = 'json'):

    schema_registry_client = SchemaRegistryClient(schema_registry_conf)

    if ( serializer_deserializer_type == 'json' ):
      json_deserializer = JSONDeserializer(schema_str, from_dict=dict_to_user)
      return json_deserializer
    # For Avro
    else:
      avro_deserializer = AvroDeserializer(schema_registry_client, schema_str, from_dict=dict_to_user)
      return avro_deserializer


def consume_messages(consumer, topic, serializer_deserializer_type='json'):

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

            if ( serializer_deserializer_type in ['avro', 'json'] ):
              if user is not None:
                print("User record {}: \n"
                      "\tfname: {}\n"
                      "\tlname: {}\n"
                      "\temail: {}\n"
                      "\tprincipal: {}\n"
                      "\tpassport_expiry_date: {}\n"
                      "\tpassport_make_date: {}\n"
                      "\tmobile: {}\n"
                      .format(msg.key(),
                            user.data['fname'] if asyncapi else user.fname,
                            user.data['lname'] if asyncapi else user.lname,
                            user.data['email'] if asyncapi else user.email,
                            user.data['principal'] if asyncapi else user.principal,
                            user.data['passport_expiry_date'] if asyncapi else user.passport_expiry_date,
                            user.data['passport_make_date'] if asyncapi else user.passport_make_date,
                            user.data['mobile'] if asyncapi else user.mobile)
                    )                      
            else:
                print('Message Received: {}\n'.format(user))

        except Exception as ex:
           print("Exception happened :",ex)


# Main Function
if __name__ == '__main__':

        import socket
        hostnames = socket.gethostname()

        print("\n")
        parser = argparse.ArgumentParser(description="for eq.: python %s -t mytopic -kb mykafkabroker01:9093 -sr https://myschemaregistry01:18081 -tssr mytopic-value -sdt avro -cid mytopic-consumer -secure -asyncapi""" %(sys.argv[0]))
        parser.add_argument('-t', dest="topic", default="mytopic",
                            help="Topic name - Brand new if serializer_deserializer_type is changed")
        parser.add_argument('-kb', dest="kafka_server", required=False, default=hostnames,
                            help="Kafka Broker with port - hostname:9092")
        parser.add_argument('-sr', dest="schema_registry", required=False, default=hostnames,
                            help="Schema Registry full URL - https://hostname:18081")
        parser.add_argument('-tssr', dest="topic_subject_in_sr", required=False, default=None,
                            help="Topic Subject in SR - mytopic-value")        
        parser.add_argument('-sdt', dest="serializer_deserializer_type", required=True, default=None,
                            help="Serializer Deserializer Type - avro, json or none")  
        parser.add_argument('-cid', dest="clientID", default=None,
                            help="consumer only: Client ID having access to consume from topic.")          
        parser.add_argument('-n', dest="num_mesg", required=False, default=5,
                            help="producer only: Number of messages to produce")             
        parser.add_argument('-secure', dest="secure_cluster", required=False, action='store_true',
                            help="Kafka Cluster is Secure")
        parser.add_argument('-asyncapi', dest="asyncapi_enabled", required=False, action='store_true',
                            help="Kafka topics using asyncapi")         


        args = parser.parse_args()

        topic = args.topic
        kafkaBroker = args.kafka_server
        schemaRegistryUrl = args.schema_registry
        secure_cluster = args.secure_cluster
        asyncapi = args.asyncapi_enabled
        serializer_deserializer_type = args.serializer_deserializer_type  
        clientID = getattr(args, 'clientID', None) or f"{topic}-consumer"
        topicSubjectInSR = getattr(args, 'topic_subject_in_sr', None) or f"{topic}-value"

        if secure_cluster is None:
            secure_cluster = False

        if schemaRegistryUrl is None and serializer_deserializer_type in ['avro', 'json']:
            print("\nError: Schema registry URL is required for Avro or JSON deserialization.\n")
            parser.print_help()
            exit(1)
        elif not serializer_deserializer_type:
            print("\nError: Please specify the serializer type (-p).\n")
            parser.print_help()
            exit(1)  

        # Security
        load_dotenv()
        security_protocol = 'SSL'
        home_dir = os.getenv('HOME')
        ssl_ca_location = f"{home_dir}/Downloads/cabundle.crt"  # Root Cert
        ssl_key_location = f"{home_dir}/Downloads/kafka.key" # Priavte Key
        ssl_certificate_location = f"{home_dir}/Downloads/kafka.crt" # Response Cert - kafka-connect-lab01.nrsh13-hadoop.com
        # Update Details End

        if secure_cluster:
            # Check if the cert files exist
            if not (os.path.exists(ssl_ca_location) and os.path.exists(ssl_key_location) and os.path.exists(ssl_certificate_location)):
                print("Error: As you chose -secure option. Please make sure these files are in the /tmp/ folder:\n")
                print(f"\tRoot Cert: {ssl_ca_location}")
                print(f"\tPrivate Key: {ssl_key_location}")
                print(f"\tResponse Cert: {ssl_certificate_location}\n\n")
                sys.exit(1)  # Exiting the script        

        print ("""INFO: Kakfa Connection Details:
               
        Serializer Type  :  %s
        AsyncAPI Used    :  %s
        Secure Cluster   :  %s
        Topic            :  %s
        Client ID        :  %s               
        Kafka Broker     :  %s
        Schema Registry  :  %s  
        TopicSubjectInSR :  %s             
        Dependencies     :  python3.9 -m pip install confluent-kafka confluent-kafka[avro] requests dateutils fastavro jsonschema python-dotenv.""" %(serializer_deserializer_type,asyncapi,secure_cluster,topic,clientID,kafkaBroker,schemaRegistryUrl,topicSubjectInSR))

        # Test HOW Access is sorted based on certificate CN
        if secure_cluster:
            kafka_conf = {
                    "bootstrap.servers": kafkaBroker,
                    "group.id": clientID,
                    "security.protocol": security_protocol,
                    "ssl.certificate.location": ssl_certificate_location,
                    "ssl.ca.location": ssl_ca_location,
                    "ssl.key.location": ssl_key_location,
            }
            schema_registry_conf = {
                     'url': schemaRegistryUrl,
                     "ssl.certificate.location": ssl_certificate_location,
                     "ssl.ca.location": ssl_ca_location,
                     "ssl.key.location": ssl_key_location,
            }
        else:
            kafka_conf = {
                    "bootstrap.servers": kafkaBroker,
                    "group.id": clientID
            }
            schema_registry_conf = {
                    'url': schemaRegistryUrl
            }

        consumer_conf = kafka_conf

        if ( serializer_deserializer_type == 'avro' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(serializer_deserializer_type, topic))
            schema_str = get_schema(schemaRegistryUrl,topic)
            print ("\nINFO: Deserialize Schema for Topic %s" %(topic))
            avro_deserializer = deserialize_schema(schema_registry_conf, schema_str, serializer_deserializer_type)
        elif ( serializer_deserializer_type == 'json' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(serializer_deserializer_type, topic))
            schema_str = get_schema(schemaRegistryUrl,topic)
            print ("\nINFO: Deserialize Schema for Topic %s" %(topic))
            json_deserializer = deserialize_schema(schema_registry_conf, schema_str, serializer_deserializer_type)
        else:
            print ("\nINFO: No Schema Pull Required for Non Serialzer topic %s" %topic)

        print ("\nINFO: Create Client obj for Kafka Connection")

        if ( serializer_deserializer_type == 'avro' ):
            consumer_conf['key.deserializer'] = StringDeserializer('utf_8')
            consumer_conf['value.deserializer'] = avro_deserializer
            consumer = DeserializingConsumer(consumer_conf)
        elif ( serializer_deserializer_type == 'json' ):
            consumer_conf['key.deserializer'] = StringDeserializer('utf_8')
            consumer_conf['value.deserializer'] = json_deserializer # without this - Exception happened : a bytes-like object is required, not 'User'
            consumer = DeserializingConsumer(consumer_conf)
        else:
            consumer = Consumer(consumer_conf)

        consume_messages(consumer, topic, serializer_deserializer_type)