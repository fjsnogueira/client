#!/usr/bin/env bash

set -e -u -o pipefail # Fail on error

dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
cd "$dir"

build_dir=${BUILD_DIR:-/tmp/keybase}

mkdir -p "$build_dir"

current_date=`date -u +%Y%m%d%H%M%S` # UTC
commit_short=`git log -1 --pretty=format:%h`
build="$current_date+$commit_short"
keybase_build=${KEYBASE_BUILD:-$build}
tags=${TAGS:-"prerelease production"}
ldflags="-X github.com/keybase/client/go/libkb.PrereleaseBuild=$keybase_build"

if [ "$PLATFORM" = "darwin" ]; then
  # To get codesign to work you have to use -ldflags "-s ...", see https://github.com/golang/go/issues/11887
  ldflags="-s $ldflags"
fi

echo "Building $build_dir/keybase ($keybase_build)"
GO15VENDOREXPERIMENT=1 go build -a -tags "$tags" -ldflags "$ldflags" -o "$build_dir/keybase" "github.com/keybase/client/go/keybase"

if [ "$PLATFORM" = "darwin" ]; then
  code_sign_identity="Developer ID Application: Keybase, Inc. (99229SGT5K)"
  codesign --verbose --force --deep --sign "$code_sign_identity" "$build_dir/keybase"
elif [ "$PLATFORM" = "linux" ]; then
  echo "No codesigning for linux"
elif [ "$PLATFORM" = "windows" ]; then
  echo "No codesigning for windows"
else
  echo "Invalid PLATFORM"
  exit 1
fi

version=`"$build_dir"/keybase version -S`
echo "Keybase version: $version"
