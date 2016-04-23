#!/bin/bash
#------------------------------------------------------------
# Install NiFi support files.
#------------------------------------------------------------

safe_copy () {
    SRC=$1
    DST=${HOME}/bin/.$1
    if [ -f ${DST} ]; then
	cp -p ${DST} ${DST}.orig
	echo "backup made ${DST} => ${DST}.orig"
    fi
    cp ${SRC} ${DST}
    echo "installed ${SRC} as new ${DST}"
}

safe_copy setjava.sh
safe_copy set-nifi-props.sh

#--------------------------------------------------

echo "$0 done"

#============================================================
# done
#============================================================
