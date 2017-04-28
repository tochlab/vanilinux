#!/bin/bash
TOPDIR=`pwd`
BUILDDIR=`pwd`/build
OUTPUTDIR=`pwd`/output
SOURCEDIR=`pwd`/sources
RESULTDIR=`pwd`/result
mkdir -p $BUILDDIR
mkdir -p $OUTPUTDIR

function cleanup_builddir()
{
	echo -n Clean builddir... 
	rm -fr $BUILDDIR/*
	echo OK
}

function cleanup_outputdir()
{
    echo -n Clean output dir... 
    rm -fr $OUTPUTDIR/*
    echo OK
}

# == emptydirs
cd output
mkdir -pv {bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv {media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 root
install -dv -m 1777 tmp var/tmp
mkdir -pv usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  usr/libexec
mkdir -pv usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) mkdir -v /lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
tar cvfz $RESULTDIR/emptydirs-0-pkg.tar.gz .
cd $TOPDIR
cleanup_builddir
cleanup_outputdir

# == bash
BASHVERSION=4.3
cd build/
tar xvfz $SOURCEDIR/bash-$BASHVERSION.tar.gz
cd bash-$BASHVERSION
./configure --prefix=/usr --without-bash-malloc --with-installed-readline 
make -j 4
make DESTDIR=$OUTPUTDIR install
cd $OUTPUTDIR
mkdir -p bin
mv usr/bin/bash bin/
if [[ ! -e $OUTPUTDIR/bin/sh ]] ; then
        ln -sf bash "$OUTPUTDIR"/bin/sh
fi
tar cvfz $RESULTDIR/bash-$BASHVERSION-pkg.tar.gz .
cd $TOPDIR
cleanup_builddir
cleanup_outputdir