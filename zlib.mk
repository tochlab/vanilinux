include makefile.inc
ZLIBVERSION=1.2.11

default:
	mkdir -p $(BUILDDIR)
	mkdir -p $(OUTPUTDIR)
	mkdir -p $(PKGDIR)
	$(call extract_archive,zlib-$(ZLIBVERSION).tar.gz)
	cd $(BUILDDIR)/zlib-$(ZLIBVERSION); ./configure --prefix=/usr; make; make DESTDIR=$(OUTPUTDIR) install
	$(call create_pkg,zlib-$(ZLIBVERSION))
	$(call clean_workdirs)
