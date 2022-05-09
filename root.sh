#!/bin/bash

red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}

green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'" "alpine")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS" "Alpine")
PACKAGE_UPDATE=("apt -y update" "apt -y update" "yum -y update" "yum -y update" "apk update -f")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install" "apk add -f")
CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
	SYS="$i" && [[ -n $SYS ]] && break
done

for ((int=0; int<${#REGEX[@]}; int++)); do
	[[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "OS hiện tại không hỗ trợ script này!" && exit 1
[[ ! -f /etc/ssh/sshd_config ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} openssh-server
[[ -z $(type -P curl) ]] && sudo ${PACKAGE_UPDATE[int]} && sudo ${PACKAGE_INSTALL[int]} curl

IP=$(curl -sm8 ip.sb)

sudo lsattr /etc/passwd /etc/shadow >/dev/null 2>&1
sudo chattr -i /etc/passwd /etc/shadow >/dev/null 2>&1
sudo chattr -a /etc/passwd /etc/shadow >/dev/null 2>&1
sudo lsattr /etc/passwd /etc/shadow >/dev/null 2>&1

read -p "Nhập cổng SSH sẽ được đặt (Mặc định là 22):" sshport
[ -z $sshport ] && red "Cổng SSH chưa được đặt, cổng 22 mặc định sẽ được sử dụng" && sshport=22
read -p "Nhập mật khẩu root:" password
[ -z $password ] && red "Chưa nhập mật khẩu, mật khẩu root sẽ được tạo ngẫu nhiên" && password=$(cat /proc/sys/kernel/random/uuid)
echo root:$password | sudo chpasswd root

sudo sed -i "s/^#\?Port.*/Port $sshport/g" /etc/ssh/sshd_config;
sudo sed -i "s/^#\?PermitRootLogin.*/PermitRootLogin yes/g" /etc/ssh/sshd_config;
sudo sed -i "s/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g" /etc/ssh/sshd_config;

sudo service ssh restart >/dev/null 2>&1 
sudo service sshd restart >/dev/null 2>&1

yellow "Thiết lập thông tin đăng nhập VPS đã hoàn tất!"
green "Địa chỉ đăng nhập：$IP:$sshport"
green "Tên tài khoản： root"
green "Mật khẩu： $password"
yellow "Vui lòng reboot lại VPS！"
