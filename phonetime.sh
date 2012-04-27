#!/bin/bash

source ~/scripts/util.sh

printtag=' ::=> '

declare -A phoneids
phoneids=([mitchel]=3AEB-1010 [sonnie]=BC4C-1008)
whosephone=none

for id in ${!phoneids[@]}; do
	if [[ -d /media/${phoneids[$id]} ]]; then
		whosephone=$id
	fi
done

if [[ $whosephone = none ]]; then
	bold_print "Failure" 'No phone detected!'
	exit 1
fi

bold_print "Detected ${whosephone}'s phone..."

mkdir -p ~/Phones

# Grab the stuff from the phone
bold_print $printtag "Syncing phone to local Phones folder"
rsync -avuz --exclude '.thumbnails' /media/${phoneids[$whosephone]}/DCIM /home/mgalgs/Phones/$whosephone

# sync to sonch if it's up:
if grep -qs /media/space /proc/mounts; then
	bold_print $printtag "Syncing local Phones folder to "
	rsync -avuz --no-g /home/mgalgs/Phones /media/space/
	rsync -avuz --no-g /media/space/Phones /home/mgalgs/
else
	bold_print $printtag "Couldn't sync to space (is the freenas server accessible?)"
fi
