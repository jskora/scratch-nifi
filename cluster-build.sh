#!/bin/bash

# cluster specific config (change for each cluster)
#=================================================

# hostnames and DNs must match certificates
CLUSTER_NAME="dev1"
NODE_PREFIX="nifi"
NODE_OU="NIFI" 
NODE_HOST_PTRN="${CLUSTER_NAME}-${NODE_PREFIX}%02d"
NODE_DN_PTRN="CN=${NODE_HOST_PTRN}, OU=NIFI"

NIFI_NODES=5
ZK_NODES=3

NIFI_VER="nifi-1.3.0-SNAPSHOT"

NIFI_HTTPS_PORT="9443"
NIFI_S2S_PORT="10443"
NIFI_CLUSTER_PORT="11443"
NIFI_ZK_PORT="2181"

ZK_PORT_QUORUM="2182"
ZK_PORT_ELECTION="2183"

JDK_VER="jdk1.8.0_121"
JDK_BIN_SRC="java8/jdk-8u121-linux-x64.tar.gz"
JCE_BIN_SRC="java8/jce_policy-8.zip"
JCE_UNZIPPED_PATH="UnlimitedJCEPolicyJDK8"

# insert each disk as a separate index, this will be mounted as "/data${INDEX}"
DISK[1]="/dev/xvdb"
DISK[2]="/dev/xvdc"

# /etc/fstab line, device and mount point will be inserted
FSTAB_PTRN="%s\t%s\tauto\tdefaults,nofail,noatime,comment=nifi\t0\t2"

declare -A PROPS
PROPS[nifi.content.repository.directory]=/data1/content_repository
PROPS[nifi.database.directory]=/data1/database_repository
PROPS[nifi.flowfile.repository.directory]=/data2/flowfile_repository
PROPS[nifi.provenance.repository.directory]=/data2/provenance_repository

# cluster independent script configuration
#=================================================

# S3 paths

CERTS_BIN_SRC="${CLUSTER_NAME}-certs.tar.gz"
NIFI_BIN_SRC="${NIFI_VER}-bin.tar.gz"

S3_BASE="https://s3.amazonaws.com/nifi-server-downloads"
S3_TOOLS="${S3_BASE}/build-tools"
S3_BUILDS="${S3_BASE}/nifi-clusters/${CLUSTER_NAME}-cluster"

# vm meta data

EC2_API_URL="http://169.254.169.254/latest"

INST_IDENT_URL="${EC2_API_URL}/dynamic/instance-identity/document"
INST_IDENT_FILE=/tmp/instance_identity.json

INST_HOST_URL="${EC2_API_URL}/meta-data/local-hostname"
INST_HOST_FILE=/tmp/local-hostname

INST_IDX_URL="${EC2_API_URL}/meta-data/ami-launch-index"
INST_IDX_FILE=/tmp/ami-launch-index

# server properties

APP_ROOT="/opt"
CERTS_TEMP=/tmp/certs
MOTD_FILE=/etc/motd

ROOT_LOG_FILE=/root/install_build_tools.log
FIREWALL_LOG=/root/install_firewall.log

EPEL_REPO_FILE=/etc/yum.repos.d/epel.repo
EPEL_GPG_KEY=/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

# java

JDK_ROOT="${APP_ROOT}/${JDK_VER}"
JCE_ROOT="${APP_ROOT}/${JCE_UNZIPPED_PATH}"

PROFILE_SCRIPT="/etc/profile.d/nifi-java.sh"

# nifi

NIFI_ROOT="${APP_ROOT}/${NIFI_VER}"
NIFI_BIN_ENV="${NIFI_ROOT}/bin/nifi-env.sh"
NIFI_USER=runnifi

NIFI_BOOTSTRAP="${NIFI_ROOT}/conf/bootstrap.conf"
NIFI_PROPS="${NIFI_ROOT}/conf/nifi.properties"
NIFI_AUTHORIZERS="${NIFI_ROOT}/conf/authorizers.xml"
NIFI_STATE_MANAGEMENT="${NIFI_ROOT}/conf/state-management.xml"

# zookeeper

ZK_PROPS="${NIFI_ROOT}/conf/zookeeper.properties"
ZK_MYID="${NIFI_ROOT}/state/zookeeper/myid"

#=================================================
# Nothing below this point should need editing, if it does move it to variable.
#=================================================

export ROOT_LOG_FILE
LOG() {
    echo -e "$1" | tee -a ${ROOT_LOG_FILE}
}
export -f LOG

LOG_HDR() {
    LOG "\n-------------------------------\n$1\n-------------------------------"
}
export -f LOG_HDR

# capture server identity
#=================================================

curl -s -o ${INST_IDENT_FILE} ${INST_IDENT_URL}
curl -s -o ${INST_HOST_FILE} ${INST_HOST_URL}
curl -s -o ${INST_IDX_FILE} ${INST_IDX_URL}

INST_ID=$(grep instanceId ${INST_IDENT_FILE})
INST_IP=$(grep privateIp ${INST_IDENT_FILE} | cut -d":" -f2 | tr -d ' ",')
INST_TYPE=$(grep instanceType ${INST_IDENT_FILE})
INST_IMAGE=$(grep imageId ${INST_IDENT_FILE})

INST_HOST=$(cat ${INST_HOST_FILE})
# index is zero 0 based but files are 1 based
INST_INDEX=$(($(cat ${INST_IDX_FILE}) + 1))

NODE_HOST=$(printf "${NODE_HOST_PTRN}" ${INST_INDEX})

NODE_DN=$(printf "${NODE_DN_PTRN}" ${INST_INDEX})

NIFI_ZK_CONNECT=""
for IDX in $(1 ${ZK_NODES}); do
    NIFI_ZK_CONNECT="${ZK_NODES},$(printf ${NODE_HOST_PTRN}, ${IDX}):${NIFI_ZK_PORT}"
done
NIFI_ZK_CONN=$(echo "${NIFI_ZK_CONN}" | sed "s/^,//")

LOG_HDR "starting ${INST_IP} $(date)"

LOG "   instanceId  =${INST_ID}"
LOG "   privateIp   =${INST_IP}"
LOG "   instanceType=${INST_TYPE}"
LOG "   imageId     =${INST_IMAGE}"
LOG "   index       =${INST_INDEX}"
LOG "   hostname was=${INST_HOST}"
LOG "   hostname is =${NODE_HOST}"
LOG "   nifi zk conn=${NIFI_ZK_CONNECT}"

# add epel repo
#=================================================

LOG_HDR "Adding epel repo"

if [ ! -f ${EPEL_GPG_KEY} ]; then
    cat <<EPELKEY > ${EPEL_GPG_KEY}
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.11 (GNU/Linux)

mQINBFKuaIQBEAC1UphXwMqCAarPUH/ZsOFslabeTVO2pDk5YnO96f+rgZB7xArB
OSeQk7B90iqSJ85/c72OAn4OXYvT63gfCeXpJs5M7emXkPsNQWWSju99lW+AqSNm
jYWhmRlLRGl0OO7gIwj776dIXvcMNFlzSPj00N2xAqjMbjlnV2n2abAE5gq6VpqP
vFXVyfrVa/ualogDVmf6h2t4Rdpifq8qTHsHFU3xpCz+T6/dGWKGQ42ZQfTaLnDM
jToAsmY0AyevkIbX6iZVtzGvanYpPcWW4X0RDPcpqfFNZk643xI4lsZ+Y2Er9Yu5
S/8x0ly+tmmIokaE0wwbdUu740YTZjCesroYWiRg5zuQ2xfKxJoV5E+Eh+tYwGDJ
n6HfWhRgnudRRwvuJ45ztYVtKulKw8QQpd2STWrcQQDJaRWmnMooX/PATTjCBExB
9dkz38Druvk7IkHMtsIqlkAOQMdsX1d3Tov6BE2XDjIG0zFxLduJGbVwc/6rIc95
T055j36Ez0HrjxdpTGOOHxRqMK5m9flFbaxxtDnS7w77WqzW7HjFrD0VeTx2vnjj
GqchHEQpfDpFOzb8LTFhgYidyRNUflQY35WLOzLNV+pV3eQ3Jg11UFwelSNLqfQf
uFRGc+zcwkNjHh5yPvm9odR1BIfqJ6sKGPGbtPNXo7ERMRypWyRz0zi0twARAQAB
tChGZWRvcmEgRVBFTCAoNykgPGVwZWxAZmVkb3JhcHJvamVjdC5vcmc+iQI4BBMB
AgAiBQJSrmiEAhsPBgsJCAcDAgYVCAIJCgsEFgIDAQIeAQIXgAAKCRBqL66iNSxk
5cfGD/4spqpsTjtDM7qpytKLHKruZtvuWiqt5RfvT9ww9GUUFMZ4ZZGX4nUXg49q
ixDLayWR8ddG/s5kyOi3C0uX/6inzaYyRg+Bh70brqKUK14F1BrrPi29eaKfG+Gu
MFtXdBG2a7OtPmw3yuKmq9Epv6B0mP6E5KSdvSRSqJWtGcA6wRS/wDzXJENHp5re
9Ism3CYydpy0GLRA5wo4fPB5uLdUhLEUDvh2KK//fMjja3o0L+SNz8N0aDZyn5Ax
CU9RB3EHcTecFgoy5umRj99BZrebR1NO+4gBrivIfdvD4fJNfNBHXwhSH9ACGCNv
HnXVjHQF9iHWApKkRIeh8Fr2n5dtfJEF7SEX8GbX7FbsWo29kXMrVgNqHNyDnfAB
VoPubgQdtJZJkVZAkaHrMu8AytwT62Q4eNqmJI1aWbZQNI5jWYqc6RKuCK6/F99q
thFT9gJO17+yRuL6Uv2/vgzVR1RGdwVLKwlUjGPAjYflpCQwWMAASxiv9uPyYPHc
ErSrbRG0wjIfAR3vus1OSOx3xZHZpXFfmQTsDP7zVROLzV98R3JwFAxJ4/xqeON4
vCPFU6OsT3lWQ8w7il5ohY95wmujfr6lk89kEzJdOTzcn7DBbUru33CQMGKZ3Evt
RjsC7FDbL017qxS+ZVA/HGkyfiu4cpgV8VUnbql5eAZ+1Ll6Dw==
=hdPa
-----END PGP PUBLIC KEY BLOCK-----
EPELKEY

    rpm --import ${EPEL_GPG_KEY}
    LOG "EPEL GPG key installed"
else
    LOG "EPEL GPG key install skipped, already exists"
fi

if [ ! -f ${EPEL_REPO_FILE} ]; then
    cat <<EPELREPO > ${EPEL_REPO_FILE}
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/\$basearch
mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
EPELREPO
    LOG "EPEL repo installed"
else
    LOG "EPEL repo install skipped, already exists"
fi

# other tools
#=================================================

LOG_HDR "Installing other tools"

yum install -y htop tree curl vim awscli nc

# check in
#=================================================

cat <<MSG | nc 10.113.8.121 10080
starting $(date)
   instanceId=${INST_ID}
   privateIp=${INST_IP}
   instanceType=${INST_TYPE}
   imageId=${INST_IMAGE}
   hostname=${INST_HOST}
   index=${INST_INDEX}
   node=${NODE_HOST}
MSG

# Java
#=================================================

LOG_HDR "Downloading and expanding Java binaries"

# JVM
if [ -d ${JDK_ROOT} ]; then
    LOG "*** JDK install skipped, already exists ***"
else
    pushd /opt

    LOG "downloading ${JDK_BIN_SRC}"
    JDK_BIN_SRC_URL="${S3_TOOLS}/${JDK_BIN_SRC}"
    curl -s ${JDK_BIN_SRC_URL} | tar -xz

    LOG "downloading ${JCE_BIN_SRC}"
    JCE_BIN_SRC_URL="${S3_TOOLS}/${JCE_BIN_SRC}"
    curl -s ${JCE_BIN_SRC_URL} | ${JDK_ROOT}/bin/jar x
    mv -f ${JCE_ROOT}/*.jar ${JDK_ROOT}/jre/lib/security/
    
    test -d ${JCE_ROOT} && rm -f ${JCE_ROOT}/*
    test -d ${JCE_ROOT} && rmdir ${JCE_ROOT}
    
    LOG "Creating profile and MOTD" 
    cat <<PROFILE >${PROFILE_SCRIPT}
export JAVA_HOME=${JDK_ROOT}
export PATH=\${JAVA_HOME}/bin:\${M2_HOME}/bin:${PATH}
PROFILE
    chmod go-w ${PROFILE_SCRIPT}
    MSG="Path has been configured for Java 8"
    grep -q "${MSG}" ${MOTD_FILE} || echo "${MSG}" >> ${MOTD_FILE}

    LOG "JDK installed"
    popd
fi

# firewall
#=================================================

LOG_HDR "opening firewall ports"

open_port() {
    LOG "checking port $1"
    setenforce 0
    firewall-cmd --list-all 2>&1 | tee -a ${FIREWALL_LOG}.${1}
    PORT_STATUS=$(firewall-cmd --zone=public --query-port=$1/tcp)
    setenforce 1
    if [ "${PORT_STATUS}" == "no" ]; then
        setenforce 0
        firewall-cmd --zone=public --add-port=$1/tcp --permanent 2>&1 | tee -a ${FIREWALL_LOG}.${1}
        firewall-cmd --reload 2>&1 | tee -a ${FIREWALL_LOG}.${1}
        setenforce 1
        LOG "firewall port $1 opened"
    else
        LOG "firewall port $1 not opened, already open"
    fi
}

open_port ${NIFI_HTTPS_PORT}
open_port ${NIFI_S2S_PORT}
open_port ${NIFI_CLUSTER_PORT}
open_port ${NIFI_ZK_PORT}
open_port ${ZK_PORT_QUORUM}
open_port ${ZK_PORT_ELECTION}

# nifi
#=================================================

LOG_HDR "downloading and configuring NiFi"

set_prop() {
    LOG "setting ${1} ${2}=${3}"
    if grep -q "^${2}=" ${1} ; then
        sed -ir "s/^\(${2}\)=.*$/\1=${3}\n/" ${1}
        LOG "updated"
    else
        echo "${2}=${3}" >> ${1}
        LOG "added"
    fi
}

set_xml() {
    LOG "setting ${1} ${2}=${3}"
    sed -ir "s@\(<property name=\"${2}\">\).*\(</property>\)@\1${3}\2@" ${1}
}

if [ ! -d ${NIFI_ROOT} ]; then

    LOG "   download and uncompress nifi"

    NIFI_BIN_SRC_URL="${S3_BUILDS}/${NIFI_BIN_SRC}"
    mkdir -p ${NIFI_ROOT}
    pushd ${NIFI_ROOT}
    LOG "${NIFI_BIN_SRC_URL}"
    curl -s ${NIFI_BIN_SRC_URL} | tar --strip-components=1 -xz
    popd
    LOG "$(ls -l ${NIFI_ROOT})"

    LOG "   download certs and copy keys and property files into place"

    CERTS_BIN_SRC_URL="${S3_BUILDS}/${CERTS_BIN_SRC}"
    rm -rf ${CERTS_TEMP}
    mkdir ${CERTS_TEMP}
    pushd ${CERTS_TEMP}
    curl -s ${CERTS_BIN_SRC_URL} | tar -xz
    popd
    mv ${NIFI_ROOT}/conf/nifi.properties ${NIFI_ROOT}/conf/nifi.properties.orig
    cp -p ${CERTS_TEMP}/$(printf ${NODE_HOST_PTRN} ${INST_INDEX})/* ${NIFI_ROOT}/conf/
    LOG "$(ls -l ${NIFI_ROOT}/conf)"

    if [[ "${NIFI_VERSION}" = *"1.3.0"* ]]; then
        # temp fix
        set_prop "${NIFI_PROPS}" nifi.security.user.authorizer file-provider
    fi

    LOG "   bootstrap.conf"

    set_prop "${NIFI_BOOTSTRAP}" "java.args.3" "-Xmx16384m"
    set_prop "${NIFI_BOOTSTRAP}" "run.as" "${NIFI_USER}"
    
    LOG "   nifi.properties"

    LOG "      banner"
    set_prop "${NIFI_PROPS}" "nifi.ui.banner.text" "${CLUSTER_NAME}"

    LOG "      client auth"
    set_prop "${NIFI_PROPS}" "nifi.security.needClientAuth" "true"

    LOG "      cluster"
    set_prop "${NIFI_PROPS}" "nifi.cluster.is.node" "true"

    LOG "      embedded zookeeper (for first ZK_NODES nodes)"
    if [ ${INST_INDEX} -le ${ZK_NODES} ]; then
        set_prop "${NIFI_PROPS}" "nifi.state.management.embedded.zookeeper.start" "true"
        mkdir -p ${NIFI_ROOT}/state/zookeeper
        echo ${INST_INDEX} > ${ZK_MYID}
    fi

    LOG "      other properties"
    for KEY in ${!PROPS[@]}; do
        VALUE=${PROPS[KEY]}
        LOG "         ${KEY}=${VALUE}"
        set_prop "${NIFI_PROPS}" "${KEY}" "${VALUE}"
    done

    LOG "   zookeeper.properties"

    for IDX in $(seq 1 ${ZK_NODES}); do
        NODE_NAME="$(printf "${NODE_HOST_PTRN}" ${IDX})"
        set_prop "${ZK_PROPS}" server.${IDX} ${NODE_NAME}:${ZK_PORT_QUORUM}:${ZK_PORT_ELECTION}
    done

    set_xml "${NIFI_AUTHORIZERS}" "Initial Admin Identity" "CN=testuser1, OU=nifidev"
    grep "Initial Admin Identity" ${NIFI_AUTHORIZERS}

    PROP_PTRN="<property name=\"Node Identity %d\">CN=%s, OU=NIFI</property>"
    SVRS=""
    CONNECT=""
    for IDX in $(seq 1 ${NIFI_NODES}); do
        NODE_NAME="$(printf "${NODE_HOST_PTRN}" ${IDX})"
        SVRS="${SVRS}$(printf "${PROP_PTRN}" "${IDX}" "${NODE_NAME}")\n"
        if [ $((${IDX})) -le $((${ZK_NODES})) ]; then
            CONNECT="${CONNECT},${NODE_NAME}:${NIFI_ZK_PORT}"
        fi
    done
    sed -ir "s@    </authorizer>@${SVRS}    </authorizer>@" ${NIFI_AUTHORIZERS}
    CONNECT=$(echo "${CONNECT}" | sed "s/^,//")
    set_prop "${NIFI_PROPS}" nifi.zookeeper.connect.string "${CONNECT}"

    LOG "   state-management.xml"
    set_xml "${NIFI_STATE_MANAGEMENT}" "Connect String" "${CONNECT}"

    LOG "      ${NIFI_BIN_ENV} - force JDK"
    sed -ir "s@#export JAVA_HOME=.*@export JAVA_HOME=${JDK_ROOT}@" ${NIFI_BIN_ENV}

    LOG "NIFI downloaded and configured"
else
    LOG "NIFI download and configure skipped, already exists"
fi

# disk configuration
#=================================================

LOG_HDR "Final system configuration"

LOG "   /etc/hosts"
for IDX in $(seq 1 ${NIFI_NODES}); do
    NODE_NAME="$(printf "${NODE_HOST_PTRN}" ${IDX})"
    LOG "      NODE_NAME=${NODE_NAME}"
    if ! grep -q ${NODE_NAME} /etc/hosts ; then
        if [ "${IDX}" == "${INST_INDEX}" ]; then
            echo -e "${INST_IP}\t${NODE_NAME}" >> /etc/hosts
        else
            echo -e "0.0.0.0\t${NODE_NAME}" >> /etc/hosts
        fi
    else
	LOG "      /etc/hosts entry found, skipping"
    fi
done

LOG "   configuring data volume(s)"
for IDX in ${!DISK[@]}; do
    DISK=${DISK[IDX]}
    DISK_DIR="/data${IDX}"
    DISK_FILE=$(file -sbL ${DISK})
    LOG "      ${DISK}  ${DISK_DIR}  ${DISK_FILE}"
    if [ "${DISK_FILE}" = "data" ]; then
        mkfs.ext4 ${DISK}
        mkdir ${DISK_DIR}
        chown -R ${NIFI_USER}: ${DISK_DIR}
        chmod -R u+rwx,g+rws,o- ${DISK_DIR}

        sed -ir "s@^${DISK}@#${DISK}@" /etc/fstab
        printf "${FSTAB_PTRN}" "${DISK}" "${DISK_DIR}" >> /etc/fstab
	    mount ${DISK}
    fi
done

# nifi user and service
#=================================================

LOG "adding nifi user and service"

LOG "   adding user '${NIFI_USER}'"
useradd -M ${NIFI_USER}

LOG "   setting ownership of JDK '${JDK_ROOT}'"
chown -R root: ${JDK_ROOT}
chmod -R 755 ${JDK_ROOT}

LOG "   setting ownership of NiFi '${NIFI_ROOT}'"
chown -R ${NIFI_USER}: ${NIFI_ROOT}
chmod -R u+rwx,g+rws,o- ${NIFI_ROOT}

LOG "   adding nifi service"
pushd ${NIFI_ROOT}
bin/nifi.sh install
systemctl disable nifi
popd

# wrap it up
#=================================================

LOG "wrapping up"
MSG=$(cat <<NOTES
NOTE: after the system starts up, the following tasks need to be done.
  1 - add appropriate users to 'runnifi' group.
          \$ sudo usermod -a -G runnifi <userid>
  2 - populate all nodes' /etc/hosts with IPs of all the hosts
        - accumulate all /root/hosts-* files and append all node IPs to each node's /etc/hosts file.
              \$ for IP in IP1 [IP2 ...]; do
                scp -p \$IP:/tmp/host-entry-* /tmp
              done
              \$ for ENTRY_FILE in /tmp/host-entry-*; do
                NODE_ENTRY=\$(cat \${ENTRY_FILE})
                if ! grep -q \${NODE_ENTRY} /etc/hosts ; then
                  cat \${ENTRY_FILE} >> /etc/hosts
                fi
              done
NOTES)
LOG "$MSG"

#=================================================

LOG_HDR "done ${INST_IP} $(date)"

#=====
# end
#=====
