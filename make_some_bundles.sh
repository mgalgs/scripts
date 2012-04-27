#!/bin/bash

for i in ~/scripts ~/conf-files ~/.emacs.d ~/sites/mgalgs.github.com; do
    (
        cd $i
        bundle_everything.sh
    )
done

destdir=$(mktemp -d)

find . -maxdepth 3 -name 'my*bundle*xz' -exec mv -v {} $destdir \;
[[ $(ls -1 $destdir | wc -l) -lt 1 ]] && { echo "no bundles found"; exit; }

echo "creating the big ol' bundle"
destbundle=bundles-$(date +%F).tar
tar cvf $destbundle -C $destdir .
echo "$destbundle bundle created"
