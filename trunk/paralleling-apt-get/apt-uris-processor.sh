#!/bin/bash

partialdir="/var/cache/apt/archives/partial"
completedir="/var/cache/apt/archives"
maxprocs=25

[ "$1" ] && maxprocs="$1"

procs=""
( ( while read lin; do echo "${lin}"; done ) | awk '{ print $1,$2; }' | egrep '(http|ftp)://'; echo '##final##' ) | while read linha; do
    if [ "$linha" != '##final##' ]; then
        base="`echo \"$linha\" | awk -F "' " '{ print $2; }'`"
        url="`echo \"$linha\" | awk -F "'" '{ print $2; }'`"
        if ! [ -e "$completedir/$base" ]; then
            while true; do
                procsnew=""
                for proc in $procs; do
                    if ps -p "$proc" > /dev/null 2>&1; then
                        procsnew="$procsnew $proc"
                    fi
                done
                conta=0
                procs="$procsnew"
                for proc in $procs; do
                    conta=$((conta+1))
                done
                if [ "$conta" -lt "$maxprocs" ]; then
                    break
                else
                    sleep 1
                fi
            done
            ( wget --continue --tries=0 --timeout=20 -O "$partialdir/$base" "$url" && mv -v "$partialdir/$base" "$completedir/$base" ) & \
            procs="$procs $!"
        fi
    else
        while true; do
            procsnew=""
            for proc in $procs; do
                if ps -p "$proc" > /dev/null 2>&1; then
                    procsnew="$procsnew $proc"
                fi
            done
            procs="$procsnew"
            if [ "$procs" ]; then
                sleep 1
            else
                break
            fi
        done
    fi
done

sleep 2
