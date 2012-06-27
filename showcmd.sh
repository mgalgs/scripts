#!/bin/bash

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
    echo "Usage: $0 cmd"
    exit 1
fi

cmd="$*"; echo "\$ $cmd"; exec $cmd
