#!/bin/sh
# Kindle FTP stop script (silent, for KOReader plugin)

fuser -k 21/tcp 2>/dev/null
iptables -D INPUT -p tcp --dport 21 -j ACCEPT 2>/dev/null
sleep 1

exit 0
