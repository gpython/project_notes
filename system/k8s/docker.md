##### 安装docker-ce
```bash
cd /etc/yum.repos.d
wget https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/docker-ce.repo

vim docker-ce.repo
#% s#https://download.docker.com/#https://mirrors.tuna.tsinghua.edu.cn/docker-ce/#g

yum repolist
yum install yum-utils device-mapper-persistent-data lvm2 bridge-utils
yum install docker-ce
mkdir /etc/docker/
vim /etc/docker/daemon.json
#添加镜像加速器
{
  "registry-mirrors":["https://registry.docker-cn.com"]
}

systemctl start docker.service 

docker version
docker info



```

##### docker 程序环境
- 环境配置文件
  - /etc/sysconfig/docker-network
  - /etc/sysconfig/docker-storage
  - /etc/sysconfig/docker

- Unit File
  - /usr/lib/systemd/system/docker.service
 
- docker Registry配置文件
  - /etc/containers/registries.conf
 
- docker-ce 配置文件
  - /etc/docker/daemon.json
 
##### 常用操作
- docker search
  - docker search nginx
- docker image  pull  下载镜像
  - docker image pull nginx:1.14.0-alpine 
  - docker imgage ls 
  - docker image ls --no-trunc
- docker run --name b1 -it busybox:latest
- docker run --name ng1 -d nginx:1.14.0-alpine
- docker run --name red1 -d redis:4-alpine 
  - 若镜像没有 这到仓库中下载 并运行
 
- docker inspect ng1

- docker exec -it red1 /bin/sh
- docker exec -it ng1 /bin/sh
  - 以交互方式登录进 redis nginx 查看
- docker logs ng1
  - 查看日志 每个容器运行一个进程 默认日志直接输出到控制台
- docker commit -a "Author <author_name@xx.com>" -c 'CMD ["/bin/httpd", "-f", "-h", "/data/html"]' -p docker_name registry_namespace/registry:version
  - 镜像修改 并指定运行时命令
 
- docker save -o backup_image_name.gz registry.domain.com/image_name:version
  - 镜像打包 可以同时打包多个镜像
  
- docker load -i back_image_name.gz 
  - 镜像载入 

- -p <containerPort>
  - 将 容器指定地址 映射为 物理机任意地址 80/tcp -> 0.0.0.0:32771
- docker run --rm --name ng2 -p 80 nginx:1.14.0-alpine
- docker port ng2
 
- -p <hostPort>:<containerPort>
  - 容器端口 映射为 主机指定端口
- -p <IP>::<containerPort> 
  - 指定容器端口 映射为 主机随机端口
- -p <IP>:<hostPort>:<containerPort>
  - 指定容器端口 映射为 主机指定端口
 
 
 
- docker network create -d bridge --subnet "10.10.10.0/24" --gateway "10.10.10.1" net_name  
- ip link set dev  need_change_br-name  name you_want_name
 
 
- 挂载卷
- -v <Host dir>:<container dir>
- docker run --name ng1 -it --rm -v /data/docker/data/ng:/data busybox 
- docker run --name ng2 -it --rm -v /data/docker/data/ng:/data busybox
  - 多个容器卷使用同一个主机目录
  
- docker run -it --name b1 --rm -v /data/docker/data/ng:/data busybox
- docker run -it --name b2 --rm --volumns-fromb1 buxybox
 -- 复制使用其他容器的卷 使用--volumns-from选项
 
- ${name:-google}
  - 变量name没有值 则赋默认值 google 否则变量${name}值
- ${name:+google}
  - 变量name若有值 则更改其值为 google  否则为空
 
 
 
###### Dockerfile
```html
FROM busybox:latest
MAINTAINER "root <root@toor.sh>"
#拷贝当前主机目录下index.html文件到容器目录下
COPY index.html /data/web/html
#拷贝 yum.repos.d 目录下所有文件到 /etc/yum.repos.d/ 目录下
COPY yum.repos.d /etc/yum.repos.d/




#ADD指令
如果 <src>为url 且<dst> 不以/结尾 则src指定的文件将被下载并直接被创建为dst
如果 <dst>以/结尾  则文明名url指定的文件将直接下载并保存为<dst>/<filename>
如果 <src>为一个本地系统上的压缩格式的tar文件 将被展开为一个目录 行为类似于tar -x 
通过url获取到的tar文件不会自动展开

如果<src>有多个 或其直接或间接使用了通配符 <dst>必须是一个以/结尾的目录路径
如果<dst>不以/结尾 则被视为一个普通文件 <src>内容将被直接写入到<dst>

#构建镜像 也可指定CPU 内存 限制条件
docker build -t  minihttp:v1.1.1 ./
```
 
 
 
 
 
 
##### 网络
- yum install bridge-utils 
- brctl show
- wget -O - -q http://172.17.0.2  # -O 内容加载完成不保存到文件直接显示 - 输出到当前终端 
- docker network inspect bridge 




###
镜像
yum install docker
systemctl start docker

查看镜像

docker images

搜索镜像

docker search nginx

拉取镜像

docker pull docker.io/centos

将镜像打包保存

docker save -o centos.tar centos

打包的镜像还原

docker load --input centos.tar

启动容器并运行 输出hello world

docker run centos /bin/echo "Hello world"

docker 容器必须前台运行个进程 否则运行完后容器直接退出
查看所有运行和不运行的进程 
docker ps -a

运行容器 最好给每一个运行的容器起一个名字 以用来区分启动的不同容器
docker run centos /bin/echo "Hello World"

新建一个指定名称--name simple_docker-container_name的容器 
镜像为centos 在所有选项后边
-t 分配伪终端 
-i 标准输入打开 要在容器中输入命令 
如果最后一个不是命令的话 最有一个永远是镜像的名称

docker run --name simple_docker_container_name -it  centos  /bin/bash

可以查看到运行的容器内进程PID 1 为docker run 最后指定的命令
当指定的进程结束后 容器就结束
容器是为了给进程做隔离使用的 进程结束后容器便结束
虚拟机是为了给操作系统做隔离使用
exit退出容器后 容器就变成关闭状态
容器内执行 ps aux 


docker run --name my_centos_2 -it centos /bin/bash

进入某个容器
docker attach my_centos_2

两个终端中执行的命令是相同的 exit 两个终端都退出了 单用户模式

比较靠谱的进入容器方式 进入命名空间
yum install util-linux
通过相应容器的PID进入容器
nsenter 

docker inspect -f "{{ .State.Pid }}" 容器名称
docker inspect -f "{{ .State.Pid }}" my_centos_3

nsenter -t 1881 -m -u -i -n -p

ps aux

nsenter 在容器内又创建了一个进程 不影响PID=1的进程


快速进入容器 不影响容器
docker_in(){
  name_id=$1
  pid=$(docker inspect -f "{{ .State.Pid }}" $name_id)
  nsenter -t ${pid} -m -u -i -n -p
}

docker_in $1

不进入容器 执行命令 docker exec
docker exec -it my_centos_4 /bin/bash

删除容器
docker rm

删除镜像
docker rmi

运行后直接退出
docker run --rm centos /bin/echo "google"


docker run --name -h hostname

docker stop container ID

docker ps -al

docker exec |docker attach | nsenter

docker rm 


nginx运行在前台 日志可直接打印 
-P 随机映射端口
docker run --name nginx_1 -d -P nginx

docker logs nginx_1

-p 物理机端口:容器内端口 指定端口映射
docker run -d -p 81:80 --name nginx_81 nginx

查看端口映射
docker port nginx_81

数据卷
-v 挂在目录 一个参数 在容器中创建的目录
-v 两个参数 宿主机目录:容器内目录


docker run -d --name nginx_2 -v /data/volumn/nginx_2:/data nginx
docker run -d --name nginx_82 -p 82:80 -v /data/volumn/nginx_82:/data nginx

数据卷容器 一个容器可以访问到另一个容器的数据 不论容器是否运行
--volumn-from

docker run -it --name my_centos_5 --volumes-from nginx_2 centos /bin/bash

所有容器的pid
docker ps -a -q
所有运行容器的pid
docker ps -q




Dockerfile
镜像构建 Dockerfile文件的当前目录下

vim Dockerfile
```html

#This Dockerfile

#base image
FROM centos

#maintainer
MAINTAINER zhn

#commands
RUN　rpm -ivh http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
RUN yum install -y nginx && yum clean all
RUN echo "daemon off" >> /etc/nginx/nginx.conf
ADD index.html /usr/share/nginx/html/index.html
#暴露的端口
EXPOSE 80
#运行的命令 nginx
CMD ["nginx"]
```


构建镜像 镜像名称 版本 使用当前目录下的Dockerfile构建
docker build -t mynginx:v2 .

docker build -t wordpress:v2 .


FROM            指定基础镜像 Dockerfile内第一条命令

MAINTAINER      维护者

RUN             运行命令

ADD             copy文件 正规压缩文件会自动解压

WORKDIR         设置当前工作目录 切换目录 为后续的RUN CMD ENTRYPOINT指令配置工作目录
                也可以使用多个WORKDIR 若后续参数为相对路径 则会目录累加
                最好使用绝对路径

VOLUME          设置卷 挂载主机目录

EXPOSE          指定对外开放的端口 若外部访问 容器启动时候还需要增减-P或-p

ENV             设置环境变量 可以在RUN之前使用 然后RUN命令时调用 容器启动时这些环境变量都会被指定

CMD             指定容器启动后要干的事情 每个Dockerfile内只能有一个CMD 若多个最后一个执行
                若在启动容器的时候也指定命令 那么会覆盖Dockerfile构建的镜像里面的CMD命令
                
ENTRYPOINT      和CMD一样 若多个最后一个执行 但是不可被docker run提供的参数覆盖
                也就是启动容器的时候 增加运行的命令不会覆盖ENTRYPOINT指定的命令      

ONBUILD         在build构建当前镜像的时候不生效 当生成的镜像 被其他的Dockerfile FROM的时候
                在下一个镜像里边生效  并在FROM后边 开始执行ONBUILD 里的命令






SSHD配置
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
RUN echo "root:root" | chpasswd


registry
Harbor

Registry

registery_url/namespace/image_name:tag

修改docker镜像的名称 tag
docker tag 原始镜像名称 修改后镜像名称

docker tag nginx:v1 192.168.1.90:5000/doc/nginx:v1.0

NameSpace
PID
IPC
Mount
UTS
User
Nat

网络模式
nat
host
oterh container
none
overlay


host 模式和docker宿主机 网络一样

other container 模式 容器间共享网络namespace

docker run -it --name busybox_2 busybox sh
docker run -it --name busybox_3 --net=container:busybox_2 busybox sh

busybox_3容器共享busybox_2的网络 两个容器的网络相同 即是busybox2的网络


overlay 模式 








Shell
set -e
shell脚本中添加 set -e 当脚本在执行时出现错误 脚本就不会继续往下执行 终止 退出


.dockerignore Dockerfile忽略的文件

init.sh脚本最后 有exec "$@"
vim init.sh
exec "$@"

则执行完init.sh 后 执行后续的命令
bash init.sh /usr/bin/supervisord -n -c /etc/supervisord.conf



```html
#在filter表中创建IN_WEB自定义链
iptables -N IN_WEB

#自定义链规则
iptables -I IN_WEB -s 192.168.9.91 -j REJECT
iptables -I IN_WEB -s 192.168.10.198 -j ACCEPT

#在INPUT链中引用刚才创建的自定义链 INPUT调用自定义链
iptables -I INPUT -p tcp --dport 80 -j IN_WEB

#return
#子链――>父链――>缺省的策略。
#具体地说，就是若包在子链 中遇到了RETURN，则返回父链的下一条规则继续进行条件的比较，
#若是在父链（或称主链，比如INPUT）中 遇到了RETURN，就要被缺省的策略（一般是ACCEPT或DROP）操作了
iptables -N CHAIN_NAME 自定义链

iptables -A CHAIN_NAME -d 192.168.1.1 -j DROP
iptables -A CHAIN_NAME -d 192.168.1.1 -j RETURN ##返回父链

#INPUT调用CHAIN_NAME

iptables -I INPUT -j CHAIN_NAME

```

