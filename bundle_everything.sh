#!/bin/bash

num_commits=${1:-20}

mdie()
{
    echo "error: $1"
    exit
}

bundle_current_repo()
{
    bndlname=$(basename $PWD).bundle
    git bundle create $bndlname -10 master 2>/dev/null || mdie "couldn't create bundle $bndlname"
    echo "$PWD/$bndlname"
}

# clean up any old bundles
rm -f *.bundle

echo "bundling up repo(s)"
# first bundle the parent repo
echo -n "."
bndl=$(bundle_current_repo)

submodules=$(git submodule foreach --quiet 'echo $path')
for m in $submodules; do
    cd $m
    echo -n "."
    bndl=$(bundle_current_repo)
    cd - 2>&1 >/dev/null
    [[ -n "$bndl" ]] && mv $bndl .
done
echo

echo "tar'ing up bundles"
dest_tar=my_emacs_bundle-$(date +%F).tar.xz
rm -f $dest_tar
tar cJf $dest_tar *.bundle || mdie "Couldn't tar up the bundles'"
echo "created $dest_tar"
rm *.bundle
