#!/bin/bash

# Set variables
KEY_DIR="./selfSignedCertificates"
PRIVATE_KEY="$KEY_DIR/kafka-lab01.nrsh13-hadoop.com.key"
CERTIFICATE="$KEY_DIR/kafka-lab01.nrsh13-hadoop.com.crt"
ROOT_CA_KEY="$KEY_DIR/root-ca.key"
ROOT_CA_CERT="$KEY_DIR/root-ca.crt"
ROOT_CA_SRL="$KEY_DIR/root-ca.srl"
OPENSSL_CONF="$KEY_DIR/openssl.cnf"

# Create a directory to store the keys and certificates
mkdir -p $KEY_DIR

# Create the OpenSSL config file
cat > $OPENSSL_CONF <<EOL
[req]
prompt                 = no
days                   = 365
distinguished_name     = req_distinguished_name
req_extensions         = v3_req
x509_extensions        = v3_req
prompt                 = no

[ req_distinguished_name ]
countryName            = NZ
stateOrProvinceName    = AKL
localityName           = Auckland
organizationName       = NRSH13
organizationalUnitName = HADOOP
commonName             = "kafka-lab01.nrsh13-hadoop.com"
emailAddress           = nrsh13@gmail.com

[ v3_req ]
basicConstraints       = CA:true
extendedKeyUsage       = serverAuth
subjectAltName         = @sans

[ sans ]
DNS.0 = "kafka-lab01.nrsh13-hadoop.com"
DNS.1 = "*.nrsh13-hadoop.com"
DNS.2 = "ansi-lab01-01.nrsh13-hadoop.com"
DNS.3 = "ansi-lab01-02.nrsh13-hadoop.com"
DNS.4 = "ansi-lab01-03.nrsh13-hadoop.com"
IP.1 = 20.28.189.13
EOL

# Generate the Root CA (Self-Signed Certificate) without passphrase
echo "Generating Root CA key and certificate (no passphrase)..."
openssl genpkey -algorithm RSA -out $ROOT_CA_KEY

# Generate the Root CA certificate from the private key
openssl req -key $ROOT_CA_KEY -new -x509 -out $ROOT_CA_CERT -config $OPENSSL_CONF -extensions v3_req -days 365

# Verify that the root certificate was generated
if [ ! -f "$ROOT_CA_CERT" ] || [ ! -s "$ROOT_CA_CERT" ]; then
  echo "Error: Root CA certificate generation failed. Exiting..."
  exit 1
fi

# Generate the private key and certificate signing request (CSR) for the server certificate
echo "Generating private key and CSR for the server certificate..."
openssl genpkey -algorithm RSA -out $PRIVATE_KEY
openssl req -key $PRIVATE_KEY -new -out "$KEY_DIR/kafka-lab01.nrsh13-hadoop.com.csr" -config $OPENSSL_CONF

# Generate the server certificate signed by the root certificate
echo "Generating server certificate..."
openssl x509 -req -in "$KEY_DIR/kafka-lab01.nrsh13-hadoop.com.csr" -CA $ROOT_CA_CERT -CAkey $ROOT_CA_KEY -CAcreateserial -out $CERTIFICATE -days 365 -sha256 -extfile $OPENSSL_CONF -extensions v3_req

# Output generated files
echo "Generated the following certificates:"
echo "Root CA Certificate: $ROOT_CA_CERT"
echo "Private Key: $PRIVATE_KEY"
echo "Server Certificate: $CERTIFICATE"