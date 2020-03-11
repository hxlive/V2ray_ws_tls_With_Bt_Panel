#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

cd "$(
    cd "$(dirname "$0")" || exit
    pwd
)" || exit
#====================================================
#	System Request:Centos 7+
#	Author:	HanX
#	Dscription: V2ray ws+tls With Bt-Panel
#	Version: 1.0
#	Email:maxbyrne@gmail.com
#	Official document: www.v2ray.com
#====================================================

shell_version="1.0.20.0310"
github_branch="master"

#fonts color
Red="\033[1;31m"
Green="\033[1;32m"
Yellow="\033[1;33m"
Blue="\033[1;36m"
Font="\033[0m"

OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"
web_dir="/www/wwwroot"


install_v2ray_ws_tls() {
    install_prepare
    v2ray_install
    V2Ray_information
}

install_prepare() {
    if [[ "${ID}" == "centos" ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi
    if [[ -e "/etc/init.d/bt" ]]; then
        sleep 1
    else
        echo -e "${OK} ${GreenBG} 未检测到 宝塔面板，请先安装……${Font}"
        exit 1
    fi
    if [[ -e "/www/server/nginx" ]]; then
        sleep 1
    else
        echo -e "${OK} ${GreenBG} 未检测到 Nginx，请先安装……${Font}"
        exit 1
    fi

    echo -e "${Yellow} 请确保已完成伪装网址的域名解析 ${Font}"
    read -rp "请输入域名信息(eg:www.hanx.vip):" domain

    if [[ -e "/www/server/panel/vhost/nginx/${domain}.conf" ]]; then
        sleep 1
    else
        echo -e "${OK} ${GreenBG} 未检测到 ${domain} 内容，请先配置……${Font}"
        exit 1
    fi

    yum install -y wget
    yum reinstall glibc-headers gcc-c++ -y
}

v2ray_install() {
    if [[ -d /root/v2ray ]]; then
        rm -rf /root/v2ray
    fi
    if [[ -d /etc/v2ray ]]; then
        rm -rf /etc/v2ray
    fi
    mkdir -p /root/v2ray

    bash <(curl -L -s https://install.direct/go.sh)

    [ -z "$UUID" ] && UUID=$(cat /proc/sys/kernel/random/uuid)
    PORT=$((RANDOM + 10000))

    cat >/etc/v2ray/config.json <<EOF
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
        "loglevel": "warning"
  },
  "inbound": {
    "tag":"vmess-in",
    "listen": "127.0.0.1",
    "port": ${PORT},
    "protocol": "vmess",
    "settings": {
    "clients": [
      {
        "id": "${UUID}",
        "level": 0,
        "alterId": 16
        }
      ]
     },
    "streamSettings": {
      "network": "ws",
      "security": "auto",
      "wsSettings": {
        "path": "/vcache/",
        "headers": {
          "Host": "${domain}"
        }
      }
    }
  },
  "outbound": {
    "tag":"direct",
    "protocol": "freedom",
    "settings": {}
  },
  "outboundDetour": [
    {
      "protocol": "blackhole",
      "settings": { },
      "tag": "blocked"
    }
  ],
  "routing": {
    "strategy": "rules",
    "settings": {
      "rules": [
        {
          "type": "field",
          "ip": [
            "0.0.0.0/8",
            "10.0.0.0/8",
            "100.64.0.0/10",
            "127.0.0.0/8",
            "169.254.0.0/16",
            "172.16.0.0/12",
            "192.0.0.0/24",
            "192.0.2.0/24",
            "192.168.0.0/16",
            "198.18.0.0/15",
            "198.51.100.0/24",
            "203.0.113.0/24",
            "::1/128",
            "fc00::/7",
            "fe80::/10"
          ],
          "outboundTag": "blocked"
        }
      ]
    }
  },
  "policy": {
    "levels": {
      "0": {
      "uplinkOnly": 0,
      "downlinkOnly": 0,
      "connIdle": 150,
      "handshake": 4
      }
    }
  }
}
EOF

    cp /www/server/panel/vhost/nginx/${domain}.conf /www/server/panel/vhost/nginx/${domain}.conf.bak
    sed -i '$d' /www/server/panel/vhost/nginx/${domain}.conf
    cat >>/www/server/panel/vhost/nginx/${domain}.conf <<EOF
        location /vcache/
        {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${PORT};
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        }
}
EOF

    cat >/usr/local/vmess_info.json <<-EOF
{
  "v": "2",
  "ps": "v2ray_${domain}",
  "add": "${domain}",
  "port": "443",
  "id": "${UUID}",
  "aid": "16",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "/vcache/",
  "tls": "tls"
}
EOF
    start_service
}

V2ray_info_query() {
    grep "$1" "/usr/local/vmess_info.json" | awk -F '"' '{print $4}'
}

V2Ray_information() {
    clear
    vmess_link="vmess://$(base64 -w 0 /usr/local/vmess_info.json)"
    {
        echo -e "${Green} V2ray+ws+tls 安装成功${Font}"
        echo -e "${Blue}=====================================================${Font}"
        echo -e "${Green} V2ray 配置信息 ${Font}"
        echo -e "${Green} 地址（address）:${Font} $(V2ray_info_query '\"add\"') "
        echo -e "${Green} 端口（port）：${Font} $(V2ray_info_query '\"port\"') "
        echo -e "${Green} 用户ID（id）：${Font} $(V2ray_info_query '\"id\"')"
        echo -e "${Green} 额外ID（alterId）：${Font} 16"
        echo -e "${Green} 加密方式（security）：${Font} auto"
        echo -e "${Green} 传输协议（network）：${Font} ws"
        echo -e "${Green} 伪装类型（type）：${Font} none"
        echo -e "${Green} 路径（不要落下/）：${Font} /vcache/"
        echo -e "${Green} 底层传输安全：${Font} tls"
        echo -e "${Blue}=====================================================${Font}"
        echo -e "${Yellow} URL导入链接:${vmess_link} ${Font}"
    }
}

start_service() {
    systemctl daemon-reload
    /www/server/nginx/sbin/nginx -s reload
    systemctl restart v2ray.service
}
stop_service() {
    systemctl stop v2ray
    systemctl stop v2ray.service
    systemctl disable v2ray.service
}

uninstall_V2Ray() {
    systemctl stop v2ray
    systemctl stop v2ray.service
    systemctl disable v2ray.service
    rm -rf /etc/systemd/system/v2ray.service
    rm -rf /usr/bin/v2ray
    rm -rf /etc/v2ray
    cp /www/server/panel/vhost/nginx/$(V2ray_info_query '\"add\"').conf.bak /www/server/panel/vhost/nginx/$(V2ray_info_query '\"add\"').conf
    rm -rf /www/server/panel/vhost/nginx/$(V2ray_info_query '\"add\"').conf.bak
    systemctl daemon-reload
    echo -e "${OK} ${GreenBG} 卸载完成，谢谢使用~ ${Font}"
}


Main_menu() {
  clear
    echo -e ""
    echo -e "    ${Blue}V2ray 部署脚本 [${shell_version}]${Font}"
    echo -e "    ${Blue}---- authored by HANX ----${Font}"
    echo -e ""
    echo -e " ———————————— 安装向导 ————————————"
    echo -e " ${Green}1. 安装 V2Ray (ws+tls)${Font}"
    echo -e " ${Green}2. 查看 V2Ray 配置信息${Font}"
    echo -e " ${Red}3. 卸载 V2Ray 及配置${Font}"
    echo -e " ${Green}4. 退出部署脚本${Font}"
    echo -e ""
    read -rp " 请输入数字：" menu_num
    case $menu_num in
    1)
        install_v2ray_ws_tls
        ;;
    2)
        V2Ray_information
        ;;
    3)
        uninstall_V2Ray
        ;;
    4)
        exit 0
        ;;
    *)
        echo -e "${RedBG}请输入正确的数字${Font}"
        sleep 2s
        Main_menu
        ;;
    esac
}

Main_menu
