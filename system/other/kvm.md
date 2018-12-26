###### install
- grep -P '(vmx|svm)' /proc/cpuinfo
- lsmod | grep kvm
```html
 kvm_intel             183720  0 
 kvm                   578558  1 kvm_intel
```

- yum install qemu-kvm qemu-kvm-tools virt-manager libvirt virt-install bridge-utils virt-manager qemu-kvm-tools  virt-viewer libguestfs-tools -y
- service libvirtd start
```html
cd /etc/sysconfig/network-scripts/
cp ifcfg-eth0 ifcfg-br0
桥接模式
vim ifcfg-eth0 
-------------------------------------------------
DEVICE=eth0
TYPE=Ethernet               #<-
UUID=7d08765c-c03c-4fe9-a725-a9765bf0097a
ONBOOT=yes                  #<-
NM_CONTROLLED=yes
BOOTPROTO=none
IPV6INIT=no
USERCTL=no
BRIDGE=br0                  #<- 
#NETWORK=192.168.0.0
#IPADDR=192.168.0.33
#NETMASK=255.255.252.0
#DNS2=202.106.0.20
#GATEWAY=192.168.1.254
#DNS1=192.168.1.6
-------------------------------------------------

vim ifcfg-br0
-------------------------------------------------
DEVICE=br0
TYPE=Bridge               #<-
UUID=7d08765c-c03c-4fe9-a725-a9765bf0097a
ONBOOT=yes                #<-
NM_CONTROLLED=yes
BOOTPROTO=none
IPV6INIT=no
USERCTL=no
NETWORK=192.168.0.0
IPADDR=192.168.0.33
NETMASK=255.255.252.0
DNS2=202.106.0.20
GATEWAY=192.168.1.254
DNS1=192.168.1.6
-------------------------------------------------
/etc/rc.d/init.d/network restart
brctl show
```


- ln -s /usr/libexec/qemu-kvm /usr/bin/qemu-kvm

- 两种不同格式 第一种按需创建大小 第二种固定大小
- qemu-img create -f qcow2 /data/kvm/CentOS_7/CentOS_7.img 20G
- qemu-img create -f raw /data/kvm/CentOS_7/CentOS_7.raw 20G

```html
virt-install --name CentOS_7 \
--os-variant=rhel7 \
--ram 1024 --vcpu=2 \
--cdrom=/data/soft/CentOS-7-x86_64-Minimal-1611.iso \
--disk path=/data/kvm/CentOS_7/CentOS_7.img,format=qcow2,size=20,bus=virtio \ 
--network bridge=br0,model=virtio \
--graphics vnc,port=5910,listen=0.0.0.0 \
--accelerate \
--noautoconsole --os-type=linux \
```
- 
- 虚拟机网卡设置为eth0类型
- install options eth0 ==> net.ifnames=0 biosdevname=0
- 打开vnc客户端 192.168.1.70：5900

```html
qemu-img create -f qcow2 /data/kvm/CentOS_7/CentOS_7.img 20G
ks自动安装
virt-install --name=CentOS_7_KS --os-variant=rhel6 -r 2048 --vcpu=2 \
--disk path=/data/kvm/CentOS_7/CentOS_7.img,format=qcow2,size=20,bus=virtio \
--graphics vnc,port=5911,listen=0.0.0.0 \
--accelerate \
--force \
--network bridge=br0,model=virtio \
-x "ks=http://192.168.0.33/ks.cfg" \
-l "http://192.168.0.33/cdrom/"
```

```html
添加磁盘
CentOS_7 虚拟机为关闭状态

qemu-img create -f qcow2 /data/kvm/CentOS_7/CentOS_7_data.img 50G

vim /etc/libvirt/qemu/CentOS_7.xml
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/data/kvm/CentOS_7/CentOS_7.img'/>
      <target dev='vda' bus='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x05' function='0x0'/>
    </disk>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='none'/>
      <source file='/data/kvm/CentOS_7/CentOS_7_data.img'/>
      <target dev='vdb' bus='virtio'/>
    </disk>

virsh define /etc/libvirt/qemu/CentOS_7.xml

virsh start CentOS_7
fdisk -l
fdisk /dev/vdb
n
p
1

w

mkfs.ext4 /dev/vdb1
blkid /dev/vdb1 | sed 's/"//g'
blkid /dev/vdb1 | sed 's/"//g' | grep -Po '(?<= )(UUID+.*)(?= TYPE)' | xargs -I {}  echo {} "/data                   xfs     defaults        0 0"
vim /etc/fstab
```



- 配置文件目录
  - /etc/libvirt/qemu/
  - virsh edit CentOS_7

- 利用libvirt 提供的API 对虚拟机(xen kvm vmware other hypervisors)进行管理 
  - systemctl enable libvirtd.service
  - systemctl status libvirtd.service
  - systemctl status libvirtd.service
  - virsh
  - virsh list
  - virsh edit CentOS_7
  - 开启网络 
  - yum install net-tools
  
- virsh edit CentOS_7
  - 修改CPU当前1个最大支持4个 此选项可支持动态增加CPU 支持热添加 不支持热删除
  - <vcpu placement='auto' current="1">4</vcpu>
  - virsh setvcpus CentOS_7 2 --live      #动态增加虚拟机中CPU数量
  - 虚拟机中查看 cat /sys/devices/system/cpu/cpu<0|1>/online

  - 内存可以动态修改 支持热添加 支持热删除
  -  <memory unit='KiB'>524288</memory>    #最大内存支持大小 不可超过此数值
  -  <currentMemory unit='KiB'>524288</currentMemory> #当前内存大小
  - virsh qemu-monitor-command CentOS_7 --hmp --cmd info balloon #查看内存情况
  - virsh qemu-monitor-command CentOS_7 --hmp --cmd balloon 1024 #修改内存
  
- brctl
  - brctl addif br0 eth0 && ip addr del dev eth0 192.168.1.70/24 && ifconfig br0 192.168.1.70/24 up && route add default gw 192.168.1.1 && iptables -F 



```html
hostnamectl --static set-hostname vm-1-80

while read loop
do 
  item=`echo ${loop} | cut -d' ' -f1`
  systemctl stop ${item}
  systemctl disable ${item}
done< <(systemctl list-unit-files | grep enabled | grep -Pi -v 'sshd|network|crond|irqbalance|syslog')

cat >> /etc/profile << EOF 
PS1='[-\$?- \[\e[32m\]\u@\[\e[31m\]\h\[\e[33m\] \w\[\e[0m\]]\\$ '
export MYSQL_PS1="\u@-DB-[\d]> "
EOF

cat > ~/.vimrc << EOF
syntax enable
syntax on
set nobackup
set tabstop=2
set shiftwidth=2
set expandtab
set ff=unix
set nobomb
set fileencoding=utf-8
set nocompatible
set ai
set hls
set nu
EOF

cat >> /etc/security/limits.conf << EOF
* soft nofile 51200
* hard nofile 51200
* soft nproc 65535 
* hard nproc 65535 
EOF

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
setenforce 0

#DNS Setting

cat > /etc/resolv.conf << EOF
search localdomain
nameserver 202.106.0.20
nameserver 8.8.8.8
EOF

/usr/sbin/ntpdate stdtime.gov.hk
echo "00 * * * *  /usr/sbin/ntpdate stdtime.gov.hk" >> /var/spool/cron/root

yum install net-tools vim tree unzip


yum install net-tools vim tree unzip openssl openssl-devel gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel openldap openldap-devel nss_ldap openldap-clients openldap-servers gd-devel libXpm-devel wget unzip pcre pcre-devel ntpdate


```

```html
#!/bin/bash

echo_err(){
  echo -e "\E[1;31m""$@ \033[0m"
}

echo_ok(){
  echo -e "\E[1;32m""$@ \033[0m"
}

usage(){
  echo "
  USAGE:
  $0 <lan_ip/netmask>

  eg.
  $0 192.168.9.50
"
  exit 99
}

create_hosts(){
  hostname=$1
  echo "127.0.0.1   $hostname localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         $hostname localhost localhost.localdomain localhost6 localhost6.localdomain6
" > /tmp/hosts
  return 0
}

create_resolv(){
  cat /etc/resolv.conf > /tmp/resolv.conf
  return 0
}

create_network(){
  hostname=$1
  gateway=`echo $1 | sed -r 's/[0-9]+$/1/'`

  echo "NETWORKING=yes
HOSTNAME=$hostname
GATEWAY=$gateway" > /tmp/network
  return 0
}

create_ethx(){
  lan=$1
  lan_gateway=`echo $1 | sed -r 's/[0-9]+$/1/'`
#  wan=$2

    echo "DEVICE=eth0
BOOTPROTO=static
TYPE=Ethernet
ONBOOT=yes
IPADDR=$lan
GATEWAY=$lan_gateway
NETMASK=255.255.255.0
" > /tmp/ifcfg-eth0

#    echo "DEVICE=eth1
#BOOTPROTO=static
#TYPE=Ethernet
#ONBOOT=yes
#IPADDR=$wan
#NETMASK=255.255.255.0
#" > /tmp/ifcfg-eth1
  
  return 0
}

create_route(){
    echo "10.0.0.0/8 via 10.10.15.254
172.16.0.0/16 via 10.10.15.254
192.168.0.0/16 via 10.10.15.254" > /tmp/route-eth0
    return 0
}

copy_in_kvm(){
  domname=`echo "$1" | sed -r 's/\./-/g'`

  virt-copy-in -d $domname /tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/
#    virt-copy-in -d $domname /tmp/ifcfg-eth1 /etc/sysconfig/network-scripts/
#    virt-copy-in -d $domname /tmp/route-eth0 /etc/sysconfig/network-scripts/
  virt-copy-in -d $domname /tmp/network /etc/sysconfig/
  virt-copy-in -d $domname /tmp/resolv.conf /etc
  virt-copy-in -d $domname /tmp/hosts /etc

  return 0
}

clear_tmp(){
  rm /tmp/{hosts,resolv.conf,network,ifcfg-*,route-*} -f
  return 0
}

change_vnc_passwd(){
  domname=`echo "$1" | sed -r 's/\./-/g'`

  sed -r -i "/vnc/s/>/ passwd='0aBy4eN6Dz0cz7N'>/" /etc/libvirt/qemu/$domname.xml

  return 0
}

# ------------------------------------------------------------

if ! echo "$1" | grep -Pq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$';then
  echo 1
  usage
fi

#if [[ ! -z $2 ]] && ! echo "$1" | grep -Pq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$';then
#    echo 2
#    usage
#fi

if echo "$1" | grep -Pq '^192\.';then
  lan_ip=$1
#    if [[ ! -z $2 ]];then
#        wan_ip=$2
#    else
#        wan_ip=`echo "$1" | sed -r 's/^[0-9]+\.[0-9]+\.[0-9]+\./123.30.247./'`
#    fi
#else
#    if [[ ! -z $2 ]];then
#        lan_ip=$2
#    else
#        lan_ip=`echo "$1" | sed -r 's/^[0-9]+\.[0-9]+\.[0-9]+\./192.168.144./'`
#    fi
#    wan_ip=$1
fi

hostname=`echo "$lan_ip" | sed -r 's/^[0-9]+\.[0-9]+\.([0-9]+)\.([0-9]+)$/vm-\1-\2/'`
gateway=`echo "$lan_ip" | sed -r 's/[0-9]+$/1/'`
domname=`echo "$lan_ip" | sed -r 's/\./-/g'`

echo_ok "
  LAN_IP   : $lan_ip
  GATEWAY  : $gateway
  HOSTNAME : $hostname
  DOMNAME  : $domname
"

while true
do
  echo_ok "it OK ? [y/n]"
  read flag

  if [[ "$flag" == 'y' ]];then
    echo_ok "Begin clone ..."
    break
  elif [[ "$flag" == 'n' ]];then
    echo_ok "Exit clone."
    exit
  else
    continue
  fi
done

echo "test $lan_ip ..."
if ping -c 2 $lan_ip >/dev/null 2>&1; then
  echo_err "$lan_ip is existed !!!"
  exit
fi

#echo "test $wan_ip ..."
#if ping -c 2 $wan_ip >/dev/null 2>&1; then
#    echo_err "$wan_ip is existed !!!"
#    exit
#fi

if test -d /data/kvm/$domname;then
  echo_err "/data/kvm/$domname is existed !!!"
  exit
else
  mkdir -p /data/kvm/$domname
fi

virt-clone --connect qemu:///system\
 -o CentOS_7 -n ${domname}\
 -f /data/kvm/${domname}/${domname}-system.img\
 -f /data/kvm/${domname}/${domname}-data.img

clear_tmp

create_hosts $hostname
create_resolv
create_network $hostname $gateway
#create_route
create_ethx $lan_ip $wan_ip
change_vnc_passwd $domname
copy_in_kvm $domname

clear_tmp
```