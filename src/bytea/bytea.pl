#!/usr/bin/perl
# you have just selected something from a table
# with gedafe encoded files in a bytea column 
# This needs to be decoded into usable parts.
# 
# instead of giving some functions like in bytea.php
# the process of decoding is described here. This is
# because php decodes BYTEA columns differently and
# is less regexp capable.
#
# 
# the file is encoded in the field like this:
# <filename> <mimetype>#<bytestring>
# (without the <> ofcourse)
# A suitable regexp is left as an exercise for the reader.
# Keep in mind that mimetypes include / and - characters.

