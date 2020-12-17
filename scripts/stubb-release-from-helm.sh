#!/bin/bash

# this script will take the helm releases from a namespace
# parse them and create an outline release.yaml entry
# this can be added to the release.yaml file but will need
# the the release values/secrets path added

# usage 1./scripts/stubb-release-from-helm.sh [namespace]

# prerequisites, yq 2.11, jq, helm 

set -e

NAMESPACE=$1

resp=$(helm ls -n $NAMESPACE | tail -n +2)

stubbjson="{\"$NAMESPACE\":{\"configs\":{\"aws_profile\":\"di2e-aws\",\"secret_path\":\"ns-release-secrets\",\"values_path\":\"ns-release-values\"},\"releases\":{}}}"
stubb=$(echo $stubbjson | jq '.')


while read -r line; do
    release="$(echo $line | awk '{print $1}')"
    
    namespace="$(echo $line | awk '{print $2}')"
    chart_version="$(echo $line | awk '{print $9}')"

    version=$(echo "$chart_version" | awk -F"-" '{print $NF}')
    chart=$(echo "$chart_version" | sed "s/-$version//")

    echo "Release: [$release]"
    echo "Namespace: [$namespace]"
    echo "ChartVersion: [$chart_version]"
    echo "Chart: [$chart]"
    echo "Version: [$version]"

    
    # echo "$chart $version"
    stub_release="{\"$release\":{} }"
    # create one chart/release entry
    an_entry=$(jq -n --arg r "$release" --arg c "$chart" --arg v "$version" '{ path: $c, version: $v } |  . | {chart: . } | .release.secrets |= . + null | .release.values |= .+null')
    
    # create json for a single release
    jq_string=".\"$release\" = $an_entry"
    a_release=$(echo $stub_release | jq "$jq_string")
    
    # add a release json object to the stubb
    jq_string=".\"$NAMESPACE\".releases += $a_release"
    stubb=$(echo $stubb | jq "$jq_string")
    
done <<< "$resp"

echo "THIS IS THE FINAL!!!"
echo $stubb | yq -y . > ${NAMESPACE}-release-stub.yaml
