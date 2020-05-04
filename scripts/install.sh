#!/bin/bash -e

CWD=$(cd $(dirname $0); pwd)

##############################################################
# Basic Configuration
##############################################################
echo "Configuring system ..."

## timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

## disable firewall and iptables
#sudo systemctl disable firewalld.service

## disable kdump
#sudo systemctl disable kdump.service

##############################################################
# Running ovfenv-installer for next reboot
##############################################################
#sudo yum install -y https://github.com/subchen/ovfenv-installer/releases/download/v1.0.2/ovfenv-installer-1.0.2-17.x86_64.rpm

#sudo cat >> /etc/rc.d/rc.local << EOF
#ovfenv-installer --run-once --log-file=/var/log/ovfenv-installer.log
#EOF

#sudo chmod +x /etc/rc.d/rc.local

# Disable selinux
setenforce 0
sed -i 's/enforcing/disabled/' /etc/selinux/config

# Performe a update in system

yum update -y
