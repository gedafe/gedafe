MAJOR  = 0
MINOR  = 9
MMINOR = 7
VERSION = $(MAJOR).$(MINOR).$(MMINOR)

FILES = `cat MANIFEST`
TAR = gedafe-$(VERSION).tar.gz

dist:
	shtool mkdir -p gedafe-$(VERSION)
	gtar cf - $(FILES) | (cd gedafe-$(VERSION) && gtar xf -)
	gtar czvf pub/$(TAR) gedafe-$(VERSION)
	rm -rf gedafe-$(VERSION)
