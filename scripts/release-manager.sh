#!/bin/bash

##################################################################################################################
# 
# This script is a wrapper for helm-command-builder.sh that allows commands to be used against all releases defined for a namespace
# 
# To use thir run ./release-manager.sh [install, upgrade, template, uninstall, enc, dec] [namespace] [(optional) release_name]
# 
# Settings:
#   RELEASE_FILE_PATH defines where the definition file (default releases.yaml) is located.  This also needs to be set in helm0command-builder.sh
######################################

set -ex

################################################
# This defines where the releases will be sourced from
RELEASE_FILE_PATH="releases.yaml"
################################################

function checkCommand {
    if ! command -v $1 &> /dev/null
    then
        printf "\n%s\n" "====> The prerequisite command [$1] could not be found"
        if [[ ! -z $2 ]]; then
            printf "%s\n\n" "======> Use \"$2\" to install"
        fi
        exit
    fi
}

# ensure prerequisite commands are locally avalible 
checkCommand jq "brew install jq"
checkCommand yq "brew install yq"


HELM_RUN_COMMAND=$1 # install, upgrade, template, uninstall, enc, dec
NAMESPACE=$2
RELEASE_NAME=$3


################################################
# Parse releases.yaml for configuration and release information
################################################

# make sure its clean
rm -f temp.json
# convert yaml to json since yaml is easier to view
cat $RELEASE_FILE_PATH | yq -j '.' > temp.json




if [[ -z $RELEASE_NAME ]]; then
    echo "RELEASE_NAME is empty then we will install all of the releases in order"
    all_ns_releases=$(jq -r '. | map_values(keys) | .releases' <<< $(jq .\"$NAMESPACE\" <<< $(cat temp.json)) | sed 's/\[//' | sed 's/\]//' | sed 's/"//g' | sed 's/,//g' )
    echo $all_ns_releases
        for i in $all_ns_releases; do
            ./scripts/helm-command-builder.sh $HELM_RUN_COMMAND $NAMESPACE $i
        done
else
    ./scripts/helm-command-builder.sh $HELM_RUN_COMMAND $NAMESPACE $RELEASE_NAME
fi

# make sure its clean
rm -f temp.json

echo "Done!"