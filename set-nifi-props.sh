#!/bin/sh

#--------------------------------------------------------------------------------
# Configure Apache NiFi conf/bootstrap.conf and conf/nifi.properties files.
#--------------------------------------------------------------------------------
# defaults
#------------------------------------------------------------

BOOTSTRAP=conf/bootstrap.conf
PROPERTIES=conf/nifi.properties
DEFAULT_JAVA_VER=7

# configure based on host OS (assumes Linux)
#------------------------------------------------------------

JAVA_VER=${1:-${DEFAULT_JAVA_VER}}

OS=$(uname)
if [ "$OS" == "" ]; then
    OS=UNKNOWN
fi

# This uses .sbak extension for interim backups which are removed at completion.
#
# (The standard sed backup that made with "-i '.sbak'" option will not work for source
# backup because sed is called multiple times on a file.  Also, OSX requires a parameter
# to the "-i" option but behaves unexpectedly in shell expansions if given a blank
# parameter ("-i ''") to suppresses backups,)
SED="sed -i.sbak"

# make backups
#------------------------------------------------------------

PREFIX=backup

function backup {
    if [ ! -f $1.orig ]; then
        echo "[$PREFIX] ** backing up $1 to $1.orig"
        echo "------------------------------------------------------------"
        cp -p $1 $1.orig
    else 
        echo "[$PREFIX] ** back up $1.orig already exists"
        echo "------------------------------------------------------------"
    fi
}

backup $BOOTSTRAP
backup $PROPERTIES

# update nifi.properties
#------------------------------------------------------------

PREFIX=properties

SKEY=$(grep nifi.sensitive.props.key conf/nifi.properties | cut -d"=" -f2)
if [ -z "$SKEY" ]; then
    read -e -p "[$PREFIX] Sensitive properties key ('' for random): " SKEY
    if [ -z "$SKEY" ]; then
        SKEY="SKEY-$RANDOM-$RANDOM-$(date +%s)"
        echo "[$PREFIX] genreated key=$SKEY"
    fi
    echo "[$PREFIX] ** setting sensitive properties key to '$SKEY'"
    echo "------------------------------------------------------------"

    ${SED} "s/nifi.sensitive.props.key=\$/nifi.sensitive.props.key=$SKEY/" $PROPERTIES
else
    echo "[$PREFIX] ** sensitive properties key already set to '$SKEY'"
fi

# update bootstrap.conf
#------------------------------------------------------------

PREFIX=bootstrap

function option_on {
    if [ $(grep -E "^#$1=" $BOOTSTRAP) ]; then
        echo "[$PREFIX] turning on $1"
        ${SED} "s/^#$1=/$1=/" $BOOTSTRAP
    else
        echo "[$PREFIX] $1 already on"
    fi
}

function option_off {
    if [ $(grep -E "^$1=" $BOOTSTRAP) ]; then
        echo "[$PREFIX] turning off $1"
        ${SED} "s/^$1=/#$1=/" $BOOTSTRAP
    else
        echo "[$PREFIX] $1 already off"
    fi
}

function add_option {
    PRIOR_OPT=$1
    NEW_OPT=$2
    if [ $(grep -E "^#?$NEW_OPT" $BOOTSTRAP) ]; then
        echo "[$PREFIX] $NEW_OPT already exists"
    else
        echo "[$PREFIX] adding $NEW_OPT after $PRIOROPT"
        if [ "$OS" == "Darwin" ]; then
            # Ugly OSX variant, but it works,
            # (based on http://www.culmination.org/2008/02/sed-on-mac-os-x-105-leopard/)
            # It boils down to changing what on Linux was
            #     ...\n...
            # to on OSX be
            #     ...\\"$'\n'"...
            # which appears to be creating
            #     \\    - an escape character
            #     "     - exit the quoted string
            #     $'\n' - a literal \n character
            #     "     - re-enter the quoted string
            # Thus inserting a literal newline like on Linux but more awkwardly.
            ${SED} "s#\(^$PRIOR_OPT$\)#\1\\"$'\n'"$NEW_OPT#" $BOOTSTRAP
        else
            ${SED} "s#\(^$PRIOR_OPT$\)#\1\n$NEW_OPT#" $BOOTSTRAP
        fi
    fi
}

# Separate entries by a space for multiple arguments.
# ARG_AFTER is a marker for additions, it can be commented out and still work.

if [ "${JAVA_VER}" == "7" ]; then
    ARGS_ON="java.arg.debug java.arg.7 java.arg.8 java.arg.9 java.arg.11 java.arg.12 java.arg.13 java.arg.14"
    ARGS_OFF=""
    ARGS_ADD="java.arg.15=-Djava.security.egd=file:///dev/./urandom"
    ARG_AFTER="java.arg.14"
else
    ARGS_ON="java.arg.debug java.arg.14"
    ARGS_OFF=""
    ARGS_ADD="java.arg.15=-Djava.security.egd=file:///dev/./urandom"
    ARG_AFTER="java.arg.14"
fi

for ON_ARG in $ARGS_ON; do
    option_on $ON_ARG
done

for OFF_ARG in $ARGS_OFF; do
    option_off $OFF_ARG
done

AFTER=$(grep -E "^#?$ARG_AFTER" $BOOTSTRAP)
for NEW_ARG in $ARGS_ADD; do
    add_option $AFTER $NEW_ARG
    AFTER=$(grep -E "^#?$NEW_ARG" $BOOTSTRAP)
done

# cleanup
#------------------------------------------------------------

rm conf/*.sbak

#------------------------------------------------------------
# end
#------------------------------------------------------------
