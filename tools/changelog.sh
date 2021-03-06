#!/bin/sh

# Exports
dir=$ANDROID_BUILD_TOP
out=$dir/out/target/product

export Changelog=$PWD/Changelog.txt
export MANIFEST="${TOP}/.repo/manifests/snippets/bootleggers.xml"

if [ -f $Changelog ];
then
	rm -f $Changelog
fi

touch $Changelog

# Build a list of all repos
PROJECTPATHS=$(grep "<project" "${MANIFEST}" | sed -n 's/.*path="\([^"]\+\)".*/\1/p')

# Add repos in local manifest for DT changelog
for lManifest in $TOP/.repo/local_manifests/*; do
	PROJECTPATHS+=" $(grep "<project" "${lManifest}" | sed -n 's/.*path="\([^"]\+\)".*/\1/p')"
done

# Print something to build output
echo ${bldppl}"Generating changelog..."${txtrst}

for i in $(seq 15);
do
export After_Date=`date --date="$i days ago" +%F`
k=$(expr $i - 1)
export Until_Date=`date --date="$k days ago" +%F`

	# Line with after --- until was too long for a small ListView
	echo '====================' >> $Changelog;
	echo "     "$Until_Date     >> $Changelog;
	echo '====================' >> $Changelog;
	echo >> $Changelog;
	
	# Cycle through every repo to find commits between 2 dates
	for PROJECTPATH in ${PROJECTPATHS}; do
		[ ! -d "$TOP/$PROJECTPATH" ] && continue
		cd "${TOP}/$PROJECTPATH"
		if ! [[ -z $(git log --after=$After_Date --until=$Until_Date) ]]; then # only echo if there is a change
			echo "[${PROJECTPATH}]" >> $Changelog
			git log --after=$After_Date --until=$Until_Date --pretty=tformat:"%h  %s  [%an]" --abbrev-commit --abbrev=7 >> $Changelog
			echo >> $Changelog
		fi
	done
echo "" >> $Changelog;
done

sed -i 's/project/ */g' $Changelog
sed -i 's/[/]$//' $Changelog

if [ -e $out/*/$Changelog ]
then
rm $out/*/$Changelog
fi
if [ -e $out/*/system/etc/$Changelog ]
then
rm $out/*/system/etc/$Changelog
fi
cp $Changelog $OUT/system/etc/
cp $Changelog $OUT/
rm $Changelog
