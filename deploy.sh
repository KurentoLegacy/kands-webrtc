#!/bin/bash

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

url=$1
if [ -z "$url" ]; then
  echo "URL not assigned. Usage: ./deploy.sh URL";
  exit -1
fi

echo "Do deploy to URL: $url"

$SCRIPT_RELATIVE_PATH/build.sh && \
version=$(webrtc_get_revision) && \
mvn clean package \
  org.apache.maven.plugins:maven-deploy-plugin:2.8:deploy-file \
  -Dfile="libjingle_peerconnection_so.so" \
  -DgroupId="com.kurento.kands" \
  -DartifactId="libjingle_peerconnection_so" \
  -Dversion="$version" \
  -Dclassifier="armeabi" \
  -Dpackaging="so" \
  -Durl="$url" && \
mvn clean package \
  org.apache.maven.plugins:maven-deploy-plugin:2.8:deploy-file \
  -Dfile="libjingle_peerconnection.jar" \
  -DgroupId="com.kurento.kands" \
  -DartifactId="libjingle_peerconnection" \
  -Dversion="$version" \
  -Dpackaging="jar" \
  -Durl="$url"
