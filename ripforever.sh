#!/bin/bash

DVDDEVICE=${DVDDEVICE:-/dev/sr0}
OUTDIR=${OUTDIR:-/media/space/Movies/isos}
ISOOWNER=${ISOOWNER:mgalgs}
ISOGROUP=${ISOGROUP:users}

[[ $EUID -eq 0 ]] || { echo "please run as root"; exit 1; }

waitfordisc()
{
    while :; do
        [[ -e $DVDDEVICE ]] && { echo; break; }
        echo -n .
        sleep 5
    done
    # bonus mount seems to help get things going... don't ask me...
    mkdir -p /mnt/ripforever
    mount $DVDDEVICE /mnt/ripforever
    umount /mnt/ripforever
    rm -r /mnt/ripforever
}

errorout()
{
    eject $DVDDEVICE
    exit 1
}

while :; do
    waitfordisc
    isobase=$(blkid $DVDDEVICE -o value -s LABEL)
    if [[ -z "$isobase" ]]; then
        # couldn't get disc title with blkid :( let's try lsdvd.
        echo "Couldn't get disc title with blkid... Trying lsdvd..."
        isobase=$(lsdvd $DVDDEVICE | grep "Disc Title:" | cut -d: -f2 | cut -c2-)
    fi
    [[ -z "$isobase" ]] && { echo "Couldn't get disc title. bailing."; errorout; }
    isoname="${isobase}.iso"
    echo "ripping $isoname to $OUTDIR/$isoname"
    dd if=$DVDDEVICE of=$OUTDIR/$isoname bs=8k || { echo "dd failed. bailing."; errorout; }
    chown $ISOOWNER:$ISOGROUP $OUTDIR/$isoname
    echo 'done!'
    eject $DVDDEVICE
done
