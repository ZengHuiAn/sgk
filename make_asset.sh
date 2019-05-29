#!/bin/bash

TO=$1;
if [ "$TO" == "" ]
then
	TO=`git describe --tags  --abbrev=0`
fi
PLATFORM=$2
if [ "$PLATFORM" == "" ]
then
	PLATFORM="Android"
fi

/Applications/Unity/Unity.app/Contents/MacOS/Unity -nographics -accept-apiupdate -batchmode -projectPath `pwd` -quit -logFile /dev/stdout -executeMethod BuildPackageShell.MakeAssetBundleAndroid 

echo $TO > Assets/Resources/AssetVersion.txt
