vim /etc/yum.conf
proxy=http://192.168.10.1:9919

在此连接寻找合适的源
https://repo.saltstack.com/yum/redhat/
yum install https://repo.saltstack.com/yum/redhat/salt-repo-2016.3-2.el7.noarch.rpm

yum install salt-master
yum install salt-minion

注意 客户端的主机名要唯一 变动主机名需要清除/etc/salt/minion_id文件内容

日志文件 /var/log/salt/master /var/log/salt/minion

salt-minion
vim /etc/salt/minion
  master: 192.168.1.70

注意 客户端   /etc/salt/minion_id文件
master识别minion时 pki文件里需要用到此minion_id文件里的标识
master pki文件夹下minion_pre里文件名对应minion_id文件里的标识
minion_pre文件里存储客户端的公钥

master 端操作
远程执行
  salt-key #列出所有类型的key
  salt-key -a 接受某个主机 或通配符接受一类主机
  salt-key -A 接受所有主机
  此过程为master 和minion交换公钥过程

  salt '*' test.ping
  salt '*' cmd.run 'w'

state状态管理 yaml格式 sls格式结尾
  缩进 2个空格 不能使用tab
  冒号 key:value
  短横线 - list1
        - list2


salt Master配置文件
/etc/salt/master

file_roots:         #状态文件目录
  base:
    - /srv/salt

state_top: top.sls  #入口文件





minion机器state被下发后存放在
/var/cache/salt/minion/files/base

apache.sls

apache-install:         #自定义名字
  pkg.installed:        #模块.方法 软件安装
    - names:            #相当于字典 里有个列表 要安装软件的列表
      - httpd
      - httpd-devel

apache-service:         # 自定义名字
  service.running:      # 模块.名字 服务运行
    - name: httpd       # 服务名字
    - enable: Tre       # 服务开机启动



top.sls 入口文件 正式环境不要使用 *
salt '*' state.highstate test=True      #先测试无误后再执行
salt '*' state.highstate                #正式执行


ZeroMQ
lsof -i:4505
lsof -i:4506
4505 发布订阅  发消息
4506 接受返回的数据

数据系统

Grains 静态数据
当Minion启动的时候收集的Minion的本地相关数据
操作系统 内核版本 CPU 内存 硬盘 设备型号 序列号等
资产管理
用于目标选择   salt -G 'os:CentOS' cmd.run
配置管理使用

salt 'vm-1-81' grains.items       #输出机器配置信息
salt 'vm-1-81' grains.items os    #输出机器某一项信息
salt -G 'os:CentOS' test.ping     #-G 目标选择执行
salt -G 'os:CentOS' cmd.run 'w'

自定义grains 在minion机器上 配置文件内 自定义角色
grains:
  roles:
    - webserver

grains 文件内定义

vim /etc/salt/grains
key: value
salt 'vm-1-81' saltutils.sync_grains      #同步刷新grains配置参数
salt 'vm-1-81' grains.item key            #获取独立配置的参数


vim top.sls
base:
  'vm-1-81':
    - web.apache
  'vm-1-82':
    - web.apache
  'roles:apache':       #自定义grain中roles为apache
    - match: grain      #grain 匹配
    - web.apache        #执行web.apache

salt master机器上自定义grains 返回字典

mkdir /srv/salt/_grains
cd !$
vim my_grains.py
  return {key2:value2, key:value}

salt '*' saltutil.sync_grains  #将自定义的grains推送到minion机器 刷新Grains

同步到minion机器上位置查看
tree /var/cache/salt/minion/

Master 执行查看 字典值
salt '*' grains.item key

grains优先级
  系统自带
  grains文件
  minion配置文件
  自己写的

Pillar 动态 类似于top file
给特定的minion指定特定的数据 只有指定的minion能看到自己的数据
敏感数据调用

Master 配置文件中 打开pillar配置
pillar_roots:
  base:
    - /srv/pillar

mkdir /srv/pillar/web

vim apache.sls
{% if grains['os'] == 'CentOS' %}
apache: httpd
{% elif grains['os'] == 'Debian' %}
apache: apache2
{% endif %}

Pillar需要在top.sls中指定哪些agent可以使用此变量
  web 为目录
  apache 为文件 apache.sls
vim /srv/pillar/top.sls
base:
  'vm-1-81':
    - web.apache

salt '*' saltutil.refresh_pillar
salt '*' pillar.items apache
salt -I 'apache:httpd' cmd.run 'w'    #-I 用pillar的key:value来匹配

        类型      数据收集方式      应用场景                        定义位置
Grains  静态  minion启动时收集    数据查询    目标选择     配置管理   minion端
Pillar  动态  master自定义       目标选择     配置管理    敏感数据    master端


主机名 redis-node01-redis04-idc01-soa.domain.com

redis-node01    #redis第一个节点
redis04         #集群
idc04           #机房
soa             #业务


匹配方式 所有的匹配目标方式都可以在top file里指定目标
salt '*' cmd.run 'w'                        #通配符
salt 'vm-1-81' cmd.run 'w'                  #指定
salt -L 'vm-1-81,vm-1-82' cmd.run 'w'       #列表
salt -E 'vm-1-(81|82)' cmd.run 'w'          #正则
salt -G 'os:CentOS' cmd.run 'w'             #Grains 匹配
salt -I 'apache:httpd' cmd.run 'w'          #Pillar的key:value来匹配

/etc/salt/master 里nodegroups 分组标识        #-N master配置文件中分组执行
salt '*' -b 10 cmd.run 'w'                  #指定一次要执行的数量

salt '*' state.show_top     #top files

salt '*' state.single pkg.installed name=nginx

编写模块
位置
mkdir /srv/salt/_modules

命名 文件名就是模块名

vim my_disk.py
def list():
  cmd = 'df -Th'
  ret = __salt__['cmd.run'](cmd)
  return ret

刷新 salt '*' saltutil.sync_modules



pkg.installed       #安装
pkg.latest          #确保最新
pkg.remove          #卸载
pkg.purge           #卸载并删除配置文件


common_packages:
  pkg.installed:
    - pkgs:
      - unzip
      - dos2unix
      - salt-minion: 2016.3.8

LAMP 配置
软件安装 管理配置文件 状态管理
pkg.installed
file.managed
service.running


lamp-pkg:
  pkg.installed:
    - pkgs:
      - httpd
      - php
      - mysql
      - mariadb-server
      - php-mysql
      - php-cli
      - php-mbstring

apache-config:
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://lamp/files/httpd.conf
    - user: root
    - group: root
    - mode: 644

php-config:
  file.managed:
    - name: /etc/php.ini
    - source: salt://lamp/files/php.ini
    - user: root
    - group: root
    - mode: 644

mysql-config:
  file.managed:
    - name: /etc/my.cnf
    - source: salt://lamp/files/my.cnf
    - user: root
    - group: root
    - mode: 644

apache-service:
  service.running:
    - name: httpd
    - enable: True
    - reload: True

mysql-service:
  service.running:
    - name: mariadb
    - enable: True
    - reload: True



salt:// 以master配置文件的file_roots: base: /srv/salt/ 路径为基准

salt://lamp/files/my.cnf 完整路径表示 /srv/salt/lamp/files/my.cnf

执行单个状态文件
salt 'vm-1-81' state.sls lamp.lamp



apache-service:
  pkg.installed:
    - pkgs:
      - httpd
      - php

  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://lamp/files/httpd.conf
    - user: root
    - group: root
    - mode: 644

   service.running:
     - name: httpd
     - enable: True
     - reload: True

mysql-service:
  pkg.installed:
    - pkgs:
      - mariadb
      - mariadb-server

  file.managed:
    - name: /etc/my.cnf
    - source: salt://lamp/files/my.cnf
    - user: root
    - group: root
    - mode: 644

  service.running:
    - name: mariadb
    - enable: True
    - reload: True
##############################################

lamp-pkg:
  pkg.installed:
    - pkgs:
      - httpd
      - php
      - mysql
      - mariadb-server
      - php-mysql
      - php-cli
      - php-mbstring

apache-config:
  file.managed:
    - name: /etc/httpd/conf/httpd.conf
    - source: salt://lamp/files/httpd.conf
    - user: root
    - group: root
    - mode: 644

apache-service:
  service.running:
    - name: httpd
    - enable: True
    - reload: True
    - require:              #此apache服务运行需要依赖lamp-pkg这个模块
      - pkg: lamp-pkg
    - watch:                #监控当apache配置文件发生改变时候 执行reload 若reload没有执行restart
      - file: apache-config

我依赖谁    require
  Apache 依赖lamp-pkg 这个模块 并且依赖apapche-config

我被谁依赖  require_in

我监控谁    watch
  如果监控文件修改 需要做出相应动作
  如果apache-config这个id的状态发生改变就reload
  如果没有reload:True 那么就restart


我被谁监控   watch_inc

我引用谁
我扩展谁

unless  如果后边这条命令返回为真 则不执行
unless test -L /usr/local/haproxy
如果 haproxy此链接存在则 不执行 cmd.run 中命令
否则每次执行state.sls 都会执行cmd.run下命令



include:
  - lamp.pkg

 lamp  为top files里定义的文件夹 如/srv/salt/ 下lamp文件夹
 pkg   为lamp文件夹下pkg.sls文件

salt 'vm-1-81' state.sls lamp.init
  执行lamp文件夹下的init.sls文件


JinJa2模板

告知file模块 使用jinja2
- template: jinja2

列出参数列表
- defaults:
  port: 88

模板中引用   xxx.conf
模板支持 salt grain pillar

- template:jinja2
- defaults:
  PORT: 88
  IPADDR: {{ grains['fqdn_ip4'][0] }}




#jinja2 grain
listen {{ grains['fqdn_ip4'][0] }}:{{ PORT }}


#salt远程执行功能 network模块 hw_addr方法 eth0参数
{{ salt['network.hw_addr']('eth0') }}

salt '*' network.hw_addr eth0
  network 模块
  hw_addr 方法
  eth0    为方法中传入的参数

#pillar /srv/pillar
{{ pillar['apache'] }}





/etc/profile:
  file.append:
    - text:
      - export HISTTIMEFORMAT="%F %T `whoami` "

file.append 文件末尾追加

net.ipv4.ip_local_port_range:
  sysctl.present:
    - value: 10000 65000

sysctl.present   sysctl模块

###################################################################

Haproxy(M)-------------------keepalive-----------------------Haproxy(S)
                                vip
                       Nginx++++++++++++++PHP

         MySQL(master)----------------------------MySQL(salve)


系统初始化

功能模块: 设置单独目录 haproxy nginx php mysql memcached
  尽可能全 独立

业务模块: 所有模块 配置 单独管理 web
  include 功能模块


环境
开发 测试 功能测试 性能测试 预生产 生产

base 基础环境
init目录 环境初始化
  dns配置
  history记录时间
  记录命令操作
  内核参数优化
  安装yum仓库
  安装zabbix agent

vim /etc/salt/master

file_roots:
  base:
    - /srv/salt/base
  prod:
    - /srv/salt/prod

pillar_roots:
  base:
    - /srv/pillar/base
  prod:
    - /srv/pillar/prod

mkdir /srv/salt/base -p
mkdir /srv/salt/prod

mkdir /srv/pillar/base -p
mkdir /srv/pillar/prod

systemctl restart salt-master
mkdir /srv/salt/base/init
cd /srv/salt/base/init/


salt '*' saltuit.refresh_pillar
salt '*' pillar.items
salt '*' pillar.get zabbix-agent:Zabbix-Server

salt '*' grains.items
salt '*' grains.item fqdn
salt '*' grains.item fqdn_ip4

salt '*' state.sls init.epel test=True
salt '*' state.show_top
salt '*' state.highstate



Prod
cd /srv/salt/prod
mkdir haproxy memcached nginx php pkg keepalived

salt '*' state.sls haproxy.install saltenv=prod

#这个模块下主要是描述service状态的函数，running状态函数表示apache在运行，省略-name不在表述，
-require表示依赖系统，依赖系统是state system的重要组成部分，
在该处描述了apache服务的运行需要依赖apache软件的部署，这里就要牵涉到sls文件的执行，
sls文件在salt中执行时无序(如果没有指定顺序，后面会讲到order)，
假如先执行了service这个状态，它发现依赖pkg包的安装，会去先验证pkg的状态有没有满足，
如果没有依赖关系的话，我们可以想象，如果没有安装apache，apache 的service肯定运行会失败的，
我们来看看怎么执行这个sls文件:

#ssh/init.sls 意思是当执行 salt '*' state.sls ssh的时候其实就是执行init.sls

include:
  - ssh
#include表示包含意思，就是把ssh/init.sls直接包含进来





