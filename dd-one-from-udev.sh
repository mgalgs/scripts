#!/bin/bash

LOGFILE=/var/log/dd-one-from-udev
PROGGIE=$(basename $0)

log()
{
    date +"%F %T $PROGGIE $*" >> $LOGFILE
}

# $DEVNAME should come from udev
log "hello from $0"
[[ -z "$DEVNAME" ]] && { log "DEVNAME env var not set\! bailing..."; exit 1; }
OUTDIR=${OUTDIR:-/media/space/Movies/isos}
ISOOWNER=${ISOOWNER:mgalgs}
ISOGROUP=${ISOGROUP:users}

[[ $EUID -eq 0 ]] || { log "please run as root"; exit 1; }

waitfordisc()
{
    # bonus mount seems to help get things going... don't ask me...
    tmpmount=$(mktemp)
    mkdir -p $tmpmount
    mount $DEVNAME $tmpmount
    umount $tmpmount
    rm -r $tmpmount
}

errorout()
{
    eject $DEVNAME
    exit 1
}

waitfordisc
isobase=$(blkid $DEVNAME -o value -s LABEL)
if [[ -z "$isobase" ]]; then
    # couldn't get disc title with blkid :( let's try lsdvd.
    log "Couldn't get disc title with blkid... Trying lsdvd..."
    isobase=$(lsdvd $DEVNAME | grep "Disc Title:" | cut -d: -f2 | cut -c2-)
fi
[[ -z "$isobase" ]] && { log "Couldn't get disc title. bailing."; errorout; }
isoname="${isobase}.iso"
log "ripping $isoname to $OUTDIR/$isoname"
dd if=$DEVNAME of=$OUTDIR/$isoname bs=8k || { log "dd failed. bailing."; errorout; }
chown $ISOOWNER:$ISOGROUP $OUTDIR/$isoname
log 'done!'
eject $DEVNAME
