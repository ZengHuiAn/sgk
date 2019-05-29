#!/bin/bash

rm -rf Assets/XLua/Gen Assets/XLua/Gen.meta
rm -rf Assets/assetbundle/Lua Assets/assetbundle/Lua.meta

rm -f Assets/StreamingAssets/Android Assets/StreamingAssets/Android.meta
rm -rf Assets/StreamingAssets/assetbundle Assets/StreamingAssets/assetbundle.meta

export ANDROID_HOME=/opt/sdk/
export UNITY_CACHE_SERVER=10.1.1.23:8126

mkdir -pv build

git fetch -ap --tags

PLATFORM="Android"
GIT_HASH=`git log -1 --pretty=format:%h`
DESCRIBE=`git describe --tags`
VERSION=`git describe --tags  --abbrev=0`

if [ -f "last" ]
then
	LAST=`cat last | sed 's///g'`
	if [ "$LAST" == "$GIT_HASH" ]
	then
		echo "finished"
		exit
	fi
fi

echo "$GIT_HASH" > last


CLIENT_TAG="test"

#rm AssetBundles
#mkdir -p AssetBundles_${CLIENT_TAG}
#ln -svf AssetBundles_${CLIENT_TAG} AssetBundles 

if [ "$CLIENT_TAG" != "test" ]
then
	rm -f	Assets/Plugins/Android/AndroidManifest.xml Assets/Plugins/Android/AndroidManifest.xml.meta
fi

sed -i "" "s/bundleVersion: ..*$/bundleVersion: $VERSION/g"  ProjectSettings/ProjectSettings.asset

echo "game_url = http://ndss.cosyjoy.com/sgk/" > Assets/config.txt
echo "# announcement_url = " >> Assets/config.txt
echo "client_tag = $CLIENT_TAG" >> Assets/config.txt
echo "svn_version = $GIT_HASH" >> Assets/config.txt

UNITY="/Applications/Unity/Unity.app/Contents/MacOS/Unity -nographics -accept-apiupdate -batchmode -projectPath `pwd` -quit -logFile /dev/stdout -executeMethod "

#PPP=" | tree unity.log"
PPP=""
M_MakeAssetBundle=${UNITY}" BuildPackageShell.MakeAssetBundle"$PLATFORM${PPP}
M_MakePackage=${UNITY}" BuildPackageShell.MakePackage"$PLATFORM${PPP}

# eval $M_MakeAssetBundle;
./make_asset.sh $VERSION
eval $M_MakePackage;

TIEMSTAMP=`stat -f "%m" build/sgk.apk`
BUILD_TIME=`date -r ${TIEMSTAMP}  +"%Y%m%d%H%M%S"`
MODIFY_TIME=`date -r ${TIEMSTAMP}  +"%Y-%m-%d %H:%M:%S"`

MD5=`/sbin/md5 -q build/sgk.apk`

exit

echo "<center><H1>守墓人android包</H1></center>" > index.html
echo "<br/>" >> index.html
echo "<center>文件名:sgk_${VERSION}_${BUILD_TIME}.apk</center>" >> index.html
echo "<br/>" >> index.html
echo "<center>打包时间: ${MODIFY_TIME}</center>" >> index.html
echo "<br/>" >> index.html
echo "<center>MD5: ${MD5}</center>" >> index.html
echo "<br/>" >> index.html
echo "<center>客户端版本号: ${VERSION}</center>" >> index.html
echo "<br/>" >> index.html
echo "<center>SVN版本号: ${GIT_HASH}</center>" >> index.html
echo "<br/>" >> index.html
echo "<center><a href=\"sgk.apk\" download=\"sgk_${VERSION}_${BUILD_TIME}.apk\">&nbsp&nbsp&nbsp&nbsp下&nbsp载&nbsp&nbsp&nbsp&nbsp</a></center>" >> index.html

scp build/sgk.apk rexzhao@10.1.2.22:/usr/local/nginx/html/sgk/sgk_oohhoo_${VERSION}.apk

# scp build/sgk.apk rexzhao@10.1.2.22:/usr/local/nginx/html/sgk/sgk.apk
# scp index.html rexzhao@10.1.2.22:/usr/local/nginx/html/sgk/index_client.html
