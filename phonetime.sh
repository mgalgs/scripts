#!/bin/bash

source ~/scripts/util.sh

mountroot=/run/media/$(whoami)
syncdest=/media/space
printtag=' ::=> '

declare -A phoneids
phoneids=([mitchel]=3AEB-1010 [sonnie]=BC4C-1008)
whosephone=none

for id in ${!phoneids[@]}; do
	if [[ -d ${mountroot}/${phoneids[$id]} ]]; then
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
rsync -avuz --exclude '.thumbnails' ${mountroot}/${phoneids[$whosephone]}/DCIM /home/mgalgs/Phones/$whosephone

# sync to sonch if it's up:
if grep -qs $syncdest /proc/mounts; then
	bold_print $printtag "Syncing local Phones folder to sonch"
	rsync -avuz --no-g /home/mgalgs/Phones $syncdest
	rsync -avuz --no-g ${syncdest}/Phones /home/mgalgs/
else
	bold_print $printtag "Couldn't sync to space (is the freenas server accessible?)"
fi
