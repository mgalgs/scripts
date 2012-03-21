#!/bin/bash

source ~/util.sh

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

# Grab the stuff from the phone
bold_print $printtag "Syncing phone to local Phones folder"
rsync -avuz --exclude '.thumbnails' /media/${phoneids[$whosephone]}/DCIM /home/mgalgs/Phones/$whosephone

# sync to sonch if it's up:
if [[ $(hostisup sonch) = yes ]]; then
	bold_print $printtag "Syncing local Phones folder to to sonch"
	rsync -avuz -e ssh /home/mgalgs/Phones sonchl:/home/mgalgs/
	rsync -avuz -e ssh sonchl:/home/mgalgs/Phones /home/mgalgs/
else
	bold_print $printtag "Couldn't sync to sonch \(is sonch on?\)"
fi
