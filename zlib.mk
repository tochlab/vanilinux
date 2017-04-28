include makefile.inc
ZLIBVERSION=1.2.11

default:
	mkdir -p $(BUILDDIR)
	mkdir -p $(OUTPUTDIR)
	tar -xf sources/zlib-$(ZLIBVERSION).tar.gz -C $(BUILDDIR)
	cd $(BUILDDIR)/zlib-$(ZLIBVERSION); ./configure --prefix=/usr; make; make DESTDIR=$(OUTPUTDIR) install
