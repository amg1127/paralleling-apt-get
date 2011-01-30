#!/bin/bash

completedir="/var/cache/apt/archives"

novokernel () {
    # 2.6.22-15-generic
    vm1="`uname -r | awk -F '.' '{ print $1; }'`"
    vm2="`uname -r | awk -F '.' '{ print $2; }'`"
    vm3="`uname -r | awk -F '.' '{ print $3; }' | awk -F '-' '{ print $1; }'`"
    vm4="`uname -r | awk -F '-' '{ print $2; }'`"
    tipo="`uname -r | sed \"s/$vm1.$vm2.$vm3-$vm4-//\"`"
    apt-cache --names-only search "^linux-image-[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*-[[:digit:]]*-$tipo\$" | awk '{ print $1; }' | cut -b 13- | while read pacote; do
        v1="`echo $pacote | awk -F '.' '{ print $1; }'`"
        v2="`echo $pacote | awk -F '.' '{ print $2; }'`"
        v3="`echo $pacote | awk -F '.' '{ print $3; }' | awk -F '-' '{ print $1; }'`"
        v4="`echo $pacote | awk -F '-' '{ print $2; }'`"
        if [ "`echo $pacote | sed \"s/$v1.$v2.$v3-$v4-//\"`" == "$tipo" ]; then
            if [ $v1 -gt $vm1 ] || \
               ( [ $v1 -eq $vm1 ] && [ $v2 -gt $vm2 ] ) || \
               ( [ $v1 -eq $vm1 ] && [ $v2 -eq $vm2 ] && [ $v3 -gt $vm3 ] ) || \
               ( [ $v1 -eq $vm1 ] && [ $v2 -eq $vm2 ] && [ $v3 -eq $vm3 ] && [ "$v4" -gt "$vm4" ] ); then
                   vm1="$v1"
                   vm2="$v2"
                   vm3="$v3"
                   vm4="$v4"
            fi
        fi
        echo linux-image-$vm1.$vm2.$vm3-$vm4-$tipo linux-headers-$vm1.$vm2.$vm3-$vm4-$tipo linux-headers-$vm1.$vm2.$vm3-$vm4
    done | tail --lines=1 | grep -v linux-image-`uname -r`
}

velhokernel () {
    echo linux-image-`uname -r`- linux-headers-`uname -r`- linux-headers-`uname -r | sed 's/^\([^\.]*\.[^-]*\-[^-]*\)-.*$/\1/'`-
}

while true; do
    apt-get update
    apt-get autoclean
    tinicial="`stat -c %Y \"$completedir\"`"
    ( apt-get -d -y --force-yes --print-uris -f install ; apt-get -d -y --force-yes --print-uris dist-upgrade ; ( [ "`novokernel`" ] && [ "`velhokernel`" ] && apt-get -d -y --force-yes --print-uris install `novokernel` `velhokernel` ) ) | sort -u | apt-uris-processor.sh 8
    if [ "`stat -c %Y \"$completedir\"`" -eq $tinicial ]; then
        break
    fi
done



sleep 2

apt-get -d -y --force-yes dist-upgrade
# [ "`novokernel`" ] && [ "`velhokernel`" ] && echo apt-get install `novokernel` `velhokernel` && apt-get -d -y --force-yes install `novokernel` `velhokernel`
