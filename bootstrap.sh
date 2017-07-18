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
    cd $OUTPUTDIR
    mkdir -pv $OUTPUTDIR/{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
    mkdir -pv $OUTPUTDIR/{media/{floppy,cdrom},sbin,srv,var}
    install -dv -m 0750 root
    install -dv -m 1777 tmp var/tmp
    mkdir -pv $OUTPUTDIR/usr/{,local/}{bin,include,lib,sbin,src}
    mkdir -pv $OUTPUTDIR/usr/{,local/}share/{color,dict,doc,info,locale,man}
    mkdir -v  $OUTPUTDIR/usr/{,local/}share/{misc,terminfo,zoneinfo}
    mkdir -v  $OUTPUTDIR/usr/libexec
    mkdir -pv $OUTPUTDIR/usr/{,local/}share/man/man{1..8}

    case $(uname -m) in
    x86_64) mkdir -v $OUTPUTDIR/lib64 ;;
    esac

    mkdir -v $OUTPUTDIR/var/{log,mail,spool}
    ln -sv run var/run
    ln -sv run/lock var/lock
    mkdir -pv $OUTPUTDIR/var/{opt,cache,lib/{color,misc,locate},local}

    create_pkg emptydirs-0
    cleanup_builddir
    cleanup_outputdir
}

function build_bash()
{
    BASHVERSION=4.3
    extract_archive bash-$BASHVERSION.tar.gz

    cd $BUILDDIR/bash-$BASHVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --without-bash-malloc --with-installed-readline 
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
    mkdir -p $OUTPUTDIR/usr/include
    cp -rv dest/include/* $OUTPUTDIR/usr/include

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
    CC=clang CXX=clang++ ./configure --prefix=/usr
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
    CC=clang CXX=clang++ ./configure --prefix=/usr
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
    CC=clang CXX=clang++ ../configure --prefix=/usr --enable-gold --enable-ld=default --enable-plugins --enable-shared --disable-werror --with-system-zlib
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
    CC=clang CXX=clang++ ./configure --prefix=/usr --enable-cxx --disable-static --docdir=/usr/share/doc/gmp
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
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static --enable-thread-safe --docdir=/usr/share/doc/mpfr

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
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/mpc
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
    CC=clang CXX=clang++ ../configure --prefix=/usr --enable-languages=c,c++ --disable-multilib --disable-bootstrap --with-system-zlib
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
    CC=clang CXX=clang++ ./configure --prefix=/usr --with-internal-glib --disable-compile-warnings --disable-host-tool --docdir=/usr/share/doc/pkg-config
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
    CC=clang CXX=clang++ ./configure --prefix=/usr \
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
    CC=clang CXX=clang++ ./configure --prefix=/usr \
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
    CC=clang CXX=clang++ ./configure --prefix=/usr --bindir=/bin --disable-static

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
    CC=clang CXX=clang++ ./configure --prefix=/usr --bindir=/bin --disable-static --libexecdir=/usr/lib

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

    CC=clang CXX=clang++ ./configure --prefix=/usr --bindir=/bin
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

    CC=clang CXX=clang++ ./configure --sysconfdir=/etc --without-group-name-max-length --without-tcb --enable-shared=no --enable-static=yes --enable-man
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
    CC=clang CXX=clang++ ./configure --prefix=/usr
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
    CC=clang CXX=clang++ ./configure --prefix=/usr
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
    CC=clang CXX=clang++ ./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.0.4
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg bison-$BISONVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_flex()
{
    FLEXVERSION=2.6.1
    extract_archive flex-$FLEXVERSION.tar.xz

    cd $BUILDDIR/flex-$FLEXVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --docdir=/usr/share/doc/flex-$FLEXVERSION
    make
    make DESTDIR=$OUTPUTDIR install
    cd $OUTPUTDIR/usr/bin
    ln -sf flex lex

    create_pkg flex-$FLEXVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_grep()
{
    GREPVERSION=2.27
    extract_archive grep-$GREPVERSION.tar.xz

    cd $BUILDDIR/grep-$GREPVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --bindir=/bin
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg grep-$GREPVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_readline()
{
    READLINEVERION=6.3
    extract_archive readline-$READLINEVERION.tar.gz

    cd $BUILDDIR/readline-$READLINEVERION
    # Reinstalling Readline will cause the old libraries to be
    # moved to <libraryname>.old. While this is normally not a
    # problem, in some cases it can trigger a linking bug in 
    # ldconfig. This can be avoided by issuing the following two seds
    sed -i '/MV.*old/d' Makefile.in
    sed -i '/{OLDSUFF}/c:' support/shlib-install
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/readline-$READLINEVERION
    make SHLIB_LIBS=-lncurses
    make SHLIB_LIBS=-lncurses DESTDIR=$OUTPUTDIR install
    mkdir -vp $OUTPUTDIR/lib
    mv -v $OUTPUTDIR/usr/lib/lib{readline,history}.so* $OUTPUTDIR/lib
    rmdir -v $OUTPUTDIR/usr/lib
    rmdir -v $OUTPUTDIR/usr/bin

    create_pkg realine-$READLINEVERION
    cleanup_builddir
    cleanup_outputdir
}

function build_bc()
{
    BCVERSION=1.06.95
    extract_archive bc-$BCVERSION.tar.bz2

    cd $BUILDDIR/bc-$BCVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --with-readline --mandir=/usr/share/man --infodir=/usr/share/info
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg bc-$BCVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_libtool()
{
    LIBTOOLVERSION=2.4.6
    extract_archive libtool-$LIBTOOLVERSION.tar.xz

    cd $BUILDDIR/libtool-$LIBTOOLVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg libtool-$LIBTOOLVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_gdbm()
{
    GDBMVERSION=1.11
    extract_archive gdbm-$GDBMVERSION.tar.gz

    cd $BUILDDIR/gdbm-$GDBMVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static --enable-libgdbm-compat
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg gdbm-$GDBMVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_gperf()
{
    GPERFVERSION=3.0.4
    extract_archive gperf-$GPERFVERSION.tar.gz

    cd $BUILDDIR/gperf-$GPERFVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-$GPERFVERSION
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg gperf-$GPERFVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_expat()
{
    EXPATVERSION=2.2.0
    extract_archive expat-$EXPATVERSION.tar.bz2

    cd $BUILDDIR/expat-$EXPATVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static
    make
    make DESTDIR=$OUTPUTDIR install
    #If desired, install the documentation: 
    #install -v -dm755 /usr/share/doc/expat-2.2.0
    #install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.0
    
    create_pkg expat-$EXPATVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_inetutils()
{
    INETUTILSVERSION=1.9.4
    extract_archive inetutils-$INETUTILSVERSION.tar.gz

    cd $BUILDDIR/inetutils-$INETUTILSVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --localstatedir=/var --disable-logger --disable-whois --disable-rcp --disable-rexec --disable-rlogin --disable-rsh --disable-servers
    make
    make DESTDIR=$OUTPUTDIR install
    mkdir -v $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/{hostname,ping,ping6,traceroute} $OUTPUTDIR/bin
    mkdir -v $OUTPUTDIR/sbin
    mv -v $OUTPUTDIR/usr/bin/ifconfig $OUTPUTDIR/sbin
    rmdir $OUTPUTDIR/usr/libexec
    # Strange. Its not executable after install
    chmod +x $OUTPUTDIR/bin/*

    create_pkg inetutils-$INETUTILSVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_perl()
{
    PERLVERSION=5.24.1
    extract_archive perl-$PERLVERSION.tar.xz

    cd $BUILDDIR/perl-$PERLVERSION
    export BUILD_ZLIB=False
    export BUILD_BZIP2=0
    export CC=clang
    export CXX=clang++ 
    sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib

    make -j 4
    make DESTDIR=$OUTPUTDIR install
    unset BUILD_ZLIB BUILD_BZIP2

    create_pkg perl-$PERLVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_perl_xmlparser()
{
    XMLPARSERVERSION=2.44
    extract_archive XML-Parser-$XMLPARSERVERSION.tar.gz

    cd $BUILDDIR/XML-Parser-$XMLPARSERVERSION
    perl Makefile.PL
    make
    make DESTDIR=$OUTPUTDIR install
    # Strange files in usr/local/
    create_pkg XML-Parser-$XMLPARSERVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_intltool()
{
    INTLTOOLVERSION=0.51.0
    extract_archive intltool-$INTLTOOLVERSION.tar.gz

    cd $BUILDDIR/intltool-$INTLTOOLVERSION
    sed -i 's:\\\${:\\\$\\{:' intltool-update.in
    CC=clang CXX=clang++ ./configure --prefix=/usr
    make
    make DESTDIR=$OUTPUTDIR install
    install -v -Dm644 $BUILDIR/doc/I18N-HOWTO $OUTPUTDIR/usr/share/doc/intltool-$INTLTOOLVERSION/I18N-HOWTO

    create_pkg intltool-$INTLTOOLVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_autoconf()
{
    AUTOCONFVERSION=2.69
    extract_archive autoconf-$AUTOCONFVERSION.tar.xz

    cd $BUILDDIR/autoconf-$AUTOCONFVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr
    make -j 4
    make DESTDIR=$OUTPUTDIR install

    create_pkg autoconf-$AUTOCONFVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_automake()
{
    AUTOMAKEVERSION=1.15
    extract_archive automake-$AUTOMAKEVERSION.tar.xz

    cd $BUILDDIR/automake-$AUTOMAKEVERSION
    sed -i 's:/\\\${:/\\\$\\{:' bin/automake.in
    CC=clang CXX=clang++ ./configure --prefix=/usr --docdir=/usr/share/doc/automake-$AUTOMAKEVERSION
    make
    make DESTDIR=$OUTPUTDIR install

    create_pkg automake-$AUTOMAKEVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_xz()
{
    XZVERSION=5.2.3
    extract_archive xz-$XZVERSION.tar.gz

    cd $BUILDDIR/xz-$XZVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/xz-$XZVERSION
    make
    make DESTDIR=$OUTPUTDIR install
    mkdir -v $OUTPUTDIR/lib $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/lib/liblzma.so* $OUTPUTDIR/lib
    cd $OUTPUTDIR
    # TODO
    #ln -svf lib/liblzma.so usr/lib/liblzma.so

    create_pkg xz-$XZVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_kmod()
{
    KMODVERSION=23
    extract_archive kmod-$KMODVERSION.tar.xz

    cd $BUILDDIR/kmod-$KMODVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --bindir=/bin --sysconfdir=/etc --with-rootlibdir=/lib --with-xz --with-zlib
    make
    make DESTDIR=$OUTPUTDIR install
    cd $OUTPUTDIR/bin
    mkdir $OUTPUTDIR/sbin
    for target in depmod insmod lsmod modinfo modprobe rmmod; do
        ln -sfv ../bin/kmod ../sbin/$target
    done

    ln -sfv kmod lsmod

    create_pkg kmod-$KMODVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_gettext()
{
    GETTEXTVERSION=0.19.8.1
    extract_archive gettext-$GETTEXTVERSION.tar.gz

    cd $BUILDDIR/gettext-$GETTEXTVERSION
    sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
    sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in
    CC=clang CXX=clang++ ./configure --prefix=/usr --disable-static --docdir=/usr/share/doc/gettext-$GETTEXTVERSION
    make
    make DESTDIR=$OUTPUTDIR install
    chmod -v 0755 $OUTPUTDIR/usr/lib/preloadable_libintl.so

    create_pkg gettext-$GETTEXTVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_procpsng()
{
    PROCPSNGVERSION=3.3.12
    extract_archive procps-ng-$PROCPSNGVERSION.tar.xz

    cd $BUILDDIR/procps-ng-$PROCPSNGVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --exec-prefix= --libdir=/usr/lib --docdir=/usr/share/doc/procps-ng-$PROCPSNGVERSION --disable-static --disable-kill
    make
    make DESTDIR=$OUTPUTDIR install
    mv -v $OUTPUTDIR/usr/lib/libprocps.so* $OUTPUTDIR/lib

    create_pkg procps-ng-$PROCPSNGVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_e2fsprogs()
{
    E2FSPROGSVERSION=1.43.3
    extract_archive e2fsprogs-$E2FSPROGSVERSION.tar.gz

    cd $BUILDDIR/e2fsprogs-$E2FSPROGSVERSION
    mkdir -v build
    cd build
    CC=clang CXX=clang++ ../configure --prefix=/usr --bindir=/bin --with-root-prefix="" --enable-elf-shlibs --disable-libblkid --disable-libuuid --disable-uuidd --disable-fsck
    make
    make DESTDIR=$OUTPUTDIR install
    make DESTDIR=$OUTPUTDIR install-libs
    chmod -v u+w $OUTPUTDIR/usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
    gunzip -v $OUTPUTDIR/usr/share/info/libext2fs.info.gz
    install-info --dir-file=$OUTPUTDIR/usr/share/info/dir $OUTPUTDIR/usr/share/info/libext2fs.info

    create_pkg e2fsprogs-$E2FSPROGSVERSION
    cleanup_builddir
    cleanup_outputdir
}

function build_coreutils()
{
    COREUTILSVERSION=8.25
    extract_archive coreutils-$COREUTILSVERSION.tar.xz

    cd $BUILDDIR/coreutils-$COREUTILSVERSION
    CC=clang CXX=clang++ ./configure --prefix=/usr --enable-no-install-program=kill,uptime
    make
    make DESTDIR=$OUTPUTDIR install
    mkdir -v $OUTPUTDIR/usr/sbin
    mkdir -v $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/{rmdir,stty,sync,true,uname} $OUTPUTDIR/bin
    mv -v $OUTPUTDIR/usr/bin/chroot $OUTPUTDIR/usr/sbin
    mkdir -v $OUTPUTDIR/usr/share/man/man8
    mv -v $OUTPUTDIR/usr/share/man/man1/chroot.1 $OUTPUTDIR/usr/share/man/man8/chroot.8
    sed -i s/\"1\"/\"8\"/1 $OUTPUTDIR/usr/share/man/man8/chroot.8

    create_pkg coreutils-$COREUTILSVERSION
    cleanup_builddir
    cleanup_outputdir
}

#build_emptydirs
#build_linuxheaders
#build_manpages
build_glibc
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
#build_bison
#build_flex
#build_grep
#build_readline
#build_bash
#build_bc
#build_libtool
#build_gdbm
#build_gperf
#build_expat
#build_inetutils
#build_perl
#build_perl_xmlparser
#build_intltool
#build_autoconf
#build_automake
#build_xz
#build_kmod
#build_gettext
#build_procpsng
#build_e2fsprogs
#build_coreutils
