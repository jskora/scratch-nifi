#!/bin/bash
#------------------------------------------------------------
# make_test_entity.sh
#------------------------------------------------------------
# Based on step by step found here.
#   https://jamielinux.com/docs/openssl-certificate-authority
#------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/make_test_ca_cfg.sh

#------------------------------------------------------------
# create a server or client
#------------------------------------------------------------

case "$2" in
    server)
        SUBTYPE="server_cert"
        ;;
    client)
        SUBTYPE="usr_cert"
        ;;
    *)
        echo "unknown type $2"
        exit
        ;;
esac
SUBJECT=$3
if [ "$SUBJECT" != "" ]; then

    echo -e "\nCreating ${SUBJECT} key"
    export SUB_PWD=${SUBJECT}
    openssl genrsa -aes256 \
        -out ${INT_DIR}/private/${SUBJECT}.key.pem \
        -passout env:SUB_PWD 2048
    chmod 0400 ${INT_DIR}/private/${SUBJECT}.key.pem
    
    echo -e "\nCreating ${SUBJECT} signing request"
    openssl req -config ${INT_DIR}/openssl.conf \
        -key ${INT_DIR}/private/${SUBJECT}.key.pem \
        -passin env:SUB_PWD \
        -new -sha256 \
        -out ${INT_DIR}/csr/${SUBJECT}.csr.pem \
        -passout env:SUB_PWD \
        -subj "/C=US/CN=${SUBJECT}.${INT_CA}"
    
    echo -e "\nCreating ${SUBJECT} certificate"
    openssl ca -config ${INT_DIR}/openssl.conf \
        -extensions server_cert \
        -days 500 \
        -notext \
        -md sha256 \
        -in ${INT_DIR}/csr/${SUBJECT}.csr.pem \
        -out ${INT_DIR}/certs/${SUBJECT}.cert.pem \
        -passin env:INT_PWD \
        -batch
    chmod 0444 ${INT_DIR}/certs/${SUBJECT}.cert.pem

    echo -e "\nVerifying ${SUBJECT} certificate"
    openssl x509 -noout -text \
        -in ${INT_DIR}/certs/${SUBJECT}.cert.pem

    echo -e "\nCreating ${SUBJECT} certificate chain"
    openssl verify -CAfile ${INT_DIR}/certs/${INT_CA}-chain.cert.pem \
        ${INT_DIR}/certs/${SUBJECT}.cert.pem

    read -p "${SUBJECT} done - press <enter> to continue" DUMP
fi

#------------------------------------------------------------
# done
#------------------------------------------------------------
