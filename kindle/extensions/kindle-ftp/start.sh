#!/bin/sh
SHARE_DIR="/mnt/us"
PLUGIN_DIR="/mnt/us/extensions/kindle-ftp"

# 1. 启动前先杀可能残留的旧循环和旧服务
pkill -9 -f "ftp_daemon.sh" 2>/dev/null
fuser -k 21/tcp 2>/dev/null
sleep 1

# 2. 放行 21 端口（防火墙设置）
# 先尝试删除可能残留的同名规则（避免重复添加），再插入新规则放行
iptables -D INPUT -p tcp --dport 21 -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp --dport 21 -j ACCEPT 2>/dev/null

# 3. 启动 FTP 服务
busybox tcpsvd 0 21 busybox ftpd -w -a root "$SHARE_DIR" &
sleep 1

# 4. 获取 IP
IP=$(ifconfig wlan0 2>/dev/null | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
if [ -z "$IP" ]; then
    IP=$(ifconfig wlan0 2>/dev/null | grep "inet " | awk '{print $2}' | cut -d: -f2)
fi

# 5. 检测服务状态并常驻显示
if netstat -tln 2>/dev/null | grep -q ":21 "; then
    # 禁止休眠
    lipc-set-prop com.lab126.powerd preventScreenSaver 1
    
    if [ -n "$IP" ]; then
        MSG="ftp://$IP:21 "
    else
        MSG="No IP "
    fi

    # 生成守护脚本，加入 while 循环
    cat << EOF > $PLUGIN_DIR/ftp_daemon.sh
#!/bin/sh
while true; do
    eips 20 1 "$MSG"
    sleep 2
done
EOF
    chmod +x $PLUGIN_DIR/ftp_daemon.sh
    
    # 启动后台进程
    $PLUGIN_DIR/ftp_daemon.sh &
else
    lipc-set-prop com.lab126.pillow pillowNotification "FTP Failed" 2>/dev/null
fi

exit 0
