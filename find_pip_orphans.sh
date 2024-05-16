#!/bin/bash

# List all installed packages
installed_packages=$(pip list --format=freeze | cut -d'=' -f1)

# Check for orphan packages
for package in $installed_packages; do
    # Get the packages that require the current package
    required_by=$(pip show $package | grep "Required-by:")

    # If no packages require the current package, it is an orphan
    if [[ "$required_by" =~ Required-by:[[:space:]]*$ ]]; then
        echo "$package"
    fi
done
