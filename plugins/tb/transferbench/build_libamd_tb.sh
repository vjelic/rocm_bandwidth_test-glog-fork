#!/bin/bash -x 
echo ">> Building 'libamd_tb.so' ..." 
BUILD_DIRECTORY="$1"
BUILD_TYPE="$2"
BUILD_INTERNAL_BINARY_VERSION="$3"
BUILD_HIPCC_BINARY="$4"
CURRENT_WORKING_DIR=$(pwd)
PARENT_DIR=$(dirname $CURRENT_WORKING_DIR)
if [ -z $BUILD_DIRECTORY ]; then
    echo "  >> WARNING: No build directory specific. Using default './build' directory."
    BUILD_DIRECTORY="$CURRENT_WORKING_DIR/build"
fi

if [ -z $BUILD_TYPE ]; then
    echo "  >> WARNING: No build type specific. Using default 'Debug' build type."
    BUILD_TYPE="Debug"
fi

if [ -z $BUILD_HIPCC_BINARY ]; then
    echo "  >> WARNING: No path to 'hipcc' specific. Using default '/opt/rocm/bin/hipcc' ."
    BUILD_HIPCC_BINARY="/opt/rocm/bin/hipcc"
fi
pwd 
if [ ! -d $BUILD_DIRECTORY ]; then
    echo "  >> Build directory does not exist. Creating it ... '$BUILD_DIRECTORY'"
    mkdir -p $BUILD_DIRECTORY
fi
echo "  >> Cleaning up the build directory ..."
rm -rf $BUILD_DIRECTORY/*

export ROCM_PATH=/opt/rocm
CXX=$BUILD_HIPCC_BINARY cmake -S $PARENT_DIR -B $BUILD_DIRECTORY -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DBUILD_INTERNAL_BINARY_VERSION="$BUILD_INTERNAL_BINARY_VERSION"
cmake --build $BUILD_DIRECTORY
pwd
