#!/bin/bash

[[ -e "$1" ]] || { echo "usage: $0 file"; exit 1; }

indent "$1"

while : ; do
    biggest=$(awk '{print length(), NR}' "$1" | sort -n -r | head -1)
    thecols=$(cut -d' ' -f1 <<<$biggest)
    linum=$(cut -d' ' -f2 <<<$biggest)
    [[ $thecols -gt 80 ]] || break
    emacs +${linum} --batch --file "$1" \
	--eval '(progn (fill-paragraph) (save-buffer))'
done
