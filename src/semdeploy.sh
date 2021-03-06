#!/bin/sh
SEMABUILD_PWD=`pwd`
SEMABUILD_BUILD="${HOME}/deploy"
SEMABUILD_SCP='scp -BC -o StrictHostKeyChecking=no'
SEMABUILD_TARGET='qreeves@icculus.org:/webspace/redeclipse.net/files'
SEMABUILD_APT='DEBIAN_FRONTEND=noninteractive apt-get'
SEMABUILD_MODULES=`curl --silent --fail http://redeclipse.net/files/stable/mods.txt` || exit 1
SEMABUILD_ALLMODS="base ${SEMABUILD_MODULES}"

sudo ${SEMABUILD_APT} update || exit 1
sudo ${SEMABUILD_APT} -fy install build-essential unzip zip nsis nsis-common mktorrent || exit 1

rm -rf "${SEMABUILD_BUILD}"
rm -rf "${SEMABUILD_PWD}/data"
mkdir -pv "${SEMABUILD_BUILD}" || exit 1

for i in ${SEMABUILD_ALLMODS}; do
    if [ "${i}" = "base" ]; then
        SEMABUILD_MODDIR="${SEMABUILD_BUILD}"
        SEMABUILD_GITDIR="${SEMABUILD_PWD}"
        SEMABUILD_ARCHBR="stable"
    else
        SEMABUILD_MODDIR="${SEMABUILD_BUILD}/data/${i}"
        SEMABUILD_GITDIR="${SEMABUILD_PWD}/data/${i}"
        SEMABUILD_ARCHBR="master"
        git submodule init "data/${i}"
        git submodule update "data/${i}"
    fi
    mkdir -pv "${SEMABUILD_MODDIR}" || exit 1
    pushd "${SEMABUILD_GITDIR}" || exit 1
    (git archive ${SEMABUILD_ARCHBR} | tar -x -C "${SEMABUILD_MODDIR}") || exit 1
    popd
done

pushd "${SEMABUILD_BUILD}/src" || exit 1
make dist dist-torrents || exit 1
popd

pushd "${SEMABUILD_BUILD}" || exit 1
mkdir -p releases || exit 1
mv -vf redeclipse_*.*_*.tar.bz2 releases/ || exit 1
mv -vf redeclipse_*.*_*.exe releases/ || exit 1
mv -vf redeclipse_*.*_*.torrent releases/ || exit 1
pushd "${SEMABUILD_BUILD}/releases"
for i in redeclipse_*.*; do
    shasum "${i}" > "${i}.shasum"
    md5sum "${i}" > "${i}.md5sum"
done
popd
${SEMABUILD_SCP} -r "releases" "${SEMABUILD_TARGET}" || exit 1
popd
