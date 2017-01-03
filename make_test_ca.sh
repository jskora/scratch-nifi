#!/bin/bash
#------------------------------------------------------------
# make_test_ca.sh
#------------------------------------------------------------
# Based on step by step found here.
#   https://jamielinux.com/docs/openssl-certificate-authority
#
# [ OCSP ] section adjustments found here
#   http://isrlabs.net/wordpress/?p=169
# include adding
#   authorityInfoAccess = OCSP;URI:http://127.0.0.1:8888
# and appending keyEncipherment to the keyUsage entry.
#   keyUsage = nonRepudiation, digitalSignature, keyEncipherment
# 
# Also adjusted root and intermediate policy_strict to make
# stateOrProvinceName and organizationName fields optional.
#------------------------------------------------------------

export ROOT_CA=test-ca
export INT_CA=intermediate.${ROOT_CA}

export OCSP_ID=ocsp.${INT_CA}

export ROOT_PWD=testca
export INT_PWD=testintermediate
export OCSP_PWD=testocsp

export ROOT_DIR="$( cd "${1:-.}" && pwd )"
read -p "destination folder is ${ROOT_DIR}, press <enter> to proceed" DUMP
export INT_DIR=${ROOT_DIR}/intermediate

#------------------------------------------------------------
# setup folders
#------------------------------------------------------------

echo -e "\nCreating CA folder ${ROOT_DIR}"

mkdir -p ${ROOT_DIR}
chmod 700 ${ROOT_DIR}

cd ${ROOT_DIR}
mkdir certs crl newcerts private
chmod 0700 private
touch index.txt
echo 1000 > serial

echo -e "\nCreating intermediate folder ${INT_DIR}"

mkdir -p ${INT_DIR}
chmod 700 ${INT_DIR}

mkdir ${INT_DIR}/certs ${INT_DIR}/crl ${INT_DIR}/csr ${INT_DIR}/newcerts ${INT_DIR}/private
chmod 0700 ${INT_DIR}/private
touch ${INT_DIR}/index.txt
echo 1000 > ${INT_DIR}/serial
echo 1000 > ${INT_DIR}/crlnumber

read -p "folder setup done - press <enter> to continue" DUMP

#------------------------------------------------------------
# create configuration files
#------------------------------------------------------------

echo -e "\nCreating ${ROOT_DIR}/openssl.conf"

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
private_key       = \$dir/private/${ROOT_CA}.key.pem
certificate       = \$dir/certs/${ROOT_CA}.cert.pem

# For certificate revocation lists.
crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/${ROOT_CA}.crl.pem
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

echo -e "\nCreating ${INT_DIR}/openssl.conf"

cp ${ROOT_DIR}/openssl.conf ${INT_DIR}/openssl.conf
#sed -i "s#^dir               = ${ROOT_DIR}#dir               = ${INT_DIR}#" ${INT_DIR}/openssl.conf
#sed -i "s#^private_key       = ${ROOT_DIR}/private/${ROOT_CA}.key.pem#private_key       = ${INT_DIR}/private/${INT_CA}.key.pem#" ${INT_DIR}/openssl.conf
#sed -i "s#^certificate       = ${ROOT_DIR}/certs/${ROOT_CA}.cert.pem#certificate       = ${INT_DIR}/certs/${INT_CA}.cert.pem#" ${INT_DIR}/openssl.conf
#sed -i "s#^crl               = ${ROOT_DIR}/crl/${ROOT_CA}.crl.pem#crl               = ${INT_DIR}/crl/${INT_CA}.crl.pem#" ${INT_DIR}/openssl.conf
#sed -i "s#^policy            = policy_strict#policy            = policy_loose#" ${INT_DIR}/openssl.conf
if [ "$(uname -s)" == "Linux" ]; then
    BKP_EXT=
else
    BKP_EXT='""'
fi
sed -i ${BKP_EXT} "s#${ROOT_DIR}#${INT_DIR}#g" ${INT_DIR}/openssl.conf
sed -i ${BKP_EXT} "s#${ROOT_CA}#${INT_CA}#g" ${INT_DIR}/openssl.conf
sed -i ${BKP_EXT} "s#= policy_strict#= policy_loose#" ${INT_DIR}/openssl.conf

read -p "config files done - press <enter> to continue" DUMP

#------------------------------------------------------------
# create root ca
#------------------------------------------------------------

echo -e "\nCreating root key"
openssl genrsa -aes256 \
    -out private/${ROOT_CA}.key.pem \
    -passout env:ROOT_PWD 4096
chmod 400 private/${ROOT_CA}.key.pem

echo -e "\nCreating root certificate"
openssl req -config openssl.conf \
    -key private/${ROOT_CA}.key.pem \
    -new -x509 -days 1000 -sha256 \
    -extensions v3_ca \
    -out certs/${ROOT_CA}.cert.pem \
    -passin env:ROOT_PWD \
    -passout env:ROOT_PWD \
    -subj "/C=US/CN=${ROOT_CA}"
chmod 444 certs/${ROOT_CA}.cert.pem

echo -e "\nVerifying root certificate"
openssl x509 -noout -text -in certs/${ROOT_CA}.cert.pem

read -p "root certificate done - press <enter> to continue" DUMP

#------------------------------------------------------------
# create intermediate ca
#------------------------------------------------------------

echo -e "\nCreating intermediate key"
openssl genrsa -aes256 \
    -out ${INT_DIR}/private/${INT_CA}.key.pem \
    -passout env:INT_PWD 4096
chmod 0400 ${INT_DIR}/private/${INT_CA}.key.pem

echo -e "\nCreating intermediate signing request"
openssl req -config ${INT_DIR}/openssl.conf \
    -new \
    -sha256 \
    -key ${INT_DIR}/private/${INT_CA}.key.pem \
    -out ${INT_DIR}/csr/${INT_CA}.csr.pem \
    -passin env:INT_PWD \
    -passout env:INT_PWD \
    -subj "/C=US/CN=${INT_CA}"

echo -e "\nCreating intermediate certificate"
openssl ca -config openssl.conf \
    -extensions v3_intermediate_ca \
    -days 1000 \
    -notext \
    -md sha256 \
    -in ${INT_DIR}/csr/${INT_CA}.csr.pem \
    -out ${INT_DIR}/certs/${INT_CA}.cert.pem \
    -passin env:ROOT_PWD \
    -batch
chmod 0444 ${INT_DIR}/certs/${INT_CA}.cert.pem

echo -e "\nVerifying intermediate certificate"
openssl x509 -noout -text \
    -in ${INT_DIR}/certs/${INT_CA}.cert.pem
openssl verify -CAfile certs/${ROOT_CA}.cert.pem \
    ${INT_DIR}/certs/${INT_CA}.cert.pem

echo -e "\nCreating intermediate certificate chain"
cat ${INT_DIR}/certs/${INT_CA}.cert.pem \
    certs/${ROOT_CA}.cert.pem > ${INT_DIR}/certs/${INT_CA}-chain.cert.pem
chmod 0400 ${INT_DIR}/certs/${INT_CA}-chain.cert.pem

read -p "intermediate cert done - press <enter> to continue" DUMP

#------------------------------------------------------------
# create servers and clients
#------------------------------------------------------------

for SERVER in server1 server2 server3; do

    echo -e "\nCreating ${SERVER} key"
    export SUB_PWD=${SERVER}
    openssl genrsa -aes256 \
        -out ${INT_DIR}/private/${SERVER}.key.pem \
        -passout env:SUB_PWD 2048
    chmod 0400 ${INT_DIR}/private/${SERVER}.key.pem
    
    echo -e "\nCreating ${SERVER} signing request"
    openssl req -config ${INT_DIR}/openssl.conf \
        -key ${INT_DIR}/private/${SERVER}.key.pem \
        -passin env:SUB_PWD \
        -new -sha256 \
        -out ${INT_DIR}/csr/${SERVER}.csr.pem \
        -passout env:SUB_PWD \
        -subj "/C=US/CN=${SERVER}.${INT_CA}"
    
    echo -e "\nCreating ${SERVER} certificate"
    openssl ca -config ${INT_DIR}/openssl.conf \
        -extensions server_cert \
        -days 500 \
        -notext \
        -md sha256 \
        -in ${INT_DIR}/csr/${SERVER}.csr.pem \
        -out ${INT_DIR}/certs/${SERVER}.cert.pem \
        -passin env:INT_PWD \
        -batch
    chmod 0444 ${INT_DIR}/certs/${SERVER}.cert.pem

    echo -e "\nVerifying ${SERVER} certificate"
    openssl x509 -noout -text \
        -in ${INT_DIR}/certs/${SERVER}.cert.pem

    echo -e "\nCreating ${SERVER} certificate chain"
    openssl verify -CAfile ${INT_DIR}/certs/${INT_CA}-chain.cert.pem \
        ${INT_DIR}/certs/${SERVER}.cert.pem

    read -p "${SERVER} done - press <enter> to continue" DUMP
done

for CLIENT in client1 client2 client3; do

    echo -e "\nCreating ${CLIENT} key"
    export SUB_PWD=${CLIENT}
    openssl genrsa -aes256 \
        -out ${INT_DIR}/private/${CLIENT}.key.pem \
        -passout env:SUB_PWD 2048
    chmod 0400 ${INT_DIR}/private/${CLIENT}.key.pem

    echo -e "\nCreating ${CLIENT} signing request"
    openssl req -config ${INT_DIR}/openssl.conf \
        -key ${INT_DIR}/private/${CLIENT}.key.pem \
        -passin env:SUB_PWD \
        -new -sha256 \
        -out ${INT_DIR}/csr/${CLIENT}.csr.pem \
        -passout env:SUB_PWD \
        -subj "/C=US/CN=${CLIENT}.${INT_CA}"

    echo -e "\nCreating ${CLIENT} certificate"
    openssl ca -config ${INT_DIR}/openssl.conf \
        -extensions usr_cert \
        -days 500 \
        -notext \
        -md sha256 \
        -in ${INT_DIR}/csr/${CLIENT}.csr.pem \
        -out ${INT_DIR}/certs/${CLIENT}.cert.pem \
        -passin env:INT_PWD \
        -batch
    chmod 0444 ${INT_DIR}/certs/${CLIENT}.cert.pem

    echo -e "\nVerifying ${CLIENT} certificate"
    openssl x509 -noout -text \
        -in ${INT_DIR}/certs/${CLIENT}.cert.pem

    echo -e "\nCreating ${CLIENT} certificate chain"
    openssl verify -CAfile ${INT_DIR}/certs/${INT_CA}-chain.cert.pem \
        ${INT_DIR}/certs/${CLIENT}.cert.pem

    read -p "${CLIENT} done - press <enter> to continue" DUMP
done

#------------------------------------------------------------
# create ocsp pair
#------------------------------------------------------------

echo -e "\nCreating ocsp key"
openssl genrsa -aes256 \
    -out ${INT_DIR}/private/${OCSP_ID}.key.pem \
    -passout env:OCSP_PWD 4096
chmod 0400 ${INT_DIR}/private/${OCSP_ID}.key.pem

echo -e "\nCreating ocsp signing request"
openssl req -config ${INT_DIR}/openssl.conf \
    -new -sha256 \
    -key ${INT_DIR}/private/${OCSP_ID}.key.pem \
    -out ${INT_DIR}/csr/${OCSP_ID}.csr.pem \
    -passin env:OCSP_PWD \
    -subj "/C=US/CN=ocsp.intermediate.testca"

echo -e "\nCreating ocsp certificate"
openssl ca -config ${INT_DIR}/openssl.conf \
    -extensions ocsp \
    -days 1000 \
    -notext \
    -md sha256 \
    -in ${INT_DIR}/csr/${OCSP_ID}.csr.pem \
    -out ${INT_DIR}/certs/${OCSP_ID}.cert.pem \
    -batch \
    -passin env:INT_PWD
chmod 0444 ${INT_DIR}/certs/${OCSP_ID}.cert.pem

echo -e "\nVerifying ocsp certificate"
openssl x509 -noout -text -in ${INT_DIR}/certs/${OCSP_ID}.cert.pem

#------------------------------------------------------------
# done
#------------------------------------------------------------
