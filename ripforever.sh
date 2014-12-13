#!/bin/bash

DVDDEVICE=${DVDDEVICE:-/dev/sr0}
OUTDIR=${OUTDIR:-/media/space/Movies/isos}
ISOOWNER=${ISOOWNER:mgalgs}
ISOGROUP=${ISOGROUP:users}

[[ $EUID -eq 0 ]] || { echo "please run as root"; exit 1; }

waitfordisc()
{
    echo -n "waiting for disc..."
    while :; do
        [[ -e $DVDDEVICE ]] && { echo; break; }
        echo -n .
        sleep 5
    done
}

while :; do
    waitfordisc
    isoname=$(echo "$(blkid $DVDDEVICE -o value -s LABEL).iso")
    echo "ripping $isoname"
    dd if=$DVDDEVICE of=$OUTDIR/$isoname || { echo "dd failed. bailing."; exit 1; }
    chown $ISOOWNER:$ISOGROUP $OUTDIR/$isoname
    echo 'done!'
    eject $DVDDEVICE
done
