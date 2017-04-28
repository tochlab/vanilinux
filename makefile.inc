TMPDIR=$(PWD)/tmp
BUILDDIR=$(TMPDIR)/build
OUTPUTDIR=$(TMPDIR)/output
PKGDIR=$(TMPDIR)/pkg
SOURCEDIR=$(PWD)/sources

define extract_archive
    echo -n "Exctracting $(1) ... "
    tar -xvf $(SOURCEDIR)/$(1) -C $(BUILDDIR)
    echo "OK"
endef

define create_pkg
    echo -n "Creating package $(1).tgz ... "
    cd $(OUTPUTDIR); tar cfz $(PKGDIR)/$1.tgz .
    echo "OK"
endef

define clean_workdirs
    rm -fr $(BUILDDIR)
    rm -fr $(OUTPUTDIR)
endef

.ONESHELL:
