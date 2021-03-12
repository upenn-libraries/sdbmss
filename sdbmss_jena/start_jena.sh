#!/usr/bin/env bash

# Script to clean up and start fuseki, because lando, **SIGH** :-(, can't
# run a command like this:
#
#   rm /fuseki/system/tdb.lock ; rm /fuseki/databases/sdbm/tdb.lock ; ./fuseki-server
#
# from compose/services/command without the server dying, and you
# *HAVE* to be able to remove lock files before you invoke server
# or, you know, half the time It. Won't. Even. Start.

cd /jena-fuseki

rm -f /fuseki/system/tdb.lock
rm -f /fuseki/databases/sdbm/tdb.lock
./fuseki-server