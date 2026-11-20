#!/bin/sh
# Kindle FTP status script (command-line debug only; KOReader plugin uses Lua)
if netstat -tln 2>/dev/null | grep -q ":21 "; then
    IP=$(ifconfig wlan0 2>/dev/null | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
    echo "FTP service: running"
    echo "Port: 21"
    echo "Dir: /mnt/us"
    if [ -n "$IP" ]; then
        echo "Link: ftp://$IP:21"
    else
        echo "No WiFi IP found"
    fi
else
    echo "FTP service: not running"
fi