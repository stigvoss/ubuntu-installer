#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

WORKDIR=/tmp
INSTALLERDIR=$WORKDIR/ubuntu-installer

cd $WORKDIR

git clone https://github.com/stigvoss/ubuntu-installer.git

cd $INSTALLERDIR
