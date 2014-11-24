#!/bin/bash

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

SCRIPT_ABS_PATH=$(get_abs_path)

function end {
  pushd $SCRIPT_ABS_PATH > /dev/null

  cp src/out/Debug/libjingle_peerconnection.jar . && \
  cp src/out/Debug/libjingle_peerconnection_so.so . &&

  popd > /dev/null # $SCRIPT_ABS_PATH

  exit 0;
}

function usage {
    echo "Usage:"
    echo ""
    echo "      build.sh [ -t, --target_arch (arm|arm64|ia32|x64|mipsel) ] [ -r, --revision rev_number ]"
    echo ""
}

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
        -h | --help )
            usage
            exit
            ;;
        * )
            usage
            exit 1
    esac
    shift
done

[ -n "$revision" ] && REVISION=" -r $revision"
[ -n "$target_arch" ] && TARGET_ARCH="target_arch=$target_arch"

pushd $SCRIPT_ABS_PATH > /dev/null

# Get depot_tools
[ -d ./depot_tools ] || git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git || \
    { echo "Unable to download depot_tools"; exit 1; }
export PATH=$PATH:$SCRIPT_ABS_PATH/depot_tools

# Update
gclient sync $REVISION || \
echo "*** Probably critical error ***"

pushd "src" > /dev/null
source ./build/android/envsetup.sh && \
export GYP_DEFINES="build_with_libjingle=1 build_with_chromium=0 libjingle_java=1 enable_tracing=1 OS=android $TARGET_ARCH $GYP_DEFINES" && \
gclient runhooks && \
echo "Using following GYP_DEFINES: $GYP_DEFINES"

ninja -C out/Release libjingle_peerconnection_jar || { echo "Error: WebRTC compilation failed"; exti 1; }
popd > /dev/null # "src"
popd > /dev/null # $SCRIPT_ABS_PATH
end
