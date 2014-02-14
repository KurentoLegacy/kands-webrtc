#!/bin/bash

function get_abs_path {
  pushd . > /dev/null
  abs_path=$(dirname `which $0`)
  cd $abs_path
  abs_path=$(pwd)
  popd > /dev/null

  echo $abs_path
}

function webrtc_get_revision {
  echo $(cd "trunk" && svn info | grep "Revision" | awk '{print $2}')
}
