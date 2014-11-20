#!/bin/bash

function usage {
    echo "Usage:"
    echo ""
    echo "      build.sh [ -t, --target_arch (arm|arm64|ia32|x64|mipsel) ] [ -r, --revision rev_number ] [ -s, --settings mvn_settings ] -u, --url mvn_repository "
    echo ""
}

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

# Get input parameters

while [ "$1" != "" ]; do
    case $1 in
        -r | --revision )
            shift
            revision=$1
            ;;
        -t | --target_arch )
            shift
            # Valid target architectures : arm, arm64, ia32, x64, mipsel
            target_arch=$1
           ;;
        -s | --settings )
            shift
            settings=$1
            ;;
        -u | --url )
            shift
            url=$1
            ;;
        -h | --help )
            usage
            exit
            ;;
        * )
            echo "Error: Unknown option"
            usage
            exit 1
    esac
    shift
done

[ -n "$revision" ] && REVISION=" -r $revision"
[ -n "$target_arch" ] && TARGET_ARCH=" target_arch=$target_arch"
[ -n "$settings" ] && SETTINGS=" --settings $settings"
[ -n "$url" ] || { echo "Error: Maven repository URL is mandatory"; usage; exit 1; }

echo "Build WebRTC"
$SCRIPT_RELATIVE_PATH/build.sh $REVISION $TARGET_ARCH

echo "Do deploy to URL: $url"
version=r$(webrtc_get_revision) && \
mvn $SETTINGS clean package \
  org.apache.maven.plugins:maven-deploy-plugin:2.8:deploy-file \
  -Dfile="libjingle_peerconnection_so.so" \
  -DgroupId="com.kurento.kands" \
  -DartifactId="libjingle_peerconnection_so" \
  -Dversion="$version" \
  -Dclassifier="$target_arch" \
  -Dpackaging="so" \
  -Durl=$url \
  -DrepositoryId=kurento-releases && \
mvn $SETTINGS clean package \
  org.apache.maven.plugins:maven-deploy-plugin:2.8:deploy-file \
  -Dfile="libjingle_peerconnection.jar" \
  -DgroupId="com.kurento.kands" \
  -DartifactId="libjingle_peerconnection" \
  -Dversion="$version" \
  -Dpackaging="jar" \
  -Durl=$url \
  -DrepositoryId=kurento-releases
