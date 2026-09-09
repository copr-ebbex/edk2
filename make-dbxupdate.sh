#!/bin/sh

# https://github.com/microsoft/secureboot_objects.git
sbrepo="$HOME/projects/secureboot"

dbxdir="PostSignedObjects/SignedByKEK2023"
srcdir="${sbrepo}/${dbxdir}"

test -d "$srcdir" || exit 1

echo "#"
echo "# pull repo updates"
(set -x; cd "$sbrepo"; git pull)
commit=$(cd "$sbrepo"; git log --oneline -n 1 --pretty='format:%h' -- $dbxdir)
latest=$(cd "$sbrepo"; git log --oneline -n 1 --pretty='format:%cs.2023' -- $dbxdir | tr -d '-')
version=$(cd "$sbrepo"; git describe --tags --long --match 'v*' | cut -d- -f1)
current=$(awk '/%define DBXDATE_2023/ { print $3 }' edk2.spec)
if test "$current" = "$latest"; then
    echo "#"
    echo "# no update needed ($latest, $version)"
    echo "#"
    exit 0
fi

echo "#"
echo "# need dbx update"
echo "#   current : $current"
echo "#   latest  : $latest ($version)"

echo "#"
echo "# copy updates"
cp -v "${srcdir}/dbx_ia32.efiauth2" "DBXUpdate-${latest}.ia32.bin"
cp -v "${srcdir}/dbx_x64.efiauth2" "DBXUpdate-${latest}.x64.bin"
cp -v "${srcdir}/dbx_aarch64.efiauth2" "DBXUpdate-${latest}.aa64.bin"

echo "#"
echo "# update specfile and git"
sed -e "/%define DBXDATE_2023/s/ 20.*/ $latest/" -i edk2.spec
git add DBXUpdate-${latest}.*.bin
git add edk2.spec
git commit -m "update dbx to $latest ($version)"

echo "#"
echo "# show update commit"
git show
