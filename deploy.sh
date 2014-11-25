#!/bin/bash

function usage {
    echo "Usage:"
    echo ""
    echo "      deploy.sh [ -d, --debug] [ -t, --target_arch (armeabi|x86|mipsel) ] [ -r, --revision rev_number ] [ -s, --settings mvn_settings ] -u, --url mvn_repository "
    echo ""
}

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

# Get input parameters

while [ "$1" != "" ]; do
    case $1 in
        -d | --debug )
            debug="-d"
            ;;
        -r | --revision )
            shift
            revision=$1
            ;;
        -t | --target_arch )
            shift
            # Valid CPU ARCHS : armeabi, x86, mips
            # http://www.kandroid.org/ndk/docs/CPU-ARCH-ABIS.html
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
[ -n "$settings" ] && SETTINGS=" --settings $settings"
[ -n "$url" ] || { echo "Error: Maven repository URL is mandatory"; usage; exit 1; }
if [ "$target_arch" = "armeabi" ]; then
    TARGET_ARCH=" -t arm"
elif [ "$target_arch" = "x86" ]; then
    TARGET_ARCH=" -t ia32" # assume 32 emulators
elif [ "$target_arch" = "mips" ]; then
    TARGET_ARCH=" -t mipsel"
elif [ -z "$target_arch" ]; then
    TARGET_ARCH=""
    target_arch="armeabi"
else
    echo "Error: unknown ndk CPU architecture selected: $target_arch"
    usage
    exit 1
fi

echo "Build WebRTC"
$SCRIPT_RELATIVE_PATH/build.sh $REVISION $TARGET_ARCH $debug || \
    { echo "Error: Build failed"; exit 1; }

echo "Do deploy to URL: $url"
version=r$(webrtc_get_revision) || { echo "Unable to get version"; exit 1; }
[ -f libjingle_peerconnection_so.so ] && mvn $SETTINGS clean package \
  org.apache.maven.plugins:maven-deploy-plugin:2.8:deploy-file \
  -Dfile="libjingle_peerconnection_so.so" \
  -DgroupId="com.kurento.kands" \
  -DartifactId="libjingle_peerconnection_so" \
  -Dversion="$version" \
  -Dclassifier="$target_arch" \
  -Dpackaging="so" \
  -Durl=$url \
  -DrepositoryId=kurento-releases
[ -f libjingle_peerconnection.jar ] && mvn $SETTINGS clean package \
  org.apache.maven.plugins:maven-deploy-plugin:2.8:deploy-file \
  -Dfile="libjingle_peerconnection.jar" \
  -DgroupId="com.kurento.kands" \
  -DartifactId="libjingle_peerconnection" \
  -Dversion="$version" \
  -Dpackaging="jar" \
  -Durl=$url \
  -DrepositoryId=kurento-releases
