local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local _ = require("gettext")

local FTPManager = WidgetContainer:extend{
    name = "ftpmanager",
    is_doc_only = false,
}

function FTPManager:init()
    self.ui.menu:registerToMainMenu(self)
end

-- 获取插件目录绝对路径
local function getPluginDir()
    local info = debug.getinfo(1, "S")
    local source = info.source
    local path = source:sub(2)
    return path:match("(.*)/")
end

-- 执行 shell 命令并返回输出（去掉尾部换行）
local function run_cmd(cmd)
    local handle = io.popen(cmd .. " 2>/dev/null")
    if not handle then return "" end
    local out = handle:read("*a") or ""
    handle:close()
    return (out:gsub("%s+$", ""))
end

-- 检查 21 端口是否在监听
local function is_ftp_running()
    local out = run_cmd("netstat -tln")
    return out:find(":21 ") ~= nil
end

-- 获取 wlan0 的 IPv4 地址
local function get_ip()
    local out = run_cmd("ifconfig wlan0")
    -- 兼容 "inet addr:192.168.x.x" 和 "inet 192.168.x.x" 两种格式
    local ip = out:match("inet addr:(%d+%.%d+%.%d+%.%d+)")
        or out:match("inet (%d+%.%d+%.%d+%.%d+)")
    return ip
end

-- 构造状态文本
local function build_status_text()
    if not is_ftp_running() then
        return _("FTP service: NOT running.\n\nTap 'Start FTP' to launch it.")
    end
    local ip = get_ip()
    local lines = {
        _("FTP service: running"),
        _("Port: 21"),
        _("Dir: /mnt/us"),
    }
    if ip then
        table.insert(lines, _("Link: ") .. "ftp://" .. ip .. ":21")
        table.insert(lines, _("User: anonymous / ftp"))
        table.insert(lines, _("Password: any or empty"))
    else
        table.insert(lines, _("No WiFi IP found. Check WiFi connection."))
    end
    return table.concat(lines, "\n")
end

function FTPManager:addToMainMenu(menu_items)
    local plugin_dir = getPluginDir()

    menu_items.ftp_manager = {
        text = _("FTP Manager"),
        sorting_hint = "more_tools",
        sub_item_table = {
            {
                text = _("Start FTP"),
                callback = function()
                    os.execute(plugin_dir .. "/start.sh")
                    -- 给 tcpsvd 一点启动时间
                    os.execute("sleep 1")
                    UIManager:show(InfoMessage:new{
                        text = build_status_text(),
                        timeout = 6,
                    })
                end,
            },
            {
                text = _("Stop FTP"),
                callback = function()
                    os.execute(plugin_dir .. "/stop.sh")
                    os.execute("sleep 1")
                    local running = is_ftp_running()
                    UIManager:show(InfoMessage:new{
                        text = running and _("Stop failed: port 21 still listening.")
                                     or _("FTP service stopped."),
                        timeout = 4,
                    })
                end,
            },
            {
                text = _("Show Status"),
                callback = function()
                    UIManager:show(InfoMessage:new{
                        text = build_status_text(),
                        timeout = 6,
                    })
                end,
            },
        },
    }
end

return FTPManager