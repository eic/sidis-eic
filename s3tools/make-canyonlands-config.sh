#!/bin/bash

###################
# TOP-LEVEL SCRIPT to automate the creation of a config file for a specific release,
# supporting streaming or downloading from S3
# - the config file consists of file names (or URLs), with Q2 minima and cross sections
###################

# RELEASE TAG AND RECO DIR: ###########################
release="canyonlands-v2.0"
releaseDir="S3/eictest/ATHENA/RECO/$release/DIS/NC"
#######################################################

# usage:
if [ $# -ne 2 ]; then
  echo """
  USAGE: $0 [energy] [mode(d/s/c)]

   - [energy]: 5x41      | - see below for available datasets
               5x100     | - data from different Q2minima are combined,
               10x100    |   weighted by cross sections
               10x275
               18x275
               
   - [mode]:   s - make config file for streaming from S3
               d - download from S3, then make the local config file
               c - just make the local config file, for local files
               i - make config file for streaming from S3, but limit the
                   number of files included (e.g., for CI or tutorials)
   
   Examples: $0 5x41 d       # download
             $0 18x275 s     # stream

   See script for local and remote file path settings; they are
   configured for a specific set of data, but you may want to change
   them.

  CURRENT RELEASE: $release

  AVAILABLE DATA ON S3 (press ^C to abort S3 query):
  """
  mc tree $releaseDir
  exit 2
fi
energy=$1
mode=$2
pushd $(dirname $(realpath $0))/..

# settings #############################################################
sourceDir="$releaseDir/$energy"
targetDir="datarec/$release/$energy"
Q2minima=( 1000 100 10 1 ) # should be decreasing order
########################################################################

# download files from S3
function status { echo ""; echo "[+] $1"; }
if [ "$mode" == "d" ]; then
  status "downloading files from S3..."
  for Q2min in ${Q2minima[@]}; do
    s3tools/generate-s3-list.sh "$sourceDir/minQ2=$Q2min" | s3tools/download.sh "$targetDir/minQ2=$Q2min"
  done
fi

# build a config file
status "build config file..."
mkdir -p $targetDir
configFile=$targetDir/files.config
> $configFile
for Q2min in ${Q2minima[@]}; do
  crossSection=$(s3tools/read-xsec-table.sh $energy $Q2min)
  if [ "$mode" == "d" -o "$mode" == "c" ]; then
    s3tools/generate-local-list.sh "$targetDir/minQ2=$Q2min" 0 $crossSection $Q2min | tee -a $configFile
  elif [ "$mode" == "s" ]; then
    s3tools/generate-s3-list.sh    "$sourceDir/minQ2=$Q2min" 0 $crossSection $Q2min | tee -a $configFile
  elif [ "$mode" == "i" ]; then
    s3tools/generate-s3-list.sh    "$sourceDir/minQ2=$Q2min" 0 $crossSection $Q2min | head -n8 | tee -a $configFile
  else
    echo "ERROR: unknown mode"
    exit 1
  fi
done

# PATCH: convert config file to one-line-per-Q2min format
status "reformatting config file to one-line-per-Q2min format..."
mv -v $configFile{,.bak}
s3tools/reformat-config.sh $configFile{.bak,}

# output some info
status "files in target directory:"
tree $targetDir
popd
status "done building config file at:"
echo "     $configFile"
status "run root macros with parameters:"
echo "     '(\"$configFile\",$(echo $energy|sed 's/x/,/'))'"
