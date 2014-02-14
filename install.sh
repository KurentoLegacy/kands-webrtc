#!/bin/bash

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

$SCRIPT_RELATIVE_PATH/build.sh && \
mvn clean install -Dkands-webrtc.version=r$(webrtc_get_revision)
