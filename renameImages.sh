#!/bin/sh

if [ ! -d "namedImages" ]; then
    mkdir namedImages
fi

maxFiles=$(ls before | nl | tail -n 1 | awk '{ print $1 }')
numDigits=1
while [ $maxFiles -gt 9 ]
do
    ((maxFiles/=10))
    ((numDigits++))
done

numImages=1
IMAGE_FILES=before/*
for f in $IMAGE_FILES
do

    # Strip the path
    file=$(basename "$f")
    fileDate=$(echo $file | sed -n 's/\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\).*/_\1.\2.\3/p')

    formatPrefix="%0"
    gPostfix="g"
    format=$formatPrefix$numDigits$gPostfix
    jpeg=".jpg"
    formattedNumImages=$(seq -f "$format" $numImages $numImages)
    newFileName=$formattedNumImages$fileDate$jpeg

    # Write the new file
    echo "$f  ->  namedImages/$newFileName"
    cp $f namedImages/$newFileName

    ((numImages++))
done
