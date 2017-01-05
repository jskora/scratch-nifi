#!/bin/bash
#------------------------------------------------------------
# revoke_test_entity.sh
#------------------------------------------------------------
# Based on step by step found here.
#   https://jamielinux.com/docs/openssl-certificate-authority
#------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/make_test_ca_cfg.sh

#------------------------------------------------------------
# revoke a server or client
#------------------------------------------------------------

SUBJECT=$2
if [ "$SUBJECT" != "" ]; then
    echo -e "\nRevoking ${SUBJECT} key"
    openssl ca \
        -config ${INT_DIR}/openssl.conf \
        -revoke ${INT_DIR}/certs/${SUBJECT}.cert.pem \
        -passin pass:${INT_PWD}
fi

#------------------------------------------------------------
# done
#------------------------------------------------------------
