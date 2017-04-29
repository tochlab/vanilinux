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
    echo -n "Creating archive for $1 ... "
    cd $OUTPUTDIR
    find . -type f -executable -exec strip {} \;
    rm -f usr/share/info/dir
    tar cfz $RESULTDIR/$1.tgz .
    cd $TOPDIR
    echo "OK"
}

function extract_archive()
{
    echo -n "Exctracting $1 ... "
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

function build_gmp()
{
    GMPVERSION=6.1.0
    extract_archive gmp-$GMPVERSION.tar.xz

    cd $BUILDDIR/gmp-$GMPVERSION
    ./configure --prefix=/usr --enable-cxx --disable-static --docdir=/usr/share/doc/gmp
    make -j 4
    make html
    make DESTDIR=$OUTPUTDIR install
    make DESTDIR=$OUTPUTDIR install-html

    create_pkg gmp-$GMPVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_mpfr()
{
    MPFRVERSION=3.1.3
    extract_archive mpfr-$MPFRVERSION.tar.xz

    cd $BUILDDIR/mpfr-$MPFRVERSION
    ./configure --prefix=/usr --disable-static --enable-thread-safe --docdir=/usr/share/doc/mpfr

    make -j 4
    make html
    make DESTDIR=$OUTPUTDIR install
    make DESTDIR=$OUTPUTDIR install-html

    create_pkg mpfr-$MPFRVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_mpc()
{
    MPCRVERSION=1.0.2
    extract_archive mpc-$MPCRVERSION.tar.gz

    cd $BUILDDIR/mpc-$MPCRVERSION
    ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/mpc
    make -j 4
    make html
    make DESTDIR=$OUTPUTDIR install
    make DESTDIR=$OUTPUTDIR install-html

    create_pkg mpc-$MPCRVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_gcc()
{
    GCCVERSION=5.4.0
    extract_archive gcc-$GCCVERSION.tar.bz2

    cd $BUILDDIR/gcc-$GCCVERSION
    mkdir -v build
    cd build
    SED=sed
    ../configure --prefix=/usr --enable-languages=c,c++ --disable-multilib --disable-bootstrap --with-system-zlib
    make -j 8
    make DESTDIR=$OUTPUTDIR install

    cd $OUTPUTDIR
    mkdir -v lib
    #TODO this have to be without ..
    ln -sv ../usr/bin/cpp lib/cpp
    ln -sv gcc cc
    #mkdir -pv usr/share/gdb/auto-load/usr/lib
    #mv -v usr/lib/*gdb.py usr/share/gdb/auto-load/usr/lib

    create_pkg gcc-$GCCVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_bzip2()
{
    BZIPVERSION=1.0.6
    extract_archive bzip2-$BZIPVERSION.tar.gz

    cd $BUILDDIR/bzip2-$BZIPVERSION
    sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
    sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

    make -f Makefile-libbz2_so
    cd $OUTPUTDIR
    mkdir bin
    mkdir lib   
    cp -v $BUILDDIR/bzip2-$BZIPVERSION/bzip2-shared bin/bzip2
    cp -v $BUILDDIR/bzip2-$BZIPVERSION/libbz2.so.1.0.6 lib
    cd bin
    ln -s bzip2 bzcat
    ln -s bzip2 bunzip2
    cd ../lib/
    ln -s libbz2.so.1.0.6 libbz2.so
    cd $BUILDDIR/bzip2-$BZIPVERSION
    make clean
    make
    make PREFIX=$OUTPUTDIR/usr install
    rm -v $OUTPUTDIR/usr/bin/{bunzip2,bzcat,bzip2}

    create_pkg bzip2-$BZIPVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_pkg_config()
{
    PKGCONFIGVERSION=0.28
    extract_archive pkg-config-$PKGCONFIGVERSION.tar.gz

    cd $BUILDDIR/pkg-config-$PKGCONFIGVERSION
    ./configure --prefix=/usr --with-internal-glib --disable-compile-warnings --disable-host-tool --docdir=/usr/share/doc/pkg-config
    make -j 4
    make DESTDIR=$OUTPUTDIR install

    create_pkg pkg-config-$PKGCONFIGVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_ncurses()
{
    NCURSESVERSION=6.0
    extract_archive ncurses-$NCURSESVERSION.tar.gz

    cd $BUILDDIR/ncurses-$NCURSESVERSION
    sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
    ./configure --prefix=/usr \
    --mandir=/usr/share/man \
    --with-shared \
    --without-debug \
    --without-normal \
    --enable-pc-files \
    --enable-widec \
    --without-hashed-db \
    --with-cxx-shared \
    --enable-symlinks \
    --with-rcs-ids \
    --with-manpage-format=normal \
    --enable-const \
    --enable-colorfgbg \
    --enable-hard-tabs \
    --enable-echo
    make -j 4
    make DESTDIR=$OUTPUTDIR install

    mkdir $OUTPUTDIR/lib
    mv -v $OUTPUTDIR/usr/lib/libncursesw.so* $OUTPUTDIR/lib

    make distclean
    ./configure --prefix=/usr \
            --with-shared    \
            --without-normal \
            --without-debug  \
            --without-cxx-binding
    make sourses libs -j 4
    make DESTDIR=$OUTPUTDIR install

    mv -v $OUTPUTDIR/usr/lib/libncurses.so* $OUTPUTDIR/lib
    mv -v $OUTPUTDIR/usr/lib/libcurses.so* $OUTPUTDIR/lib
    
    create_pkg ncurses-$NCURSESVERSION
    
    cleanup_builddir
    cleanup_outputdir
}

function build_attr()
{
    ATTRVERSION=2.4.47
    extract_archive attr-$ATTRVERSION.src.tar.gz
    cd $BUILDDIR/attr-$ATTRVERSION
    # Modify the documentation directory so that it is a versioned directory
    sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
    # Prevent installation of manual pages that were already installed by the man pages package
    sed -i -e "/SUBDIRS/s|man[25]||g" man/Makefile
    ./configure --prefix=/usr --bindir=/bin --disable-static

    make
    make DESTDIR=$OUTPUTDIR install install-dev install-lib
    chmod -v 755 $OUTPUTDIR/usr/lib/libattr.so
    mkdir -p $OUTPUTDIR/lib
    mv -v $OUTPUTDIR/usr/lib/libattr.so.* $OUTPUTDIR/lib
    rm $OUTPUTDIR/usr/lib/libattr.so
    cd $OUTPUTDIR/lib
    ln -sfv libattr.so.1.1.0 libattr.so.1
    ln -sfv libattr.so.1 libattr.so

    create_pkg attr-$ATTRVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_acl()
{
    ACLVERSION=2.2.52
    extract_archive acl-$ACLVERSION.src.tar.gz

    cd $BUILDDIR/acl-$ACLVERSION
    # Modify the documentation directory so that it is a versioned directory
    sed -i -e 's|/@pkg_name@|&-@pkg_version@|' include/builddefs.in
    # Fix some broken tests
    sed -i "s:| sed.*::g" test/{sbits-restore,cp,misc}.test
    # Additionally, fix a bug that causes getfacl -e to segfault on overly long group name
    sed -i -e "/TABS-1;/a if (x > (TABS-1)) x = (TABS-1);" libacl/__acl_to_any_text.c
    ./configure --prefix=/usr --bindir=/bin --disable-static --libexecdir=/usr/lib

    make
    make DESTDIR=$OUTPUTDIR install install-dev install-lib
    chmod -v 755 $OUTPUTDIR/usr/lib/libacl.so
    mkdir -p $OUTPUTDIR/lib
    mv -v $OUTPUTDIR/usr/lib/libacl.so.* $OUTPUTDIR/lib
    rm $OUTPUTDIR/usr/lib/libacl.so
    cd $OUTPUTDIR/lib
    ln -sfv libacl.so.1.1.0 libacl.so.1
    ln -sfv libacl.so.1 libacl.so

    create_pkg acl-$ACLVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_libcap()
{
    LIBCAPVERSION=2.25
    extract_archive libcap-$LIBCAPVERSION.tar.xz

    cd $BUILDDIR/libcap-$LIBCAPVERSION
    sed -i '/install.*STALIBNAME/d' libcap/Makefile

    make
    make RAISE_SETFCAP=no lib=lib prefix=/usr DESTDIR=$OUTPUTDIR install
    chmod -v 755 $OUTPUTDIR/usr/lib/libcap.so
    mkdir $OUTPUTDIR/lib
    mv -v $OUTPUTDIR/usr/lib/libcap.so* $OUTPUTDIR/lib
    
    create_pkg libcap-$LIBCAPVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_sed()
{
    SEDVERSION=4.2.2
    extract_archive sed-$SEDVERSION.tar.bz2

    cd $BUILDDIR/sed-$SEDVERSION
    # First fix an issue in the LFS environment and remove a failing test
    sed -i 's/usr/tools/'       build-aux/help2man
    sed -i 's/panic-tests.sh//' Makefile.in

    ./configure --prefix=/usr --bindir=/bin
    make
    make html
    make DESTDIR=$OUTPUTDIR install
    install -d -m755 $OUTPUTDIR/usr/share/doc/sed-$SEDVERSION
    install -m644 doc/sed.html $OUTPUTDIR/usr/share/doc/sed-$SEDVERSION

    create_pkg sed-$SEDVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_shadow()
{
    SHADOWVERSION=4.4
    extract_archive shadow-$SHADOWVERSION.tar.gz

    cd $BUILDDIR/shadow-$SHADOWVERSION
    # Disable the installation of the groups program and its man pages,
    # as Coreutils provides a better version. Also Prevent the installation 
    # of manual pages that were already installed by the man pages package
    sed -i 's/groups$(EXEEXT) //' src/Makefile.in
    find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
    find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
    find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

    # CVE is a good reason not to be vanilla
    for p in `find $SOURCEDIR/ -name shadow-$SHADOWVERSION\*.patch` ; do
        patch -p 1 < $p
    done

    # Instead of using the default crypt method, use the more secure SHA-512
    # method of password encryption, which also allows passwords longer than 8
    # characters. It is also necessary to change the obsolete /var/spool/mail
    # location for user mailboxes that Shadow uses by default to the /var/mail
    # location used currently
    sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

    # Make a minor change to make the default useradd consistent with the LFS groups file:
    sed -i 's/1000/999/' etc/useradd
    # Fix a security issue identified upstream
    sed -i -e '47 d' -e '60,65 d' libmisc/myname.c

    ./configure --sysconfdir=/etc --without-group-name-max-length --without-tcb --enable-shared=no --enable-static=yes --enable-man
    make
    make DESTDIR=$OUTPUTDIR install
    mv -v $OUTPUTDIR/usr/bin/passwd $OUTPUTDIR/bin

    create_pkg shadow-$SHADOWVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_psmisc()
{
    PSMISCVERSION=22.21
    extract_archive psmisc-$PSMISCVERSION.tar.gz

    cd $BUILDDIR/psmisc-$PSMISCVERSION
    ./configure --prefix=/usr
    make
    make DESTDIR=$OUTPUTDIR install
    mkdir $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/fuser $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/killall $OUTPUTDIR/bin

    create_pkg psmisc-$PSMISCVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_m4()
{
    M4VERSION=1.4.17
    extract_archive m4-$M4VERSION.tar.xz

    cd $BUILDDIR/m4-$M4VERSION
    ./configure --prefix=/usr
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg m4-$M4VERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_bison()
{
    BISONVERSION=3.0.4
    extract_archive bison-$BISONVERSION.tar.xz

    cd $BUILDDIR/bison-$BISONVERSION
    ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg bison-$BISONVERSION
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
#build_binutils
#build_gmp
#build_mpfr
#build_mpc
#build_gcc
#build_bzip2
#build_pkg_config
#build_ncurses
#build_attr
#build_acl
#build_libcap
#build_sed
#build_shadow
#build_psmisc
#build_m4
build_bison