#!/bin/bash

defaultLocation="/usr/local/bin"
defaultVersion="latest"
location=${WORKER_LOCATION:-$defaultLocation}
version=${WORKER_VERSION:-$defaultVersion}

echo "Installing location $location"
# Copyright MontFerret Team 2020
version=$(curl -sI https://github.com/MontFerret/worker/releases/latest | grep location | awk -F"/" '{ printf "%s", $NF }' | tr -d '\r')

if [ ! $version ]; then
    echo "Failed while attempting to install ferret-worker. Please manually install:"
    echo ""
    echo "1. Open your web browser and go to https://github.com/MontFerret/worker/releases"
    echo "2. Download the latest release for your platform."
    echo "3. chmod +x ./ferret-worker"
    echo "4. mv ./ferret-worker $location"
    exit 1
fi

hasCli() {
    has=$(which ferret-worker)

    if [ "$?" = "0" ]; then
        echo
        echo "You already have the ferret-worker!"
        export n=5
        echo "Overwriting in $n seconds... Press Control+C to cancel."
        echo
        sleep $n
    fi

    hasCurl=$(which curl)

    if [ "$?" = "1" ]; then
        echo "You need curl to use this script."
        exit 1
    fi

    hasTar=$(which tar)

    if [ "$?" = "1" ]; then
        echo "You need tar to use this script."
        exit 1
    fi
}

checkHash(){
    sha_cmd="sha256sum"

    if [ ! -x "$(command -v $sha_cmd)" ]; then
        sha_cmd="shasum -a 256"
    fi

    if [ -x "$(command -v $sha_cmd)" ]; then

    (cd $targetDir && curl -sSL $baseUrl/worker_checksums.txt | $sha_cmd -c >/dev/null)
        if [ "$?" != "0" ]; then
            # rm $targetFile
            echo "Binary checksum didn't match. Exiting"
            exit 1
        fi
    fi
}

getPackage() {
    uname=$(uname)
    userid=$(id -u)

    platform=""
    case $uname in
    "Darwin")
    platform="_darwin"
    ;;
    "Linux")
    platform="_linux"
    ;;
    esac

    uname=$(uname -m)
    arch=""
    case $uname in
    "x86_64")
    arch="_x86_64"
    ;;
    esac
    case $uname in
    "aarch64")
    arch="_arm64"
    ;;
    esac

    if [ "$arch" = "" ]; then
        echo "$arch is not supported. Exiting"
        exit 1
    fi

    suffix=$platform$arch
    targetDir="/tmp/worker$suffix"

    if [ "$userid" != "0" ]; then
        targetDir="$(pwd)/worker$suffix"
    fi

    if [ ! -d $targetDir ]; then
        mkdir $targetDir
    fi

    targetFile="$targetDir/worker"

    if [ -e $targetFile ]; then
        rm $targetFile
    fi

    echo

    if [ $location = $defaultLocation ]; then
        if [ "$userid" != "0" ]; then
            echo
            echo "========================================================="
            echo "==    As the script was run as a non-root user the     =="
            echo "==    following commands may need to be run manually   =="
            echo "========================================================="
            echo
            echo "  sudo cp $targetFile $location/ferret-worker"
            echo "  rm -rf $targetDir"
            echo

            exit 1
        fi
    fi

    if [ ! -d $location ]; then
        mkdir $location
    fi

    baseUrl=https://github.com/MontFerret/worker/releases/download/$version
    url=$baseUrl/worker$suffix.tar.gz
    echo "Downloading package $url as $targetFile"

    curl -sSL $url | tar xz -C $targetDir

    if [ "$?" != "0" ]; then
        echo "Failed to download file"
        exit 1
    fi

    # checkHash

    chmod +x $targetFile

    echo "Download complete."
    echo
    echo "Attempting to move $targetFile to $location"

    mv $targetFile "$location/ferret-worker"

    if [ "$?" = "0" ]; then
        echo "New version of ferret-worker installed to $location"
    fi

    if [ -d $targetDir ]; then
        rm -rf $targetDir
    fi

    "$location/ferret-worker" --version
}

hasCli
getPackage