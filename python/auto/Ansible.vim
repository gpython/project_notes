
配置文件 /etc/ansible/ansible.cfg
主机池  /etc/ansible/hosts

ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.1.81

ansible-doc -l
ansible-doc -s yum

ansible <host-pattern> [-f fork] [-m module_name] [-a args]
-f forks 启动的并发线程数
-m module_name 使用的模板
-a args 模块特有参数

cron:
  state:
    present: 安装
    absent:  移除

cron
ansible all -m cron -a 'minute="*/10" job="/bin/echo hell" name="test cron job"'
ansible all -a 'crontab -l'
ansible all -m cron -a 'minute="*/10" job="/bin/echo hell" name="test cron job" state=absent'

user
ansible all -m user -a  'user=user1 uid=306 system=yes group=user1'
ansible all -m user -a  'user="user1" state=absent'
ansible all -a "tail -n 1 /etc/passwd"

group
ansible all -m group -a 'name=mysql gid=306 system=yes'

copy
 src = 定义本地源文件路径 相对或绝对
 dest = 定义远程目标文件路径 绝对
 content = 取代src 表示直接用此处指定的信息生成目标文件内容
ansible all -m copy -a 'src=/etc/passwd dest=/tmp/passwd-ansible owner=root mode=644'

file
ansible all -m file -a "owner=nobody group=nobody mode=600 path=/tmp/passwd-ansible"
file 链接文件 pwd-link -> /tmp/passwd-ansible
ansible all -m file -a "path=/tmp/pwd-link src=/tmp/passwd-ansible state=link"

service
 enable 开机启动
 name 服务名
 state start
ansible all -m service -a "enabled=true name=httpd state=started"

用户创建 并创建密码
ansible all -m group -a "name=john gid=1000"
ansible all -m user -a "name=john group=john"
ansible all -m shell -a "echo passwd | passwd --stdin john"

shell
 在远程主机上运行命令 尤其是用到管道等复杂命令

script
 将本地脚本复制到远程主机并运行 本地脚本相对路径

yum
 name 软件程序包 可以带版本号
 absent 卸载
ansible all -m yum -a "name=zsh"
ansible all -m yum -a "name=zsh state=absent"

setup
 收集远程主机的facts
 setup变量可以直接 调用 解析 无需声明

- host: web
  remote_user: root
  tasks:
    - name: copy file
      copy: content="{{ ansible_all_ipv4_address }}" dest=/tmp/var.ans

yaml
 序列里的项 用 "-" 来表示
 Map 里的键值用 ":" 来表示

- hosts: webnodes
  vars:
    http_port: 80
    max_client: 256
  remote_user: root
  task:
    - name: ensure apache is at latest version
      yum: name=httpd state=latest
    - name: ensure apache
      service: name=httpd state=started
  handlers:
    - name: restart apache
      service: name=httpd state=restarted
       模块名    key value

host 指定要执行指定任务的主机 可以是一个或多个由冒号分割的主机组
remote_user 用于指定远程主机上执行任务的用户
task 任务执行 以此在所有主机上执行完第一个任务再执行第二个任务
service: name=httpd state=restart
模块名    名称 执行状态

只有shell 和command 模块仅需要给定一个列表 无需使用key=value格式

- host: webserver
  remote_user: root
  tasks:
    - name: create nginx group
      group: name=nginx system=yes gid=1001
    - name: create nginx user
      group: name=nginx uid=1001 group=nginx system=yes

- host: dbserver
  remore_user: root
  tasks:
    - name: copy file to dbserver
      copy: src=/etc/passwd dest=/tmp/passwd-an

handlers
 用于当关注的资源发生变化时 采取一定的操作

notify
 这个action 可用于在每个play的最后被触发 这样可以避免多次有改发生时都执行指定的操作
 取而代之 仅在所有的变化都完成后一次性的执行指定操作
 在notify中列出的操作称为handler 也即notify中调用handler中定义的操作

- name: template configuration file
  template: src=template.j2 dest=/etc/foo.cnf
  notify:
    - restart memcached
    - restart apache

所有变化都完成后一次性执行指定操作
notify触发以下handlers中的task
handler是task列表 这些task与前述的task并没有本质上不同

handlers:
  - name: restart memcached
    service: name=memcached state=restarted
  - name: restart apache
    service: name=apache state=restarted


#配置文件发生改变 触发 restart handlers
#变量 vars 下声明 setup中变量可以直接使用 "{{ setup vars }}"
#host中定义的主机变量也可以直接使用

- host: web
  remote_user: root
  vars:
    - package: httpd
    - service: httpd
  tasks:
    - name: install httpd apache
      yum: name={{ package } state=latest

    - name: install config file for httpd
      copy: src=/root/conf/httpd.conf dest=/etc/httpd/conf/httpd.conf
      notify:
        - restart httpd

    - name: start httpd service
      service: enabled=true name={{ service }} state=started

  handlers:
    - name: restart httpd
      service: name={{ service }} state=restarted

条件变量 when
 tasks后添加when条件变量
 when 变量可以是setup中key 无需{{}}包裹

ansible-playbook con.yaml


with_items
 当需要有重复的执行任务时 可以使用迭代机制 格式为将需要迭代的内容定义为item变量引用
 并通过with_items语句来指明迭代元素列表即可

- name: create several users
  user: name={{ item }} starte=present groups=wheel
  with_items:
    - create_user1
    - create_user2

上边语句等同于
- name: create user1
  user: name=create_user1 state=present groups=wheel
- name: create user2
  user: name=create_user2 state=present groups=wheel

with_items 可以使用元素为字典类型
- name: create several users
  user: name={{ item.name }} state=present groups={{ item.groups }}
  with_items:
    - { name: 'create_user1' groups: 'wheel'}
    - { name: 'create_user2' groups: 'wheel'}

tags
 在playbook中可以为某个或某些任务定义一个标签 在执行此playbook时
 通过ansible-playbook命令使用 --tag选项能实现仅运行指定的tasks 而非所有

- name: install config file for httpd
  template: src=/root/httpd/httpd.conf.j2 dest=/etc/httpd/conf/httpd.conf
  tags:
    - conf
特殊tags always  无论任何时候都运行


role
 创建以roles命名的目录
 在roles目录中分别创建以各角色名称的目录 如nginx mysql webserver
 在每个角色命名的目录中分别创建 files handlers meta tasks templates 和vars目录 用不到的可以不创建或为空
 在playbook文件中调用各角色

role中各目录可用文件
 tasks目录 至少包含一个名为main.yml的文件 定义角色任务列表 可以使用include包含其他的位于此目录中的task文件
 files目录 存放有copy或script等模块调用的文件
 templates目录 template模块会自动在此目录中寻找jinja2模板文件
 handlers 此目录中应当包含一个main
 yml文件 用于定义此角色用到的各handler 在handler中使用include包含的其他的handler文件也应位于此目录
 vars目录 包含一个main.yml文件 用于定义此角色用到的变量
 meta目录 包含一个main.yml文件 用于定义此角色的特殊设定及其他依赖关系
 default目录 为当前角色设定默认变量时使用此目录 应当包含一个mian.yml文件

mkdir -pv ansible_playbooks/rols/{nginx, mysql}/{tasks, files, templates, meta, handlers, vars}



















