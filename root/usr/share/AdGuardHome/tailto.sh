#!/bin/sh
tail -n $1 "$2" > /tmp/var/tailtmp
cat /tmp/var/tailtmp > "$2"
rm /tmp/var/tailtmp