#!/usr/bin/env python
# This is a simple example of the SerializingProducer using JSON and Avro.

# Python Modules
import random, struct, sys, os, requests
import socket, json, sys, time, random
import os, random, argparse
import datetime
from dateutil.relativedelta import relativedelta
import struct, socket

from confluent_kafka import admin
from confluent_kafka import KafkaException
from confluent_kafka import Producer
from confluent_kafka import SerializingProducer
from confluent_kafka.serialization import StringSerializer
from confluent_kafka.schema_registry.avro import AvroSerializer
from confluent_kafka.schema_registry.json_schema import JSONSerializer
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


def user_to_dict(user, ctx):
    """
    Returns a dict representation of a User instance for serialization.
    Returns:
        dict: Dict populated with user attributes to be serialized.
    """
    return dict(fname=user.fname,
            lname=user.lname,
            email=user.email,
            ipaddress=user.ipaddress,
            principal=user.principal,
            passport_expiry_date=user.passport_expiry_date,
            passport_make_date=user.passport_make_date,
            mobile=user.mobile)


def delivery_report(err, msg):
    """
    Reports the failure or success of a message delivery.
    Note:
        In the delivery report callback the Message.key() and Message.value()
        will be the binary format as encoded by any configured Serializers and
        not the same object that was passed to produce().
    """
    if err is not None:
        print("Delivery failed for User record {}: {}".format(msg.key(), err))
        return
    print('\tUser record {} successfully produced to {} [{}] at offset {}\n'.format(
        msg.key(), msg.topic(), msg.partition(), msg.offset()))



# Get Schema for Value
def get_schema(SCHEMA_REGISTRY_URL,topic):
        try:
                subject = topic + '-value'
                url="{}/subjects/{}/versions".format(SCHEMA_REGISTRY_URL, subject),
                headers = { 'Content-Type': 'application/vnd.schemaregistry.v1+json',}

                # Get Latest Version
                print ("\nINFO: Making the API Call to SR")
                versions_response = requests.get(
                        url="{}/subjects/{}/versions".format(SCHEMA_REGISTRY_URL, subject),
                        headers={
                                "Content-Type": "application/vnd.schemaregistry.v1+json",
                        }, verify=ssl_ca_location
                )

                latest_version = versions_response.json()[-1]

                # Get Value Schema
                schema_response = requests.get(
                        url="{}/subjects/{}/versions/{}".format(SCHEMA_REGISTRY_URL, subject, latest_version),
                        headers={
                                "Content-Type": "application/vnd.schemaregistry.v1+json",
                        }, verify=ssl_ca_location
                )

                value_schema = schema_response.json()

                print ("\nINFO: Schema Found in SR. Returning with Details")
                return value_schema["schema"]

        except Exception as ex:
                print ("\nWARN: Failed to get Schema from SR. Using Default Schema now", ex , '\n')
                return 'none'


def serialize_schema(SCHEMA_REGISTRY_URL, schema_str, producer_serializer_type = 'json'):

    # Use below schemas when Schema does not exists in SR.
    if ( producer_serializer_type == 'json' and schema_str == 'none' ):
      schema_str = """
    {
      "$schema": "http://json-schema.org/draft-07/schema#",
      "title": "User",
      "description": "A Confluent Kafka Python User",
      "type": "object",
      "properties": {
        "fname": {
          "description": "User's fname",
          "type": "string"
        },
        "lname": {
          "description": "User's lname",
          "type": "string"
        },
        "email": {
          "description": "User's email",
          "type": "string"
        },
        "principal": {
          "description": "User's principal",
          "type": "string"
        },

        "ipaddress": {
          "description": "User's ipaddress",
          "type": "string"
        },
        "passport_make_date": {
          "description": "User's Passport Make Date",
          "type": "string"
        },
        "passport_expiry_date": {
          "description": "User's Passport Expiry Date",
          "type": "string"
        },
        "mobile": {
          "description": "User's Mobile Number",
          "type": "number",
          "exclusiveMinimum": 0
        }
      },
      "required": [ "fname", "lname", "email", "principal", "ipaddress", "passport_make_date", "passport_expiry_date", "mobile" ]
    }
    """
    # For Avro
    elif ( producer_serializer_type == 'avro' and schema_str == 'none' ) :

      schema_str = """
{
  "name": "value",
  "namespace": "mytopic",
  "type": "record",
  "fields": [
    {
      "name": "fname",
      "type": "string"
    },
    {
      "name": "lname",
      "type": "string"
    },
    {
      "name": "email",
      "type": "string"
    },
    {
      "name": "principal",
      "type": "string"
    },
    {
      "name": "ipaddress",
      "type": "string"
    },
    {
      "name": "mobile",
      "type": "long"
    },
    {
      "default": "None",
      "logicalType": "timestamp",
      "name": "passport_make_date",
      "type": [
        "string",
        "null"
      ]
    },
    {
      "logicalType": "date",
      "name": "passport_expiry_date",
      "type": "string"
    }
  ]
}
"""

    else:
       schema_str = schema_str

    schema_registry_client = SchemaRegistryClient(schema_registry_conf)

    if ( producer_serializer_type == 'json' ):
      json_serializer = JSONSerializer(schema_str, schema_registry_client, user_to_dict)
      return json_serializer
    # For Avro
    else: # To Avoid Producer writing the schema to SR. set below. NO Permissions in Enterprise Kafka to write the schema.
      #pro_conf = {"auto.register.schemas": False}
      #avro_serializer = AvroSerializer(schema_registry_client, schema_str, user_to_dict, conf=pro_conf)
      avro_serializer = AvroSerializer(schema_registry_client, schema_str, user_to_dict) # Order of arguments is different from JSONSerializer and important. AttributeError: 'SchemaRegistryClient' object has no attribute 'strip'
      return avro_serializer


# Check and Create if the Topic Does not Exist.
def check_topic_existence(connection, topic):
        """ Check Topic Existence and Create it if needed"""

        chk_topic = connection.list_topics().topics

        if chk_topic.get(topic):
                print ("\nINFO: Topic %s Exists." %topic)
        else:
                print ("\nINFO: Creating the Topic %s" %topic)
                # NewTopic specifies per-topic settings for passing to passed to AdminClient.create_topics().
                setTopic = admin.NewTopic(topic ,num_partitions=1, replication_factor=1)
                fs = connection.create_topics([setTopic],request_timeout=10)

                for t,f in fs.items():
                    try:
                        f.result()  # The result itself is None
                        print("\nINFO: Topic {} Created".format(t))
                    except KafkaException as e:
                        print("Falied to Create Topic {}: {}".format(t, e))
                        sys.exit()


def produce_messages(producer, num_mesg, topic, producer_serializer_type='json'):

    """ Produce Messages to the Topic """

    fnames = ["James","John","Robert","Michael","William","David","Richard","Joseph","Thomas","Charles","Christopher","Daniel","Matthew","Anthony","Donald","Mark","Paul","Steven","Andrew","Kenneth","George","Joshua","Kevin","Brian","Edward","Ronald","Timothy","Jason","Jeffrey","Ryan","Gary","Jacob","Nicholas","Eric","Stephen","Jonathan","Larry","Justin","Scott","Frank","Brandon","Raymond","Gregory","Benjamin","Samuel","Patrick","Alexander","Jack","Dennis","Jerry","Tyler","Aaron","Henry","Douglas","Jose","Peter","Adam","Zachary","Nathan","Walter","Harold","Kyle","Carl","Arthur","Gerald","Roger","Keith","Jeremy","Terry","Lawrence","Sean","Christian","Albert","Joe","Ethan","Austin","Jesse","Willie","Billy","Bryan","Bruce","Jordan","Ralph","Roy","Noah","Dylan","Eugene","Wayne","Alan","Juan","Louis","Russell","Gabriel","Randy","Philip","Harry","Vincent","Bobby","Johnny","Logan","naresh","ravi","Bhanu","akash","jane","gaurav","sailesh","tom","Andrea","Steve","Kris","Virender","Jason","stephen","Daemon","Elena","manu","nimisha","Bruce","michael","Akshay"]

    lnames = ["mith","ohnson","illiams","ones","rown","avis","iller","ilson","oore","Taylor","Anderson","Thomas","Jackson","White","Harris","Martin","Thompson","Garcia","Martinez","Robinson","Clark","Rodriguez","Lewis","Lee","Walker","Hall","Allen","Young","Hernandez","King","Wright","Lopez","Hill","Scott","Green","Adams","Baker","Gonzalez","Nelson","Carter","Mitchell","Perez","Roberts","Turner","Phillips","Campbell","Parker","Evans","Edwards","Collins","Stewart","Sanchez","Morris","Rogers","Reed","Cook","Morgan","Bell","Murphy","Bailey","Rivera","Cooper","Richardson","Cox","Howard","Ward","Torres","Peterson","Gray","Ramirez","James","Watson","Brooks","Kelly","Sanders","Price","Bennett","Wood","Barnes","Ross","Henderson","Coleman","Jenkins","Perry","Powell","Long","jangra","verma","sharma","weign","nain","devgun","gaundar","dagarin","thomas","ramayna","bourne","salvator","gilbert","beniwal","kumar","khanna","khaneja","singh","bansal","gupta","kaushik"]

    emails = ["@gmail.com","@@yahoo.com","@hotmail.com","@aol.com","@hotmail.co.uk","@rediffmail.com","@ymail.com","@outlook.com","@@gmail.com","hotmail.com","@hotmail.com","@bnz.co.nz","@nbc.com","@yahoo.com","#gmail.com","@hcl.com","@#tcs.com","@tcs.com","##hcl.com"]

    try:
            print("\nINFO: Producing Messages - \n")

            for val in range(0,num_mesg):
                #time.sleep(1)
                fname=random.choice(fnames)
                lname=random.choice(lnames)
                email=random.choice(emails)
                ipaddress = socket.inet_ntoa(struct.pack('>I', random.randint(1, 0xffffffff)))
                mobile = random.randint(9800000000,9899999999)
                passport_expiry_date = (datetime.datetime.now() + datetime.timedelta(random.randint(1,100)*365/12))
                passport_make_date = (passport_expiry_date - relativedelta(years=10))

                passport_make_date = passport_make_date.date()
                passport_expiry_date = passport_expiry_date.date()

                if val%5 == 0:
                        mobile = "9"+str(mobile)

                key =  mobile

                if ( producer_serializer_type in ['avro', 'json'] ):
                    user = User(fname=fname,
                            lname=lname,
                            email=fname+'_'+lname+email,
                            ipaddress=ipaddress,
                            principal=fname+"@EXAMPLE.COM",
                            passport_expiry_date=str(passport_expiry_date),
                            passport_make_date=str(passport_make_date),
                            mobile=int(mobile))
                else:
                    user = {"fname" : fname, "lname" : lname, "email" : fname+"_"+lname+email, "principal" : fname+"@EXAMPLE.COM", "passport_make_date" : str(passport_make_date), "passport_expiry_date" : str(passport_expiry_date), "ipaddress" : ipaddress , "mobile" : int(mobile)}
                    user = str(user).encode()

                producer.produce(topic=topic, value=user, key=str(key), on_delivery=delivery_report)

                # Polls the producer for events and calls the corresponding callbacks (if registered).
                producer.poll(0.5)

            producer.flush()

    except Exception as ex:
           print("Exception happened :",ex)



# Main Function
if __name__ == '__main__':

        import socket
        hostnames = socket.gethostname()

        print("\n")
        parser = argparse.ArgumentParser(description="Required Details For Kafka Producer -")
        parser.add_argument('-p', dest="producer_serializer_type", required=True, default='none', choices=['avro', 'json', 'none'],
            help="Serializer Type - avro, json or none")
        parser.add_argument('-t', dest="topic", default="mytopic",
            help="Topic name - Brand new if producer_serializer_type is changed")
        parser.add_argument('-n', dest="num_mesg", required=False, default=5,
            help="Number of Messages you want ot Produce")
        parser.add_argument('-s', dest="kafka_server", required=False, default=hostnames,
            help="Kafka, ZK and Schema Registry Servers - Assuming all runs on One Machine")
        parser.add_argument('-secure', dest="secure_cluster", required=False, default=True, choices=['True', 'False'],
            help="Kafka Cluster is Secure - True or False")

        args = parser.parse_args()

        producer_serializer_type = args.producer_serializer_type
        topic = args.topic
        num_mesg = int(args.num_mesg)
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
            zookeeperPort = 2182
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
        ssl_certificate_location = '/var/ssl/private/kafka_broker.crt' # Response Cert
        # Update Details End

        print ("""\nINFO: Kakfa Connection Details:

        Kafka Broker     :  %s
        Zookeeper        :  %s
        Topic            :  %s
        Serializer Type  :  %s
        Secure Cluster   :  %s """ %(kafkaBroker,zookeeper,topic,producer_serializer_type,secure_cluster))

        # Test HOW Access is sorted based on certificate CN
        if secure_cluster is True:
            kafka_conf = {
                    "bootstrap.servers": kafkaBroker,
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
                    "bootstrap.servers": kafkaBroker
            }
            schema_registry_conf = {
                    'url': SCHEMA_REGISTRY_URL
            }

        print ("\nINFO: Creating connection obj for Admin Task")
        connection = admin.AdminClient(kafka_conf)

        print ("\nINFO: Check if Topic %s exists. Else Create it" %topic)
        check_topic_existence(connection, topic)

        producer_conf = kafka_conf

        if ( producer_serializer_type == 'avro' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(producer_serializer_type, topic))
            schema_str = get_schema(SCHEMA_REGISTRY_URL,topic)
            print ("\nINFO: Set up %s Schema for Topic %s" %(producer_serializer_type, topic))
            avro_serializer = serialize_schema(schema_registry_conf, schema_str, producer_serializer_type)
        elif ( producer_serializer_type == 'json' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(producer_serializer_type, topic))
            schema_str = get_schema(SCHEMA_REGISTRY_URL,topic)
            print ("\nINFO: Set up %s Schema for Topic %s" %(producer_serializer_type, topic))
            json_serializer = serialize_schema(schema_registry_conf, schema_str, producer_serializer_type)
        else:
            print ("\nINFO: No Schema set Required for None Option")

        print ("\nINFO: Create Client obj for Kafka Connection")

        if ( producer_serializer_type == 'avro' ):
            producer_conf['key.serializer'] = StringSerializer('utf_8')
            producer_conf['value.serializer'] = avro_serializer
            producer = SerializingProducer(producer_conf)
        elif ( producer_serializer_type == 'json' ):
            producer_conf['key.serializer'] = StringSerializer('utf_8')
            producer_conf['value.serializer'] = json_serializer # without this - Exception happened : a bytes-like object is required, not 'User'
            producer = SerializingProducer(producer_conf)
        else:
            producer = Producer(producer_conf)

        produce_messages(producer,int(num_mesg),topic, producer_serializer_type)

