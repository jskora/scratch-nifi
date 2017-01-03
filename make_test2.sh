#!/bin/bash
#------------------------------------------------------------
# make test 2
#------------------------------------------------------------

ROOT_DIR=$(pwd)

echo -e "\nroot config"

mkdir certs crl newcerts private
chmod 700 private
touch index.txt
echo 1000 > serial

cat <<EOF > openssl.conf
# OpenSSL root CA configuration file.
# Copy to '/root/ca/openssl.cnf'.

[ ca ]
# 'man ca'
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ${ROOT_DIR}
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/testca.key.pem
certificate       = \$dir/certs/testca.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/testca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of 'man ca'.
countryName             = match
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the 'ca' man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the 'req' tool ('man req').
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     =
localityName_default            =
0.organizationName_default      =
#organizationalUnitName_default  =
#emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
authorityInfoAccess = OCSP;URI:http://127.0.0.1:8888

[ server_cert ]
# Extensions for server certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
authorityInfoAccess = OCSP;URI:http://127.0.0.1:8888

[ crl_ext ]
# Extension for CRLs ('man x509v3_config').
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates ('man ocsp').
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = critical, OCSPSigning
EOF

echo -e "\nroot key"
openssl genrsa -aes256 \
    -passout pass:testca \
    -out private/testca.key.pem 4096

chmod 400 private/testca.key.pem

echo -e "\nroot cert"
openssl req -config openssl.conf \
    -key private/testca.key.pem \
    -new -x509 -days 1000 -sha256 -extensions v3_ca \
    -out certs/testca.cert.pem \
    -subj "/C=US/CN=root.testca" \
    -passin pass:testca \
    -passout pass:testca \
    -batch
chmod 0444 certs/testca.cert.pem

echo -e "\nroot verify"
openssl x509 -noout -text -in certs/testca.cert.pem

echo -e "\nintermediate config"

mkdir intermediate
mkdir intermediate/certs intermediate/crl intermediate/csr intermediate/newcerts intermediate/private
chmod 700 intermediate/private
touch intermediate/index.txt
echo 1000 > intermediate/serial

echo 1000 > intermediate/crlnumber

cat <<EOF > intermediate/openssl.conf
# OpenSSL root CA configuration file.
# Copy to '/root/ca/openssl.cnf'.

[ ca ]
# 'man ca'
default_ca = CA_default

[ CA_default ]
# Directory and file locations.
dir               = ${ROOT_DIR}/intermediate
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

# The root key and root certificate.
private_key       = \$dir/private/testca-intermediate.key.pem
certificate       = \$dir/certs/testca-intermediate.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/testca-intermediate.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

# SHA-1 is deprecated, so use SHA-2 instead.
default_md        = sha256

name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_loose

[ policy_strict ]
# The root CA should only sign intermediate certificates that match.
# See the POLICY FORMAT section of 'man ca'.
countryName             = match
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ policy_loose ]
# Allow the intermediate CA to sign a more diverse range of certificates.
# See the POLICY FORMAT section of the 'ca' man page.
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
# Options for the 'req' tool ('man req').
default_bits        = 2048
distinguished_name  = req_distinguished_name
string_mask         = utf8only

# SHA-1 is deprecated, so use SHA-2 instead.
default_md          = sha256

# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca

[ req_distinguished_name ]
# See <https://en.wikipedia.org/wiki/Certificate_signing_request>.
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

# Optionally, specify some defaults.
countryName_default             = US
stateOrProvinceName_default     =
localityName_default            =
0.organizationName_default      =
#organizationalUnitName_default  =
#emailAddress_default            =

[ v3_ca ]
# Extensions for a typical CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
# Extensions for a typical intermediate CA ('man x509v3_config').
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ usr_cert ]
# Extensions for client certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = client, email
nsComment = "OpenSSL Generated Client Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, emailProtection
authorityInfoAccess = OCSP;URI:http://127.0.0.1:8888

[ server_cert ]
# Extensions for server certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
authorityInfoAccess = OCSP;URI:http://127.0.0.1:8888

[ crl_ext ]
# Extension for CRLs ('man x509v3_config').
authorityKeyIdentifier=keyid:always

[ ocsp ]
# Extension for OCSP signing certificates ('man ocsp').
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = critical, OCSPSigning
EOF

echo -e "\nintermediate key"
openssl genrsa -aes256 \
    -passout pass:testca.intermediate \
    -out intermediate/private/testca-intermediate.key.pem 4096
chmod 400 intermediate/private/testca-intermediate.key.pem

echo -e "\nintermediate csr"
openssl req -config intermediate/openssl.conf \
    -new -sha256 \
    -key intermediate/private/testca-intermediate.key.pem \
    -out intermediate/csr/testca-intermediate.csr.pem \
    -passin pass:testca.intermediate \
    -passout pass:testca.intermediate \
    -subj "/C=US/CN=intermediate.testca"

echo -e "\nintermediate cert"
openssl ca -config openssl.conf \
    -extensions v3_intermediate_ca \
    -days 1000 -notext -md sha256 \
    -in intermediate/csr/testca-intermediate.csr.pem \
    -out intermediate/certs/testca-intermediate.cert.pem \
    -passin pass:testca \
    -batch

echo -e "\nintermediate verify"
openssl x509 -noout -text -in intermediate/certs/testca-intermediate.cert.pem
openssl verify -CAfile certs/testca.cert.pem intermediate/certs/testca-intermediate.cert.pem

echo -e "\nintermediate cert chain"
cat intermediate/certs/testca-intermediate.cert.pem \
    certs/testca.cert.pem > intermediate/certs/testca-chain.cert.pem
chmod 444 intermediate/certs/testca-chain.cert.pem

echo -e "\nserver1 key"
openssl genrsa -aes256 \
    -passout pass:server1 \
    -out intermediate/private/server1.key.pem 2048
chmod 400 intermediate/private/server1.key.pem

echo -e "\nserver1 csr"
openssl req -config intermediate/openssl.conf \
    -key intermediate/private/server1.key.pem \
    -new -sha256 \
    -out intermediate/csr/server1.csr.pem \
    -passin pass:server1 \
    -passout pass:server1 \
    -subj "/C=US/CN=server1.intermediate.testca"

echo -e "\nserver1 cert"
openssl ca -config intermediate/openssl.conf \
    -extensions server_cert \
    -days 500 -notext -md sha256 \
    -in intermediate/csr/server1.csr.pem \
    -out intermediate/certs/server1.cert.pem \
    -passin pass:testca.intermediate \
    -batch
chmod 444 intermediate/certs/server1.cert.pem

echo -e "\nserver1 index.txt"
cat intermediate/index.txt

echo -e "\nserver1 verify"
openssl x509 -noout -text -in intermediate/certs/server1.cert.pem
openssl verify -CAfile intermediate/certs/testca-chain.cert.pem \
    intermediate/certs/server1.cert.pem

echo -e "\nserver2 key"
openssl genrsa -aes256 \
    -passout pass:server2 \
    -out intermediate/private/server2.key.pem 2048
chmod 400 intermediate/private/server2.key.pem

echo -e "\nserver2 csr"
openssl req -config intermediate/openssl.conf \
    -key intermediate/private/server2.key.pem \
    -new -sha256 \
    -out intermediate/csr/server2.csr.pem \
    -passin pass:server2 \
    -passout pass:server2 \
    -subj "/C=US/CN=server2.intermediate.testca"

echo -e "\nserver2 cert"
openssl ca -config intermediate/openssl.conf \
    -extensions server_cert \
    -days 500 -notext -md sha256 \
    -in intermediate/csr/server2.csr.pem \
    -out intermediate/certs/server2.cert.pem \
    -passin pass:testca.intermediate \
    -batch
chmod 444 intermediate/certs/server2.cert.pem

echo -e "\nserver2 index.txt"
cat intermediate/index.txt

echo -e "\nserver2 verify"
openssl x509 -noout -text -in intermediate/certs/server2.cert.pem
openssl verify -CAfile intermediate/certs/testca-chain.cert.pem \
    intermediate/certs/server2.cert.pem

echo -e "\nocsp key"
openssl genrsa -aes256 \
    -passout pass:ocsp \
    -out intermediate/private/ocsp.key.pem 4096

echo -e "\nocsp csr"
openssl req -config intermediate/openssl.conf \
    -new -sha256 \
    -key intermediate/private/ocsp.key.pem \
    -out intermediate/csr/ocsp.csr.pem \
    -passin pass:ocsp \
    -passout pass:ocsp \
    -subj "/C=US/CN=ocsp.intermediate.testca"

echo -e "\nocsp cert"
openssl ca -config intermediate/openssl.conf \
    -extensions ocsp -days 500 -notext -md sha256 \
    -in intermediate/csr/ocsp.csr.pem \
    -out intermediate/certs/ocsp.cert.pem \
    -passin pass:testca.intermediate \
    -batch

echo -e "\nocsp verify"
openssl x509 -noout -text \
    -in intermediate/certs/ocsp.cert.pem

echo -e "\ntest certs, revoke cert, test certs"
echo "openssl ocsp -port 127.0.0.1:8888 -text -sha256 \
    -index intermediate/index.txt \
    -CA intermediate/certs/testca-chain.cert.pem \
    -rkey intermediate/private/ocsp.key.pem \
    -rsigner intermediate/certs/ocsp.cert.pem \
    -nrequest 4 >/dev/null 2>/dev/null"

read -p "press enter when ready" x

echo -e "\nbefore revocation"
openssl verify -CAfile intermediate/certs/testca-chain.cert.pem \
    intermediate/certs/server1.cert.pem
openssl verify -CAfile intermediate/certs/testca-chain.cert.pem \
    intermediate/certs/server2.cert.pem
openssl ocsp -CAfile intermediate/certs/testca-chain.cert.pem \
    -url http://127.0.0.1:8888 -resp_text \
    -issuer intermediate/certs/testca-intermediate.cert.pem \
    -cert intermediate/certs/server1.cert.pem
openssl ocsp -CAfile intermediate/certs/testca-chain.cert.pem \
    -url http://127.0.0.1:8888 -resp_text \
    -issuer intermediate/certs/testca-intermediate.cert.pem \
    -cert intermediate/certs/server2.cert.pem

openssl ca -config intermediate/openssl.conf \
    -revoke intermediate/certs/server2.cert.pem \
    -passin pass:testca.intermediate

echo -e "\nafter revocation"
openssl verify -CAfile intermediate/certs/testca-chain.cert.pem \
    intermediate/certs/server1.cert.pem
openssl verify -CAfile intermediate/certs/testca-chain.cert.pem \
    intermediate/certs/server2.cert.pem
openssl ocsp -CAfile intermediate/certs/testca-chain.cert.pem \
    -url http://127.0.0.1:8888 -resp_text \
    -issuer intermediate/certs/testca-intermediate.cert.pem \
    -cert intermediate/certs/server1.cert.pem
openssl ocsp -CAfile intermediate/certs/testca-chain.cert.pem \
    -url http://127.0.0.1:8888 -resp_text \
    -issuer intermediate/certs/testca-intermediate.cert.pem \
    -cert intermediate/certs/server2.cert.pem

