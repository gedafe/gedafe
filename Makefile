MAJOR  = 0
MINOR  = 9
MMINOR = 7
VERSION = $(MAJOR).$(MINOR).$(MMINOR)

FILES = `cat MANIFEST`
TAR = gedafe-$(VERSION).tar.gz

dist:
	gtar czvf pub/$(TAR) $(FILES)
