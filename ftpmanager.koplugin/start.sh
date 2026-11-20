#!/bin/sh
# Kindle FTP start script (silent, for KOReader plugin)
SHARE_DIR="/mnt/us"

# 1. Clean old process by port
fuser -k 21/tcp 2>/dev/null
sleep 1

# 2. Check busybox ftpd
if ! busybox --list | grep -q "ftpd"; then
    echo "Error: BusyBox has no ftpd"
    exit 1
fi

# 3. Check share dir
if [ ! -d "$SHARE_DIR" ]; then
    echo "Error: share dir not found: $SHARE_DIR"
    exit 1
fi

# 4. Allow port 21 in firewall
if ! iptables -C INPUT -p tcp --dport 21 -j ACCEPT 2>/dev/null; then
    iptables -I INPUT -p tcp --dport 21 -j ACCEPT 2>/dev/null
fi

# 5. Start FTP service
busybox tcpsvd 0 21 busybox ftpd -w -a root "$SHARE_DIR" &

exit 0