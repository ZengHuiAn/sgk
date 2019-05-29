#!/bin/bash

FROM="$1"
TO="$2"
PLATFORM="$3"

TAG=`git describe --tags --abbrev=0`
if [ "$TO" == "" ]
then
	TO=`git log -1 --pretty=format:%h`
fi
if [ "$FROM" == "" ]
then
	FROM=$TAG
fi
if [ "$PLATFORM" == "" ]
then
	PLATFORM="Android"
fi

ASSET=${FROM}_to_${TO}
ASSET_O=$ASSET/o;
ASSET_N=$ASSET/n;
ASSET_P=$ASSET/p;
DIR="AssetBundles/"${PLATFORM}

echo ""
echo "$DIR"
echo "'$FROM' build '$TO'"
echo "$ASSET"
echo ""

rm -rf $ASSET
rm -rf $ASSET_O;
rm -rf $ASSET_N;
rm -rf $ASSET_P;
mkdir $ASSET
mkdir $ASSET_O;
mkdir $ASSET_N;
mkdir $ASSET_P;

echo $FROM $TO
echo $DIR

PatchFiles=patch_file;
rm -rfv $PatchFiles;
git diff --name-only $FROM $TO -- $DIR | while read file
do
	if [ ! -f "$file" ]
	then
		continue;
	fi
	
	if [ "${file##*.}" == "manifest" ]
	then
		continue;
	fi	

	nfile=${file:${#DIR}}
	mkdir -pv `dirname ${ASSET_O}$nfile`
	mkdir -pv `dirname ${ASSET_N}$nfile`
	mkdir -pv `dirname ${ASSET_P}$nfile`

	echo $nfile >> $PatchFiles;
	cp -rf "$file" "${ASSET_N}$nfile" || exit
	git checkout $FROM $file && (cp -rf "$file" "${ASSET_O}$nfile") 
	echo `git reset HEAD $file` > a
	git checkout HEAD $file
done

if [ ! -f "$PatchFiles"  ]
then
	echo "Not need to update!!!" ${#Files[@]}
	echo "Exit"
	rm -rf $ASSET
	rm -rf $ASSET_O;
	rm -rf $ASSET_N;
	rm -rf $ASSET_P;
	exit
fi

cat $PatchFiles | while read file
do
	# bsdiff: usage: bsdiff oldfile newfile patchfile
	if [ ! -f "${ASSET_O}/$file" ]
	then
		cp ${ASSET_N}/$file ${ASSET_P}/$file
	else	
		bsdiff ${ASSET_O}/$file ${ASSET_N}/$file ${ASSET_P}/$file".patch"; 
	fi
done

cd ${ASSET_P}
zipfile=$ASSET.d
zip -r $zipfile . 
cd ../../
if [ ! -d "patch" ]
then
	mkdir "patch"
fi

mv "${ASSET_P}/$zipfile" "patch"

SIZE=`ls -l "patch/$zipfile" | awk '{print $5}'`

echo ""
echo "array_push(\$patchs, array('file' => '$zipfile', 'crc' => 0, 'version' => '$TO', 'size' => $SIZE, 'force' => 0));"
echo ""

