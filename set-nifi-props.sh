#!/bin/sh

BOOTSTRAP=conf/bootstrap.conf
PROPERTIES=conf/nifi.properties

# make backups

PREFIX=backup

function backup {
    if [ ! -f $1.orig ]; then
        echo "[$PREFIX] ** backing up $1 to $1.orig"
        cp -p $1 $1.orig
    else 
        echo "[$PREFIX] ** back up $1.orig already exists"
    fi
}
backup $BOOTSTRAP
backup $PROPERTIES

# update nifi.properties

PREFIX=properties

SKEY=$(grep nifi.sensitive.props.key conf/nifi.properties | cut -d"=" -f2)
if [ -z "$SKEY" ]; then
    read -e -p "[$PREFIX] Sensitive properties key ('' for random): " SKEY
    if [ -z "$SKEY" ]; then
        SKEY="SKEY-$RANDOM-$RANDOM-$(date +%s)"
        echo "[$PREFIX] genreated key=$SKEY"
    fi
    sed -i "s/nifi.sensitive.props.key=\$/nifi.sensitive.props.key=$SKEY/" $PROPERTIES
    echo "[$PREFIX] ** sensitive properties key set to '$SKEY'"
else
    echo "[$PREFIX] ** sensitive properties key already set to '$SKEY'"
fi

# update bootstrap.conf

PREFIX=bootstrap

function option_on {
    if [ $(grep -E "^#$1=" $BOOTSTRAP) ]; then
        echo "[$PREFIX] turning on $1"
        sed -i "s/^#$1=/$1=/" $BOOTSTRAP
    else
        echo "[$PREFIX] $1 already on"
    fi
}

function option_off {
    if [ $(grep -E "^$1=" $BOOTSTRAP) ]; then
        echo "[$PREFIX] turning off $1"
        sed -i "s/^$1=/#$1=/" $BOOTSTRAP
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
        sed -i "s#\(^$PRIOR_OPT$\)#\1\n$NEW_OPT#" $BOOTSTRAP
    fi
}

# separate entries by a space for multiple arguments"
ARGS_ON="java.arg.debug java.arg.7 java.arg.8 java.arg.9 java.arg.11 java.arg.12 java.arg.13 java.arg.14"
ARGS_OFF=""
ARGS_ADD="java.arg.15=-Djava.security.egd=file:///dev/./urandom"
ARG_AFTER="java.arg.14"

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
