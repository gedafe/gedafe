.SUFFIXES:
.SUFFIXES: .c .o .pl .pm .pod .html .man .wml .1 .txt
SHELL=/bin/sh

MAJOR  = 0
MINOR  = 9
MMINOR = 12
VERSION = $(MAJOR).$(MINOR).$(MMINOR)

TAR = gedafe-$(VERSION).tar.gz

dist:   doc/gedafe-sql.txt doc/gedafe-user.txt
	shtool mkdir -p gedafe-$(VERSION)
	gtar -T MANIFEST -cf - | (cd gedafe-$(VERSION) && gtar xf -)
	gtar --mode=g-s -czvf pub/$(TAR) gedafe-$(VERSION)
	rm -rf gedafe-$(VERSION)

.pod.1:
	pod2man --release=$(VERSION) --center=mrtg $<  > $@

.1.txt:
	groff -man -Tascii $< > $@
