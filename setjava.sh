#!/bin/bash

#------------------------------------------------------------
# Switch between JDKs for Java 7 and 8.
#------------------------------------------------------------

# Configure these based on local system.
#------------------------------------------------------------
JAVA7BASE=/local/jdk1.7.0_80
JAVA8BASE=/local/jdk1.8.0_60

# Get JDK version parameter
#------------------------------------------------------------
BASH_SOURCE0=${BASH_SOURCE[0]}
ARG0=$0
TGTVER=${1:-X}
if [ "$TGTVER" == "X" ]; then
    echo "Current version"
else
    echo "Target version = $TGTVER"
fi

# Verify script was sourced if changing Java version.
#------------------------------------------------------------
SOURCED=no
if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    SOURCED=yes
fi

# Create path with Java removed and build new paths based on
# the requested Java version.
#------------------------------------------------------------
#NOJAVA_PATH=$(echo $PATH | sed "s#:[^:]*'${JAVA7BASE}[^:]*:#:#g" | sed "s#:[^:]*'${JAVA8BASE}[^:]*:#:#g")
NOJAVA_PATH=$(echo $PATH | sed "s#\(:\|^\)[^:]*/jdk1.[78][^:]*\(:\|\$\)#:#g")
#echo "NOJAVA_PATH=${NOJAVA_PATH}"

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

# Notify user of what was done.
#------------------------------------------------------------
if [ "${TGTVER}" != "X" ]; then
    echo "Java switched to ${JAVA_HOME}"
fi

echo "Java path and Maven options"
echo "---------------------------"
echo "JAVA_HOME=$JAVA_HOME"
echo "PATH=$PATH" | grep -P --color=auto "(:|=)[^:]*/jdk[^:]*(:|$)"
echo "MAVEN_OPTS=${MAVEN_OPTS}" | grep -P --color=auto "(?<==).*$"

if [ "${TGTVER}" != "X" -a "${SOURCED}" == "no" ]; then
    echo "--------------------------------------------------"
    echo "This script must be sourced to work with either"
    echo "    \$ source $(basename $0)"
    echo "or"
    echo "    \$ . $(basename $0)"
    echo "--------------------------------------------------"
    echo "* CHANGES NOT MADE *" | grep --color=tty -E ".*"
    echo "--------------------------------------------------"
fi

#------------------------------------------------------------
# end
#------------------------------------------------------------
