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

function extract_archive()
{
    echo -n "Exctracting $1 ... ""
    tar -xf $SOURCEDIR/$1 -C $BUILDDIR
    echo "OK"
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

    mkdir -v var/{log,mail,spool}
    ln -sv run var/run
    ln -sv run/lock var/lock
    mkdir -pv var/{opt,cache,lib/{color,misc,locate},local}

    create_pkg emptydirs-0
    cleanup_builddir
    cleanup_outputdir
}

function build_bash()
{
    BASHVERSION=4.3
    extract_archive bash-$BASHVERSION.tar.gz

    cd $BUILDDIR/bash-$BASHVERSION
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
    LINUXVERSION=4.9.25
    extract_archive linux-$LINUXVERSION.tar.xz

    cd $BUILDDIR/linux-$LINUXVERSION
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
    extract_archive man-pages-$MANVERSION.tar.xz

    cd $BUILDDIR/man-pages-$MANVERSION
    make DESTDIR=$OUTPUTDIR/ install

    create_pkg man-pages-$MANVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_glibc()
{
    GLIBCVERSION=2.23
    extract_archive glibc-$GLIBCVERSION.tar.xz

    cd $BUILDDIR/glibc-$GLIBCVERSION
    mkdir -v build
    cd build
    ../configure --prefix=/usr --enable-kernel=2.6.32 --enable-obsolete-rpc --enable-stack-protector=strong libc_cv_slibdir=/lib
    make -j 4
    make check
    touch $OUTPUTDIR/etc/ld.so.conf
    make DESTDIR=$OUTPUTDIR install
    cp -v ../nscd/nscd.conf $OUTPUTDIR/etc/nscd.conf
    mkdir -pv $OUTPUTDIR/var/cache/nscd
    echo /usr/local/lib > $OUTPUTDIR/etc/ld.so.conf
    echo /opt/lib >> $OUTPUTDIR/etc/ld.so.conf

    create_pkg glibc-$GLIBCVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_zlib()
{
    ZLIBVERSION=1.2.11
    extract_archive zlib-$ZLIBVERSION.tar.gz

    cd $BUILDDIR/zlib-$ZLIBVERSION
    ./configure --prefix=/usr
    make -j 4
    make DESTDIR=$OUTPUTDIR install
    cd $OUTPUTDIR
    mkdir lib
    mv -v usr/lib/libz.so.* lib
    #TODO CHECK THIS LINKING
    ln -sfv lib/libz.so usr/lib/libz.so

    create_pkg zlib-$ZLIBVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_file()
{
    FILEVERSION=5.29
    extract_archive file-$FILEVERSION.tar.gz

    cd $BUILDDIR/file-$FILEVERSION
    ./configure --prefix=/usr
    make -j 4
    make DESTDIR=$OUTPUTDIR install

    create_pkg file-$FILEVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_binutils()
{
    BINUTILSVERSION=2.27
    extract_archive binutils-$BINUTILSVERSION.tar.bz2

    cd $BUILDDIR/binutils-$BINUTILSVERSION
    mkdir -v build
    cd build
    ../configure --prefix=/usr --enable-gold --enable-ld=default --enable-plugins --enable-shared --disable-werror --with-system-zlib
    make -j 4
    make DESTDIR=$OUTPUTDIR install

    create_pkg binutils-$BINUTILSVERSION
    cleanup_builddir
    cleanup_outputdir
}

#build_emptydirs
#build_linuxheaders
#build_bash
#build_manpages
#build_glibc
#build_zlib
#build_file
build_binutils