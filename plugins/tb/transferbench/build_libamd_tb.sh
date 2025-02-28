#!/bin/bash -x 
echo "Building 'libamd_tb.so' ..." 
rm -rf ./build/; 
mkdir ./build/; 
cd $_ ; 
export ROCM_PATH=/opt/rocm; 
CXX=/opt/rocm/bin/hipcc cmake -DCMAKE_BUILD_TYPE=Debug .. ; 
make
cd -

