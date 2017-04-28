#!/bin/bash
TOPDIR=`pwd`
BUILDDIR=`pwd`/build
OUTPUTDIR=`pwd`/output
SOURCEDIR=`pwd`/sources
RESULTDIR=`pwd`/result
mkdir -p $BUILDDIR
mkdir -p $OUTPUTDIR
mkdir -p $RESULTDIR

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

function create_pkg()
{
    cd $OUTPUTDIR
    tar cvfz $RESULTDIR/$1-pkg.tar.gz .
    cd $TOPDIR
}

function build_emptydirs()
{
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

    create_pkg emptydirs-0
    cleanup_builddir
    cleanup_outputdir
}

function build_bash()
{
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

    create_pkg bash-$BASHVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_linuxheaders()
{
    # == linux
    LINUXVERSION=4.9.25
    cd build/
    tar xvfJ $SOURCEDIR/linux-$LINUXVERSION.tar.xz
    cd linux-$LINUXVERSION
    make mrproper
    make INSTALL_HDR_PATH=dest headers_install
    find dest/include \( -name .install -o -name ..install.cmd \) -delete
    mkdir -p $OUTPUTDIR/include
    cp -rv dest/include/* $OUTPUTDIR/include

    create_pkg linux-headers-$LINUXVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_manpages()
{
    MANVERSION=4.09
    cd build/
    tar xvfJ $SOURCEDIR/man-pages-$MANVERSION.tar.xz
    cd man-pages-$MANVERSION
    make DESTDIR=$OUTPUTDIR/ install

    create_pkg man-pages-$MANVERSION
    cleanup_builddir
    cleanup_outputdir
}

#build_emptydirs
#build_linuxheaders
build_bash
#build_manpages