#!/usr/bin/env bash

DOCKER_IMAGE=test:latest

set -e
shopt -s xpg_echo

function print_usage {
  echo "Usage: helm-releaser.sh [-k path-to-kubeconfig-file]"
}

while getopts ":k:a:r:h" OPT; do
  case ${OPT} in
    k)
      kubeConfig=$OPTARG
      ;;
    a)
      awsConfigDir=$OPTARG
      ;;
    r)
      releaseDir=$OPTARG
      ;;
    h)
      print_usage
      exit 0
      ;;
    \?)
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    :)
      echo "Invalid option: -${OPTARG} requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Error: Invalid number of command arguments."
  echo "Expecting [command] [namespace] [release] or [command] [namespace]"
  exit 1
fi

# Prompt for kubeconfig if not set
if [ -z $kubeConfig ]; then
  echo -n "Path to kubeconfig file: "
  read kubeConfig
  kubeConfig=${kubeConfig/#\~/$HOME}
fi

# Prompt for release directory if not set
if [ -z $releaseDir ]; then
  echo -n "Path to release directory: "
  read releaseDir
  releaseDir=${releaseDir/#\~/$HOME}
fi

# Prompt for AWS config directory
if [ -z $awsConfigDir ]; then
  echo -n "Path to AWS config directory: "
  read awsConfigDir
  awsConfigDir=${awsConfigDir/#\~/$HOME}
fi

echo $kubeConfig

#######################
###  Sanity Checks  ###
#######################

# Check if files/paths are valid
[ ! -f $kubeConfig ] && echo "Error: kubeconfig '$kubeConfig' does not exist or is not readable" && exit 1
[ ! -d $releaseDir ] && echo "Error: release directory '$releaseDir' does not exist or is not readable" && exit 1
[ ! -d $awsConfigDir ] && echo "Error: AWS config directory '$awsConfigDir' does not exist or is not readable" && exit 1

#### Add command checks for: docker

######
###
######

dockerCmd="docker run --rm"
dockerCmd="${dockerCmd} -v ${kubeConfig}:/root/.kube/config"
dockerCmd="${dockerCmd} -v ${releaseDir}:/release"
dockerCmd="${dockerCmd} -v ${awsConfigDir}:/root/.aws"
dockerCmd="${dockerCmd} ${DOCKER_IMAGE}"
dockerCmd="${dockerCmd} $@"

echo "\nKubeConfig     = $kubeConfig"
echo "Release Dir    = $releaseDir"
echo "AWS Config dir = $awsConfigDir"

echo "\nThe Docker command that will be executed is:"
echo "    ${dockerCmd}"

echo -n "\nDo you want to proceed (yes|no): "
read proceed
echo ""

if [ "$proceed" == "yes" ]; then
  $dockerCmd
  echo ""
else
  echo "Aborting.\n"
  exit 1
fi
