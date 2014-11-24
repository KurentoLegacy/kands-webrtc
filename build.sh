#!/bin/bash

SCRIPT_RELATIVE_PATH=$(dirname $0)
source $SCRIPT_RELATIVE_PATH/utils.sh

SCRIPT_ABS_PATH=$(get_abs_path)

function usage {
    echo "Usage:"
    echo ""
    echo "      build.sh [ -t, --target_arch (arm|arm64|ia32|x64|mipsel) ] [ -r, --revision rev_number ] [ -d, --debug ]"
    echo ""
    echo "           -t, --target_arch    Default target architecture. Default is arm"
    echo "           -r, --revision       Build release. Default is latest"
    echo "           -d, --debug          Build debug mode. By default release is build"
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
        -d | --debug )
            # Activate debug mode
            BIN_DIR="out/Debug"
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
gclient sync $REVISION --force || { echo "Error: Unable to sync source code"; exit 1; }

pushd "src" > /dev/null
echo "Build: Set android environment and run hooks"
source ./build/android/envsetup.sh && \
export GYP_DEFINES="$GYP_DEFINES $TARGET_ARCH" && 
echo "Build: GYP_DEFINES = $GYP_DEFINES" && \
gclient runhooks || \
{ echo "Error: runhooks failed"; exit 1; }

[ -z "$BIN_DIR" ] && BIN_DIR="out/Release"
ninja -C $BIN_DIR libjingle_peerconnection_jar || { echo "Error: WebRTC compilation failed"; exti 1; }
cp $BIN_DIR/libjingle_peerconnection.jar .. && \
cp $BIN_DIR/libjingle_peerconnection_so.so .. || { echo "Error: Unable to find libjingle binaries"; exit 1 ; }