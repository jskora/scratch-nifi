#!/bin/bash
#------------------------------------------------------------
# make_test_ca_cfg.sh
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
# done
#------------------------------------------------------------
