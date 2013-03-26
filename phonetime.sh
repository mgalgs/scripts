#!/bin/bash

declare -A phoneids
phoneids=(
    [mitchel_N4]=004add3e851192f4
    [sonnie_N4]=TBD
    [mitchel_Nexus_S]=3AEB-1010
    [sonnie_Nexus_S]=BC4C-1008
)

source ~/scripts/util.sh

if grep -q Ubuntu /etc/lsb-release 2>/dev/null; then
    mountrootroot=/media
else
    mountrootroot=/run/media
fi
mountroot=${mountrootroot}/$(whoami)
syncdest=/media/space
printtag=' ::=> '

whichphone=none

# TODO: support mtp instead of ptp
# LD_LIBRARY_PATH=/home/mgalgs/src/libmtp-code/src/.libs/ ~/src/go-mtpfs/go-mtpfs /media/mtpfs/mitchel_N4/

# if this is a PTP phone, get the serial number using gphoto
gphoto_serial_number=$(gphoto2 --summary | grep '  Serial Number' | cut -d' ' -f5)

if [[ -n "$gphoto_serial_number" ]]; then
    # this is a new phone (detected with gphoto)
    for id in ${!phoneids[@]}; do
	if [[ ${phoneids[$id]} == "$gphoto_serial_number" ]]; then
	    whichphone=$id
	    srcdir=/media/gphotofs/$whichphone
	    gphotofs $srcdir
	    break
	fi
    done
else
    # this is an old phone (mounted directly as filesystems)
    for id in ${!phoneids[@]}; do
	if [[ -d ${mountroot}/${phoneids[$id]} ]]; then
            whichphone=$id
	    srcdir="${mountroot}/${phoneids[$whichphone]}/DCIM"
            break
	fi
    done
fi


if [[ $whichphone = none ]]; then
        bold_print "Failure" 'No phone detected!'
        exit 1
fi

bold_print "Detected phone:" "${whichphone}"

dstdir="$HOME/Phones/$whichphone"
mkdir -p $dstdir

# Grab the stuff from the phone
bold_print $printtag "Syncing phone to local Phones folder"
rsync -avuz --exclude '.thumbnails' "$srcdir" "$dstdir"

# sync to sonch if it's up:
if grep -qs $syncdest /proc/mounts; then
        bold_print $printtag "Syncing local Phones folder to sonch"
        rsync -avuz --no-g $HOME/Phones $syncdest
        rsync -avuz --no-g ${syncdest}/Phones $HOME/
else
        bold_print $printtag "Couldn't sync to $syncdest (is the freenas server accessible?)"
fi

mount | grep -q fuse.gphotofs && fusermount -u $srcdir
