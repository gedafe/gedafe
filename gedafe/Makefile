MAJOR  = 0
MINOR  = 9
MMINOR = 7
VERSION = $(MAJOR).$(MINOR).$(MMINOR)

TAR = gedafe-$(VERSION).tar.gz

dist:
	shtool mkdir -p gedafe-$(VERSION)
	gtar -T MANIFEST -cf - | (cd gedafe-$(VERSION) && gtar xf -)
	gtar --mode=g-s -czvf pub/$(TAR) gedafe-$(VERSION)
	rm -rf gedafe-$(VERSION)
