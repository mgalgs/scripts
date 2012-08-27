#!/bin/bash

# You might also want to add this to your .bashrc:
# complete -F _pgrep wait_for_thing.sh


[[ $# -ne 1 || $1 == "-h" || $1 == "--help" ]] && { echo "usage: $0 name"; exit 1; }

pidof $1 || { echo "nothing much"; exit 0; }
echo "waiting for $1 ($(pidof $1 | tr '\n' ','))"
while pidof $1 2>&1 >/dev/null; do
    echo -n '.'
    sleep 1
done

echo
xmessage -nearmouse "wait_for_thing \`$1' is complete"
