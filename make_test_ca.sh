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

export ROOTCA=testca
export INTMCA=testintermediate

export TGTDIR="$( cd "${1:-.}" && pwd )"
read -e -p "Destination folder for test CA: " -i "$TGTDIR" REPLY
export INTDIR=${TGTDIR}/intermediate

echo "Creating destination CA folder $TGTDIR"
mkdir -p $TGTDIR
chmod 700 $TGTDIR
cd $TGTDIR
mkdir certs crl newcerts private
chmod 0700 private
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
dir               = ${TGTDIR}
certs             = $dir/certs
crl_dir           = $dir/crl
new_certs_dir     = $dir/newcerts
database          = $dir/index.txt
serial            = $dir/serial
RANDFILE          = $dir/private/.rand

# The root key and root certificate.
private_key       = $dir/private/${ROOTCA}.key.pem
certificate       = $dir/certs/${ROOTCA}.cert.pem

# For certificate revocation lists.
crlnumber         = $dir/crlnumber
crl               = $dir/crl/${ROOTCA}.crl.pem
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

[ server_cert ]
# Extensions for server certificates ('man x509v3_config').
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

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

echo -e "\nCreating root key"
openssl genrsa -aes256 -out private/${ROOTCA}.key.pem -passout env:ROOTCA 4096
chmod 400 private/${ROOTCA}.key.pem

echo -e "\nCreating root certificate"
openssl req -config openssl.conf -key private/${ROOTCA}.key.pem \
    -new -x509 -days 1000 -sha256 -extensions v3_ca -out certs/${ROOTCA}.cert.pem \
    -passin env:ROOTCA -passout env:ROOTCA \
    -subj "/C=US/CN=testca.root"
chmod 444 certs/${ROOTCA}.cert.pem

echo -e "\nVerifying root certificate"
openssl x509 -noout -text -in certs/${ROOTCA}.cert.pem

#------------------------------------------------------------

echo "Creating destination intermediate folder $INTDIR"
mkdir -p $INTDIR
chmod 700 $INTDIR
cd $INTDIR

mkdir certs crl newcerts private
chmod 0700 private
touch index.txt
echo 1000 > serial
echo 1000 > crlnumber

cp ../openssl.conf openssl.conf
sed -i "s#^dir               = ${TGTDIR}#dir               = ${TGTDIR}/intermediate#"
sed -i "s#^private_key       = $dir/private/${ROOTCA}.key.pem#private_key       = $dir/private/${INTMCA}.key.pem#"
sed -i "s#^certificate       = $dir/certs/${ROOTCA}.cert.pem#certificate       = $dir/certs/${INTMCA}.cert.pem#"
sed -i "s#^crl               = $dir/crl/${ROOTCA}.crl.pem#crl               = $dir/crl/${INTMCA}.crl.pem#"
sed -i "s#^policy            = policy_loose#policy            = policy_strict#"
