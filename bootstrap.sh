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
}

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