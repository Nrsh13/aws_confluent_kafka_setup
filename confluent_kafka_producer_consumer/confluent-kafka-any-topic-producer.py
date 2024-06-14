#!/usr/bin/env python
# This is a simple example of the SerializingProducer using JSON and Avro.

# Python Modules
from uuid import uuid4
import random, struct, sys, os, requests
import socket, json, sys, time, random
import os, random, argparse
import datetime
from dateutil.relativedelta import relativedelta
import struct, socket
from dotenv import load_dotenv

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


def user_to_dict(user, ctx, asyncapi):
    """
    Returns a dict representation of a User instance for serialization.
    Returns:
        dict: Dict populated with user attributes to be serialized.
    """
    if asyncapi:
      return dict(metadata=user.metadata,
            data=user.data)
    else:
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
                url="{}/subjects/{}/versions".format(SCHEMA_REGISTRY_URL, subject)
                headers = { 'Content-Type': 'application/vnd.schemaregistry.v1+json',}
                cert = (ssl_certificate_location,ssl_key_location) # Make sure Cert is mentioned before Key

                # Get Latest Version
                print ("\nINFO: Making the API Call to SR")

                #For SSLError -> https://levelup.gitconnected.com/solve-the-dreadful-certificate-issues-in-python-requests-module-2020d922c72f
                versions_response = requests.get(
                        url=url,
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

                print ("\nINFO: Schema Found in SR. Returning with Details")
                return value_schema["schema"]

        except Exception as ex:
                print ("\nWARN: Failed to get Schema from SR. Using Default Schema now", ex , '\n')
                return 'none'


def serialize_schema(SCHEMA_REGISTRY_URL, schema_str, serializer_deserializer_type = 'json'):

    # Use below schemas when Schema does not exists in SR.
    if ( serializer_deserializer_type == 'json' and schema_str == 'none' ):
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
    elif ( serializer_deserializer_type == 'avro' and schema_str == 'none' ) :

      ## Different if we used asyncapi
      if asyncapi:
          
        schema_str = """
{
  "fields": [
    {
      "default": null,
      "name": "metadata",
      "type": [
        "null",
        {
          "fields": [
            {
              "name": "id",
              "type": "string"
            },
            {
              "name": "time",
              "type": "string"
            },
            {
              "name": "subject",
              "type": "string"
            },
            {
              "name": "source",
              "type": "string"
            },
            {
              "name": "type",
              "type": "string"
            },
            {
              "default": null,
              "name": "correlationId",
              "type": [
                "null",
                "string"
              ]
            }
          ],
          "name": "TestAvroEventsMetaData",
          "type": "record"
        }
      ]
    },
    {
      "default": null,
      "name": "data",
      "type": [
        "null",
        {
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
              "default": null,
              "name": "ipaddress",
              "type": [
                "null",
                "string"
              ]
            },
            {
              "name": "mobile",
              "type": "long"
            },
            {
              "name": "passport_make_date",
              "type": "string"
            },
            {
              "name": "passport_expiry_date",
              "type": "string"
            }
          ],
          "name": "TestAvroEventsData",
          "type": "record"
        }
      ]
    }
  ],
  "name": "TestAvroEventsMessageValue",
  "namespace": "DOMAIN.SUBDOMAIN",
  "type": "record"
}
"""

      else:
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

    if ( serializer_deserializer_type == 'json' ):
      json_serializer = JSONSerializer(schema_str, schema_registry_client, user_to_dict(asyncapi))
      return json_serializer
    # For Avro
    else: # To Avoid Producer writing the schema to SR. set below. NO Permissions in Enterprise Kafka to write the schema.
      #pro_conf = {"auto.register.schemas": False}
      #avro_serializer = AvroSerializer(schema_registry_client, schema_str, user_to_dict, conf=pro_conf)
      avro_serializer = AvroSerializer(schema_registry_client, schema_str, user_to_dict(asyncapi)) # Order of arguments is different from JSONSerializer and important. AttributeError: 'SchemaRegistryClient' object has no attribute 'strip'
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


def produce_messages(producer, num_mesg, topic, serializer_deserializer_type='json'):

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

                if ( serializer_deserializer_type in ['avro', 'json'] ):

                  if asyncapi:
                    metadata = {"id": str(uuid4()),"time": str(datetime.datetime.now()), "type" : "testing", "subject": "SUBDOMAIN", "source": "SUBDOMAIN", "correlationId" : "testing"}

                    data = {"fname" : fname, "lname" : lname, "email" : fname+"_"+lname+email, "principal" : fname+"@EXAMPLE.COM", "ipaddress" : ipaddress , "mobile" : int(mobile), "passport_make_date" : str(passport_make_date), "passport_expiry_date" : str(passport_expiry_date)}

                    user = User(metadata=metadata, data=data)
                  
                  else:           
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
        parser = argparse.ArgumentParser(description="Required Details For Kafka:")
        parser.add_argument('-t', dest="topic", default="mytopic",
                            help="Topic name - Brand new if serializer_deserializer_type is changed")
        parser.add_argument('-kb', dest="kafka_server", required=False, default=hostnames,
                            help="Kafka Broker with port - hostname:9092")
        parser.add_argument('-sr', dest="schema_registry", required=False, default=hostnames,
                            help="Schema Registry full URL - https://hostname:18081")
        parser.add_argument('-cid', dest="clientID", default=None,
                            help="Client ID having access to consume from topic.")  
        parser.add_argument('-sdt', dest="serializer_deserializer_type", required=True, default='none',
                            help="Serializer Deserializer Type - avro, json or none")                 
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
        clientID = args.clientID if args.clientID else f"{topic}-consumer"

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
        ssl_ca_location = f"{home_dir}/Downloads/ca.crt"  # Root Cert
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

        print ("""\nINFO: Kakfa Connection Details:

        Dependencies     :  python3.9 -m pip install confluent-kafka confluent-kafka[avro] requests dateutils fastavro jsonschema python-dotenv.
        Instructions     :  while asyncApi usage, replace DOMAIN and SUBDOMAIN with your values.
        Kafka Broker     :  %s
        Schema Registry  :  %s
        Topic            :  %s
        Client ID        :  %s
        Serializer Type  :  %s
        AsyncAPI Used    :  %s
        Secure Cluster   :  %s """ %(kafkaBroker,schemaRegistryUrl,topic,clientID,serializer_deserializer_type,asyncapi,secure_cluster))

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

        print ("\nINFO: Creating connection obj for Admin Task")
        connection = admin.AdminClient(kafka_conf)

        print ("\nINFO: Check if Topic %s exists. Else Create it" %topic)
        check_topic_existence(connection, topic)

        producer_conf = kafka_conf

        if ( serializer_deserializer_type == 'avro' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(serializer_deserializer_type, topic))
            schema_str = get_schema(SCHEMA_REGISTRY_URL,topic)
            print ("\nINFO: Set up %s Schema for Topic %s" %(serializer_deserializer_type, topic))
            avro_serializer = serialize_schema(schema_registry_conf, schema_str, serializer_deserializer_type)
        elif ( serializer_deserializer_type == 'json' ):
            print ("\nINFO: Get %s Schema for Topic %s" %(serializer_deserializer_type, topic))
            print(SCHEMA_REGISTRY_URL)
            schema_str = get_schema(SCHEMA_REGISTRY_URL,topic)
            print ("\nINFO: Set up %s Schema for Topic %s" %(serializer_deserializer_type, topic))
            json_serializer = serialize_schema(schema_registry_conf, schema_str, serializer_deserializer_type)
        else:
            print ("\nINFO: No Schema set Required for None Option")

        print ("\nINFO: Create Client obj for Kafka Connection")

        if ( serializer_deserializer_type == 'avro' ):
            producer_conf['key.serializer'] = StringSerializer('utf_8')
            producer_conf['value.serializer'] = avro_serializer
            producer = SerializingProducer(producer_conf)
        elif ( serializer_deserializer_type == 'json' ):
            producer_conf['key.serializer'] = StringSerializer('utf_8')
            producer_conf['value.serializer'] = json_serializer # without this - Exception happened : a bytes-like object is required, not 'User'
            producer = SerializingProducer(producer_conf)
        else:
            producer = Producer(producer_conf)

        produce_messages(producer,int(num_mesg),topic, serializer_deserializer_type)
