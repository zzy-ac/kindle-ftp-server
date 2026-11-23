#!/bin/sh
PLUGIN_DIR="/mnt/us/extensions/kindle-ftp"

# 1. 用 pkill -f 精准杀死后台循环
# 这会匹配所有包含 "ftp_daemon.sh" 的命令行，不管是 sh 还是 busybox
pkill -9 -f "ftp_daemon.sh" 2>/dev/null

# 2. 停止 FTP 服务
fuser -k 21/tcp 2>/dev/null
sleep 1

# 3. 恢复系统休眠
lipc-set-prop com.lab126.powerd preventScreenSaver 0

# 4. 关闭防火墙的 21 端口放行（撤销规则）
iptables -D INPUT -p tcp --dport 21 -j ACCEPT 2>/dev/null

# 5. 此时后台循环绝对已经死了，现在写 3 秒 killall
eips 20 1 " [ killall ftpd ]        "
sleep 3

# 6. 用超长空格覆盖，彻底擦除
eips 20 1 "                       "

# 清理文件
rm -f $PLUGIN_DIR/ftp_daemon.sh

exit 0
