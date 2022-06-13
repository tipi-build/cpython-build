#!/bin/bash

# Patches all the *.so files that do have a 
echo "Patching python *.so files at least 2 levels deep under $1"
cd $1

find . -mindepth 2 -name "*.so" | while read sofile; do

    # return code == = only if there's an RPATH defined
    chrpath --list $sofile 

    if [ $? -eq 0 ]
    then
        rel_path=$(realpath --relative-to=$sofile ./lib)
        new_runpath="\$ORIGIN/$rel_path/lib:\$ORIGIN"
        chrpath --replace $new_runpath $sofile 1> /dev/null 
    fi

done