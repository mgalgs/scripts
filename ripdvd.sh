#!/bin/bash

# usage
if [[ $1 == "-h" || $1 == "--help" || $# -gt 2 ]]; then
    echo "Usage: ripdvd.sh [dvd-device or iso]"
    echo
    echo "There are a few other parameters that can be overridden."
    echo "See the source."
    exit 1
fi

print_help_menu()
{
    cat <<"EOF"
Toggle rip selection:
   Controls whether or not the title will be ripped

Preview
   Launches a preview of the title in a separate video player

Toggle main feature
   Controls whether or not the title is considered a "main feature"
   (This only affects the resulting filename, nothing more).

EOF
}

# some params that can be overridden:
DVDDEVICE=${1:-/dev/sr0}
OUTPUTDIR=${OUTPUTDIR:-~/Videos}
DORIP=${DORIP:-yes}
HANDBRAKE_PROFILE=${HANDBRAKE_PROFILE:-"High Profile"}
HANDBRAKE_OUTPUT_FORMAT=${HANDBRAKE_OUTPUT_FORMAT:-mp4}

# check for some necessary programs
found_everything=yes
for required_prog in lsdvd HandBrakeCLI; do
    which $required_prog >/dev/null 2>&1
    [[ $? -eq 0 ]] || {
	echo "Couldn't find the \`$required_prog' utility. Please install it and try again."
	found_everything=no
    }
done
[[ $found_everything = yes ]] || exit 1


if ! lsdvd $DVDDEVICE > /dev/null 2>&1; then
    echo "Couldn't find dvd in $DVDDEVICE"
    exit 1
fi

movie_title=$(lsdvd $DVDDEVICE 2>/dev/null | grep 'Disc Title' | awk '{print $3}')

final_output_dir=$OUTPUTDIR/$movie_title
mkdir -p $final_output_dir
output_iso=$final_output_dir/${movie_title}.iso
# set output iso to dvd device if they gave an ISO
if [[ $DVDDEVICE =~ .iso$ ]]; then
    output_iso=$DVDDEVICE
    DORIP=no
fi

# read the dvd titles into an array
thetitles=()
while read -r -d $'\0'; do
    thetitles+=("$REPLY")
done < <(lsdvd $DVDDEVICE 2>/dev/null | grep -e '^Title:' | tr '\n' '\0')

# initialize the willrip and ismainfeature arrays
titleid=1
willrip=()
ismainfeature=()
for thetitle in "${thetitles[@]}"; do
    willrip[$titleid]=x
    # mark title a main feature if it's more than 15 minutes long
    ismainfeature[$titleid]=$(awk '{print $4}' <<<$thetitle | awk 'BEGIN {FS=":"} {if ($1 > 0 || $2 > 15) print "x"}')
    (( titleid++ ))
done

# do the menu
while : ; do
    titleid=1
    echo
    echo
    echo "[selected] [ismainfeature] [ id]     Title..."
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    for title in "${thetitles[@]}"; do
        titleid_formatted=$(printf "%3d" $titleid)
        willrip_formatted=$(printf "%1s" ${willrip[$titleid]})
        ismainfeature_formatted=$(printf "%1s" ${ismainfeature[$titleid]})
        echo "   [$willrip_formatted]           [$ismainfeature_formatted]       [$titleid_formatted]     $title"
        (( titleid++ ))
    done
    echo
    echo "Menu:"
    echo "xN      : Toggle rip selection for title N"
    echo "            (omit N to select/deselect all)"
    echo "pN      : Preview title N"
    echo "eN      : Toggle title N as a main feature"
    echo "            (omit N to select/deselect all)"
    echo "q       : Quit"
    echo "h       : Help"
    echo '<enter> : Go!'
    echo
    read -p " >>> " selection
    [[ -z "$selection" ]] && break
    if [[ ( ! $selection =~ ^[xpeqh] ) || ${selection:1} > ${#thetitles[@]} ]]; then
        echo "Invalid selection"
        continue
    fi
    case ${selection:0:1} in
        x*)
            if [[ -z "${selection:1}" ]]; then
                # they omitted N, toggle all
                if [[ ${willrip[1]} == "x" ]]; then
                    xval=""
                else
                    xval="x"
                fi

                myind=1
                for bogus in "${willrip[@]}"; do
                    willrip[$myind]=$xval
                    (( myind++ ))
                done
            else
                # they specified N (in ${selection:1}). toggle selection.
                if [[ "${willrip[${selection:1}]}" == "x" ]]; then
                    willrip[${selection:1}]=""
                else
                    willrip[${selection:1}]="x"
                fi
            fi
            ;;
        e*)
            if [[ -z "${selection:1}" ]]; then
                # they omitted N, toggle all
                if [[ ${ismainfeature[1]} == "x" ]]; then
                    xval=""
                else
                    xval="x"
                fi

                myind=1
                for bogus in "${willrip[@]}"; do
                    ismainfeature[$myind]=$xval
                    (( myind++ ))
                done
	    else
		if [[ "${ismainfeature[${selection:1}]}" == "x" ]]; then
                    ismainfeature[${selection:1}]=""
		else
                    ismainfeature[${selection:1}]="x"
		fi
	    fi
            ;;
        p*)
            mplayer dvd://${selection:1}/$DVDDEVICE
            ;;
        q)
            echo "Bye"
            exit 1
            ;;
	h)
	    print_help_menu
	    echo "Press enter to continue..."
	    read bogus
	    ;;
    esac
done


if [[ -e $output_iso && $DORIP == yes ]]; then
    read -p "$output_iso already exists. Do you really want to rip the iso again? [y/n] " DORIP
fi

if [[ ! $DORIP =~ ^[nN] ]]; then
    echo "saving the DVD iso to ${output_iso}..."
    dd if=$DVDDEVICE | pv > $output_iso
fi


HANDBRAKE_BASE_CMD="HandBrakeCLI --input $output_iso --preset $HANDBRAKE_PROFILE"

echo "You can watch the output by tailing /tmp/ripdvd-output.txt"

rm -f /tmp/ripdvd-output.txt

titleid=1
mainind=1
extraind=1
for thetitle in "${thetitles[@]}"; do
    if [[ ${willrip[$titleid]} == "x" ]]; then
        extrafilestuff=""
        if [[ ${ismainfeature[$titleid]} ]]; then
            extrafilestuff+="_main_${mainind}"
            (( mainind++ ))
        else
            extrafilestuff+="_extra_${extraind}"
            (( extraind++ ))
        fi
        outfile=$final_output_dir/${movie_title}${extrafilestuff}.$HANDBRAKE_OUTPUT_FORMAT
        handbrake_cmd="$HANDBRAKE_BASE_CMD --output $outfile --title $titleid"
        echo "ripping title $titleid with the following command:"
        echo $handbrake_cmd
        $handbrake_cmd >> /tmp/ripdvd-output.txt 2>&1
	grep -q "No title found" /tmp/ripdvd-output.txt
	[[ $? -eq 0 ]] && {
	    echo
	    echo 'WOW!'
	    echo "The rip doesn't seem to be working..."
	    echo "Try running the following command manually to investigate:"
	    echo $handbrake_cmd
	    exit 1
	}
    else
        echo "skipping ${titleid} (Due to user request. We fight for the Users...)"
    fi
    (( titleid++ ))
done

echo -e '\n\nAll done!'
