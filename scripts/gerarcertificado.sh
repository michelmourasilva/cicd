SUBJECT="/C=ES/ST=PO/L=Vigo/O=Registry/OU=Registry/CN=registry"
PASS="registrysegredo"

mkdir certs
cd certs
openssl genrsa -out registry.key 4096
openssl req -new -key registry.key -subj $SUBJECT -passout pass:$PASS > registry.csr
openssl rsa -in registry.csr -out registry.key -passin pass:$PASS
openssl x509 -in registry.csr -out registry.crt -req -signkey registry.key -days 10000





