#!/bin/bash

# roughly sort git sha1s by date

source $(dirname $0)/util.sh

[[ -d "$1" ]] && cd "$1"

sha1s=()

while read l; do
    # the tr is to trim whitespace
    sha1s+=($(tr -d '[[:space:]]' <<<"$l"))
done

git rev-list ${sha1s[@]} | grep -f <(array_print_one_per_line sha1s[@])
