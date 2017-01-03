#!/bin/bash
#------------------------------------------------------------
# check_certs_status.sh
#------------------------------------------------------------
# Based on step by step found here.
#   https://jamielinux.com/docs/openssl-certificate-authority
#------------------------------------------------------------

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/make_test_ca_cfg.sh

#------------------------------------------------------------
# check server and client certs
#------------------------------------------------------------

for SUBJECT in ${INT_DIR}/certs/*; do
    case $SUBJECT in
        ${INT_DIR}/certs/${INT_CA}-chain.cert.pem)
            ;;
        ${INT_DIR}/certs/${INT_CA}.cert.pem)
            ;;
        ${INT_DIR}/certs/${OCSP_ID}.cert.pem*)
            ;;
        *)
            openssl verify -CAfile ${INT_DIR}/certs/${INT_CA}-chain.cert.pem \
                ${SUBJECT}
            openssl ocsp \
                -CAfile ${INT_DIR}/certs/${INT_CA}-chain.cert.pem \
                -url http://127.0.0.1:8888 \
                -resp_text \
                -issuer ${INT_DIR}/certs/${INT_CA}.cert.pem \
                -cert ${SUBJECT} 2>&1 | grep cert.pem
            echo ""
            ;;
    esac
done

#------------------------------------------------------------
# end
#------------------------------------------------------------
