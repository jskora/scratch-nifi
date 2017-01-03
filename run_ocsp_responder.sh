#!/bin/bash
#------------------------------------------------------------
# run_ocsp_responder
#------------------------------------------------------------
# Based on step by step found here.
#   https://jamielinux.com/docs/openssl-certificate-authority
#------------------------------------------------------------

export ROOT_CA=test-ca
export INT_CA=intermediate.${ROOT_CA}

export OCSP_ID=ocsp.${INT_CA}

export ROOT_PWD=testca
export INT_PWD=testintermediate
export OCSP_PWD=testocsp

export ROOT_DIR="$( cd "${1:-.}" && pwd )"
export INT_DIR=${ROOT_DIR}/intermediate

#------------------------------------------------------------
# start ocsp responder
#------------------------------------------------------------

openssl ocsp -port 127.0.0.1:8888 \
    -text \
    -sha256 \
    -index ${INT_DIR}/index.txt \
    -CA ${INT_DIR}/certs/${INT_CA}-chain.cert.pem \
    -rkey ${INT_DIR}/private/${OCSP_ID}.key.pem \
    -rsigner ${INT_DIR}/certs/${OCSP_ID}.cert.pem

#------------------------------------------------------------
# end
#------------------------------------------------------------
