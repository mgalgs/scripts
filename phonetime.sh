#!/bin/bash

USBDEVICES=(18d1:4ee1 18d1:4ee2)

declare -A phoneids
phoneids=(
    [mitchel_N4]=004add3e851192f4
    [sonnie_N4]=004b091190078df4
    [mitchel_Nexus_S]=3AEB-1010
    [sonnie_Nexus_S]=BC4C-1008
)

source ~/scripts/util.sh

syncdest=/net/space/media/space
printtag=' ::=> '

usage()
{
    echo "Usage: $(basename $0) [options]"
    echo
    echo "Options:"
    echo " --local    Local sync only. Don't look for a phone."
}

local_sync()
{
    bold_print $printtag "Syncing local Phones folder to sonch"
    rsync -avuz --no-g $HOME/Phones $syncdest
    rsync -avuz --no-g ${syncdest}/Phones $HOME/
}

[[ "$1" = "-h" || "$1" = "--help" ]] && { usage; exit 1; }
[[ "$1" = "--local" ]] && { local_sync; exit $?; }

# if this is a PTP phone, get the serial number using gphoto
gphoto_serial_number=$(gphoto2 --summary 2>/dev/null | grep '  Serial Number' | cut -d' ' -f5)
# if this is a Nexus 4, get the serial number using lsusb
for usbdevice in ${USBDEVICES[@]}; do
    n4_serial_number=$(lsusb -d $usbdevice -v 2>/dev/null | grep iSerial | awk '{print $3}')
    [[ -n "$n4_serial_number" ]] && break
done

if [[ -n "$n4_serial_number" ]]; then
    serial_number=$n4_serial_number
    use_mtpfs=yes
    use_go_mtpfs=yes
    echo "Found an mtpfs phone (${serial_number})"
elif [[ -n "$gphoto_serial_number" ]]; then
    serial_number=$gphoto_serial_number
    use_gphotofs=yes
    echo "Found a gphotofs phone (${serial_number})"
else
    echo "No phone detected :("
    exit 1
fi

if [[ -n "$serial_number" ]]; then
    for id in ${!phoneids[@]}; do
        if [[ ${phoneids[$id]} == "$serial_number" ]]; then
            whichphone=$id
            if [[ $use_mtpfs = "yes" ]]; then
                mountdir=/media/mtpfs/$whichphone
                mkdir -pv $mountdir
                srcdir="$mountdir/Internal storage/DCIM"
                echo "Will mount mtpfs at $mountdir"
                if [[ $use_go_mtpfs = yes ]]; then
                    go-mtpfs $mountdir &
                else
                    mtpfs -o allow_other $mountdir
                fi
                while :; do
                    echo "waiting for $srcdir to show up..."
                    sleep 1
                    [[ -d "$srcdir" ]] && break
                done
            elif [[ $use_gphotofs = "yes" ]]; then
                mountdir=/media/gphotofs/$whichphone
                srcdir=$mountdir
                echo "Will mount gphotofs at $srcdir"
                gphotofs $srcdir || exit 1
            fi
            break
        fi
    done
else
    # this is an old phone (mounted directly as filesystems)
    if grep -q Ubuntu /etc/lsb-release 2>/dev/null; then
        mountrootroot=/media
    else
        mountrootroot=/run/media
    fi
    mountroot=${mountrootroot}/$(whoami)
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

# sync to sonch if the rsync succeeded and if sonch is up:
if [[ $? -eq 0 ]]; then
    local_sync
fi

[[ $use_mtpfs = "yes" && $use_go_mtpfs ]] && pkill go-mtpfs

mount | grep -q -e fuse.gphotofs -e DeviceFs\(Nexus\ 4\) && fusermount -u "$mountdir"
