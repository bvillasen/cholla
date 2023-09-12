#!/bin/bash

rocshore_dir=$(pwd)
cholla_dir="$(dirname "$rocshore_dir")"
echo "Cholla dir: ${cholla_dir}"

echo "Seting MI300A environment"
source ${cholla_dir}/builds/setup.mi300.sh

echo "Compiling Cholla Cosmology"
cd $cholla_dir
make TYPE=cosmology -j
executable="$(ls "${cholla_dir}/bin")"
echo "Found executable: ${executable}"
cd $rocshore_dir
cp "${cholla_dir}/bin/${executable}" .

#Download initial conditions
ics_file=ics_256_n1_z100.tar.gz
if [ ! -e ${ics_file} ]; then
  echo "Downloading initial confitions file"
  wget -O ${ics_file} https://www.dropbox.com/scl/fi/51u6gksh6iq04ucjfrb7q/ics_256_n1_z100.tar.gz?rlkey=e4w6xv9rnee0ef4z4esma1rc7
else
  echo "Found initial confitions file: ${ics_file}"
fi

ics_dir=ics_256_n1_z100
if [ ! -e ${ics_dir} ]; then
  echo "Extracting initial confitions file"
  tar -xzvf ${ics_file}  
else
  echo "Found initial confitions directory: ${ics_dir}"
fi

#Create output dir
mkdir snapshot_files
