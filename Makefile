.SUFFIXES:
.SUFFIXES: .c .o .pl .pm .pod .html .man .wml .1 .txt
SHELL=/bin/sh

MAJOR  = 1
MINOR  = 0
MMINOR = 0
VERSION = $(MAJOR).$(MINOR).$(MMINOR)

TAR = gedafe-$(VERSION).tar.gz

release: release-tag
	doc/gedafe-sql.txt doc/gedafe-user.txt
	shtool mkdir -p gedafe-$(VERSION)
	gtar -T MANIFEST -cf - | (cd gedafe-$(VERSION) && gtar xf -)
	gtar --mode=g-s -czvf pub/$(TAR) gedafe-$(VERSION)
	rm -rf gedafe-$(VERSION)
	
release-tag:
	cvs tag -F v$(MAJOR)_$(MINOR)_$(MMINOR)

.pod.txt:
	pod2man --release=$(VERSION) --center=gedafe $<  >pod2txt.tmp
	groff -man -Tascii pod2txt.tmp > $@
	rm pod2txt.tmp
