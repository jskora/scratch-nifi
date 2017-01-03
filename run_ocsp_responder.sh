#!/bin/bash
#------------------------------------------------------------
# run_ocsp_responder
#------------------------------------------------------------
# Based on step by step found here.
#   https://jamielinux.com/docs/openssl-certificate-authority
#------------------------------------------------------------

export ROOT_CA=test-ca
export INT_CA=test-intermediate

export OCSP_ID=test-ocsp

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
    -index intermediate/index.txt \
    -CA intermediate/certs/ca-chain.cert.pem \
    -rkey intermediate/private/test-ocsp.key.pem \
    -rsigner intermediate/certs/test-ocsp.cert.pem

#------------------------------------------------------------
# end
#------------------------------------------------------------
