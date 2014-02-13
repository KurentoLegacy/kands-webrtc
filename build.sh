#!/bin/bash

FAIL_MARK=last_execution_fails

pushd . > /dev/null
SCRIPT_PATH=$(dirname `which $0`)
cd $SCRIPT_PATH
SCRIPT_PATH="`pwd`"
popd /dev/null

function fail {
  cd $SCRIPT_PATH
  echo "FAIL" && touch $FAIL_MARK && exit -1
}

pushd $SCRIPT_PATH

# Check for updates
if [[ ! -f $FAIL_MARK && -d "trunk" ]]; then
  pushd "trunk"

  DIFF=$(svn diff --summarize -rCOMMITTED:HEAD)
  if [ -z $DIFF ]; then
    echo "There is not any change";
    exit 0;
  fi

  popd
fi

# Update
gclient sync --nohooks --force && \
cp util/common.gypi trunk/talk/build/common.gypi || \
fail

pushd "trunk"
source ./build/android/envsetup.sh && \
gclient runhooks && \
ninja -C out/Debug libjingle_peerconnection_jar && \
revision=$(svn info | grep "Revision" | awk '{print $2}') || \
fail
popd

cp trunk/out/Debug/libjingle_peerconnection.jar . && \
cp trunk/out/Debug/libjingle_peerconnection_so.so . && \
mvn clean package -Dkands-webrtc.version=r$revision || \
fail

popd

rm -f $FAIL_MARK
