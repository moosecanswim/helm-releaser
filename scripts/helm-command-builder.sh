#!/bin/bash

##################################################################################################################
##################################################################################################################
# 
# This script is designed to simplify the command necessary to preform helm and helm secrets opperations.
# 
# This script uses an input file "release.yaml" which defines releases:
# namespace:
#   configs:
#     aws_profile: name of aws profile to use with secrets
#     secret_path: default path to source secrets for the namespace
#     values_path: default path to source release values for the namespace
#   releases:
#     a-release-name:
#       chart:
#         path: path to helm chart (can be local chart, remote chart, or tarball)
#         version: chart version
#       release:
#         values: name of the release values file (relative to path defined in values_path)
#         secrets: name of the release secrets file (relative to path defined in secret_path)
#       config: (optional if the release has different release values/secrets path than those defined in namespace.configs)
#         aws_profile: name of aws profile to use with secrets
#         secret_path: override path to source release secrets
#         values_path: overides path to source release values 
# 
# To use thir run ./helm-command-builder.sh [install, upgrade, template, uninstall, enc, dec] [namespace] [release_name]
# 
# Settings:
#   RELEASE_FILE_PATH defines where the definition file (default releases.yaml) is located
##################################################################################################################
##################################################################################################################

set -ex

######################################################
# This defines where the releases will be sourced from
RELEASE_FILE_PATH=releases.yaml
#####################################################

function checkCommand {
    if ! command -v $1 &> /dev/null
    then
        printf "\n%s\n" "====> The prerequisite command [$1] could not be found"
        if [[ ! -z $2 ]]; then
            printf "%s\n\n" "======> Use \"$2\" to install"
        fi
        exit 5
    fi
}

function validateRemoteChart {
    # validate that a helm repo is present locally when the chart path indicates its a remote chart
    if [[ $1 = */* ]]; then
    # get helm repo
    repo=$(echo $1 | awk -F/ '{print $1}' | tr -cd "[:alnum:]")
        # ensure repo is avalible locally
        if [[ ! $repo == $(helm repo list | grep kanister | awk '{print $1}') ]]; then
        printf "\n%s\n\n" "=====> The repo helm repo [$repo] is not avalible locally.  run a 'helm repo add $repo <repo url>' then run the make command again"
        exit 5
        fi
    fi
}

function validateUpgradeUninstall {
    # validate upgrade or uninstall
        {
            helm get all $2 -n $1 >/dev/null
        } || {
            printf "\n%s\n\n" "====> Helm release [$2] does not exist in namespace: [$1].  CANT UPGRADE OR UNINSTALL.  Exiting! "
            exit 3
        }
}

function validateAWS {
    # validate aws-profile provided is local
    if [[ $(aws configure --profile $1 list) && $? -eq 0 ]]; then
        echo "$1 Exists" 
    else
        echo "$1 Does not exist.  You will need to add it locally then run the install again." 
        exit 4
    fi
}

# ensure prerequisite commands are locally avalible 
checkCommand jq "brew install jq"
checkCommand yq "pip3 install yq"
checkCommand helm "brew install kubernetes-helm"
checkCommand aws "brew install awscli"
checkCommand sops "brew install sops"

# ensure helm version 3 is used
if [[ ! $(helm version | sed 's/.*{Version://'  | awk 'BEGIN {FS=",";}{print $1}' | awk -F. '{print $1}' | tr -cd "[:alnum:]") == v3 ]]; then
    printf "\n%s\n\n" "====> This script requires helm 3.  exiting"
    exit 4
fi


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


# get release info and configs for the namespace
# jq parse strings
releases_query="jq .\"$NAMESPACE\".releases.\"$RELEASE_NAME\""
ns_configs_query="jq .\"$NAMESPACE\".configs"
release_configs_query="jq .\"$NAMESPACE\".releases.\"$RELEASE_NAME\".configs"

# use above jq parse strings
asset_releases=$(cat temp.json | $releases_query)
asset_ns_config=$(cat temp.json | $ns_configs_query)
asset_release_configs=$(cat temp.json | $release_configs_query)

# validate a release was found/parsed
if [[ $asset_releases == null ]]; then
    printf "\n%s\n\n" "====> Either Namespace [$NAMESPACE] or Release [$RELEASE_NAME] provided was not found in releases.yaml"
    exit 2
fi
# validate a namespace config was found/parsed
if [[ $asset_ns_config == null ]]; then
    printf "\n%s\n\n" "====> namespace level configs are not present in releases.yaml"
    exit 1
fi
# validate a release config was found/parsed
if [[ $asset_release_configs == null ]]; then
    printf "\n%s\n\n" "====> release level configs are not present in releases.yaml will be using namespace level configs"
fi


# Parse namespace level configs
NS_AWS_PROFILE=$(echo $asset_ns_config | jq -r '.aws_profile')
NS_RELEASE_SECRETS_PATH=$(echo $asset_ns_config | jq -r '.secret_path')
NS_RELEASE_VALUES_PATH=$(echo $asset_ns_config | jq -r '.values_path')

# Parse release level configs
echo $asset_release_configs
RELEASE_AWS_PROFILE=$(echo $asset_release_configs | jq -r '.aws_profile')
RELEASE_RELEASE_SECRETS_PATH=$(echo $asset_release_configs | jq -r '.secret_path')
RELEASE_RELEASE_VALUES_PATH=$(echo $asset_release_configs | jq -r '.values_path')

# if the release has configus use those otherwise use the namespace level configs
if [[ ! $RELEASE_AWS_PROFILE == null ]]; then
    echo "using release config aws_profile"
    AWS_PROFILE=$RELEASE_AWS_PROFILE
else
    echo "Using namespace config aws_profile"
    AWS_PROFILE=$NS_AWS_PROFILE
fi
if [[ ! $RELEASE_RELEASE_SECRETS_PATH == null ]]; then
    echo "using release config csf"
    RELEASE_SECRETS_PATH=$RELEASE_RELEASE_SECRETS_PATH
else
    echo "using namespace config csf"
    RELEASE_SECRETS_PATH=$NS_RELEASE_SECRETS_PATH
fi
if [[ ! $RELEASE_RELEASE_VALUES_PATH == null ]]; then
    echo "using release config cvf"
    RELEASE_VALUES_PATH=$RELEASE_RELEASE_VALUES_PATH
else
    echo "using namespace config cvf"
    RELEASE_VALUES_PATH=$NS_RELEASE_VALUES_PATH
fi

echo "AWS Profile: $AWS_PROFILE"
echo "Custom Secret File: $RELEASE_SECRETS_PATH"
echo "Custom Value File: $RELEASE_VALUES_PATH"

# Parse release info
CHART=$(echo $asset_releases | jq -r '.chart.path')
VERSION=$(echo $asset_releases | jq -r '.chart.version')
RELEASE_SECRETS=$(echo $asset_releases | jq -r '.release.secrets')
RELEASE_VALUES=$(echo $asset_releases | jq -r '.release.values')




########################
# helm command builder #
########################

validateRemoteChart $CHART

# Create the prefix and suffix for helm secrets
helm_secrets_prefix=" "
if [[ ! $RELEASE_SECRETS == null ]];then
    # ensure this profile is avalible locally
    validateAWS $AWS_PROFILE

    release_secrets_arg="-f $RELEASE_SECRETS_PATH/$RELEASE_SECRETS"
    # place helm secrets validation in here when its ready
    helm_secrets_prefix="AWS_PROFILE=$AWS_PROFILE"
fi
# set version argument
if [[ ! $VERSION == null ]];then
    helm_version="--version $VERSION"
fi
# set release values argument
if [[ ! $RELEASE_VALUES == null ]];then
    release_values_arg="-f $RELEASE_VALUES_PATH/$RELEASE_VALUES"
fi



case $HELM_RUN_COMMAND in
    enc)
        echo "Do an encrypt"
        helm_run=$(printf "helm secrets enc %s" "$RELEASE_SECRETS_PATH/$RELEASE_SECRETS")
        ;;
    dec)
        echo "do a decrypt"
        helm_run=$(printf "helm secrets dec %s" "$RELEASE_SECRETS_PATH/$RELEASE_SECRETS")
        ;;
    install)
        echo "do an install"
        helm_run=$(printf "helm install %s %s %s %s %s %s" $RELEASE_NAME $CHART $helm_version "$release_values_arg" "$release_secrets_arg" "-n $NAMESPACE")
        ;;
    upgrade)
        echo "do an upgrade"
        validateUpgradeUninstall $NAMESPACE $RELEASE_NAME
        helm_run=$(printf "helm upgrade %s %s %s %s %s %s" $RELEASE_NAME $CHART $helm_version "$release_values_arg" "$release_secrets_arg" "-n $NAMESPACE")
        ;;
    uninstall)
        echo "do an uninstall"
        validateUpgradeUninstall $NAMESPACE $RELEASE_NAME
        helm_secrets_prefix=""
        helm_run=$(printf "helm uninstall %s %s\n\n" $RELEASE_NAME "-n $NAMESPACE")
        ;;
    template)
        echo "do an template"
        if [[ ! $VERSION == null ]];then
            template_location="> $RELEASE_NAME-$VERSION-template.yaml"
        else
            template_location="> $RELEASE_NAME-latest-template.yaml"
        fi
        helm_run=$(printf "helm template %s %s %s %s %s %s %s" $RELEASE_NAME $CHART $helm_version "$release_values_arg" "$release_secrets_arg" "-n $NAMESPACE" $template_location)
        ;;
    *)
        echo "This helm run command [$1] not known.  use one of the following [enc, dec, install, upgrade, template, uninstall]"
esac

# Appends helm secret prefix if needed
helm_run=$(printf "\n%s %s\n\n" "$helm_secrets_prefix" "$helm_run")

printf "\n%s\n\n" "$helm_run"
# eval $helm_run