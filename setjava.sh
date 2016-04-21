#!/bin/bash

BASH_SOURCE0=${BASH_SOURCE[0]}
ARG0=$0
SOURCED=no
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    SOURCED=yes
fi

TGTVER=${1:-X}

if [ "${TGTVER}" != "X" -a "${SOURCED}" == "no" ]; then
    echo "--------------------------------------------------"
    echo "This script must be sourced to work with either"
    echo "    \$ source $(basename $0)"
    echo "or"
    echo "    \$ . $(basename $0)"
    echo "--------------------------------------------------"
fi

JAVA7BASE=/local/jdk1.7.0_80
JAVA8BASE=/local/jdk1.8.0_60

#NOJAVA_PATH=$(echo $PATH | sed "s#:[^:]*'${JAVA7BASE}[^:]*:#:#g" | sed "s#:[^:]*'${JAVA8BASE}[^:]*:#:#g")
NOJAVA_PATH=$(echo $PATH | sed "s#\(:\|^\)[^:]*${JAVA7BASE}[^:]*\(:\|\$\)#:#g" | sed "s#\(:\|^\)[^:]*${JAVA8BASE}[^:]*\(:\|\$\)#:#g")
echo "NOJAVA_PATH=${NOJAVA_PATH}"

if [ "${TGTVER}" == "7" ]; then
    export JAVA_HOME=${JAVA7BASE}
    export PATH=$JAVA_HOME/bin:$NOJAVA_PATH
    export MAVEN_OPTS="-Xms1024m -Xmx3076m -XX:MaxPermSize=256m"
fi

if [ "${TGTVER}" == "8" ]; then
    export JAVA_HOME=${JAVA8BASE}
    export PATH=$JAVA_HOME/bin:$NOJAVA_PATH
    export MAVEN_OPTS="-Xms1024m -Xmx3076m"
fi

if [ "${TGTVER}" != "X" ]; then
    echo "Java switched to ${JAVA_HOME}"
fi

echo "Java path and Maven options"
echo "---------------------------"
echo "PATH=$PATH" | grep -P --color=auto "(:|=)[^:]*/jdk[^:]*(:|$)"
echo "MAVEN_OPTS=${MAVEN_OPTS}" | grep -P --color=auto "(?<==).*$"
