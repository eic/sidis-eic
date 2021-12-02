#!/bin/bash
# organize artifacts by combining directories from different recon methods
# - execute in CI pipelines from top-level directory, after all artifacts
#   have been collected into one directory, specified by argument
# - execute before merging fast and fullsim results

# arguments
if [ $# -ne 2 ]; then echo "USAGE: $0 [artifacts-dir] [search-string (e.g., pname or aname)]"; exit 2; fi
pushd $1

# merge recon-* directories, adding recon method to suffix
echo "------------- merge recon methods -------------------"
# loop through recon* directories
ls | grep "$2" |\
while read dirRecon; do
  method=$(echo $dirRecon | sed 's/^.*_//g')
  dirOut=$(echo $dirRecon | sed "s/_$method/_with_recons/g")
  echo "MOVE ARTIFACTS IN $dirRecon/ FOR METHOD \"$method\" TO $dirOut/"
  mkdir -p $dirOut
  pushd $dirRecon
  mv -v *.images/* ./; rm -r *.images
  for file in *; do
    mv -v $file ../$dirOut/$(echo $file | sed "s/^.*\./&$method./g")
  done
  popd
  rm -r $dirRecon
done


############
popd
