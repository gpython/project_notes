####基础环境#######
# 停防火墙
systemctl stop firewalld
systemctl disable firewalld

#关闭Swap
swapoff -a
sed -i 's/.*swap.*/#&/' /etc/fstab

#关闭Selinux
setenforce  0
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config

#加载br_netfilter
modprobe br_netfilter

#添加配置内核参数
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
#加载配置
sysctl -p /etc/sysctl.d/k8s.conf

#查看是否生成相关文件
ls /proc/sys/net/bridge

# 添加K8S的国内yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

#安装依赖包以及相关工具
yum install -y epel-release
yum install -y yum-utils device-mapper-persistent-data lvm2 net-tools conntrack-tools wget vim  ntpdate libseccomp libtool-ltdl

#配置ntp（配置完后建议重启一次）
systemctl enable ntpdate.service
echo '*/30 * * * * /usr/sbin/ntpdate time7.aliyun.com >/dev/null 2>&1' > /tmp/crontab2.tmp
crontab /tmp/crontab2.tmp
systemctl start ntpdate.service

# /etc/security/limits.conf 是 Linux 资源使用配置文件，用来限制用户对系统资源的使用
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 65536"  >> /etc/security/limits.conf
echo "* hard nproc 65536"  >> /etc/security/limits.conf
echo "* soft  memlock  unlimited"  >> /etc/security/limits.conf
echo "* hard memlock  unlimited"  >> /etc/security/limits.conf


#######
kube-apiserver
kube-controller-manager
kube-scheduler
apiserver.sh
controller-manager.sh
scheduler.sh
kubectl
###############################

环境
    master, etcd 192.168.1.93
    node1   192.168.1.94
    node2   192.168.1.95

前提
    基于主机名通信   /etc/hosts
    192.168.1.93 kubernet-master
    192.168.1.94 kubernet-node-1
    192.168.1.95 kubernet-node-2

    时间同步
    echo '*/30 * * * * /usr/sbin/ntpdate time7.aliyun.com >/dev/null 2>&1' > /tmp/crontab2.tmp
    crontab /tmp/crontab2.tmp
    /usr/sbin/ntpdate time7.aliyun.com

    关闭firewalled iptables.service

安装配置
    etcd cluster master节点
    flannel 集群 所有节点
    配置k8s master节点
        kubernetes-master
        启动服务
          kube-apiserver kube-scheduler kube-controller-manager

    配置k8s各node节点
        kubernetes-node
        先设定启动docker服务
        启动k8s服务
            kube-proxy kubelet

kubeadm
    master nodes: 安装 kubelet kubeadm docker
    master: kubeadm init
    nodes:  kubeadm join


cd /etc/yum.repos.d
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

yum repolist

scp kubernetes.repo docker-ce.repo 192.168.1.94:/etc/yum.repos.d/
scp kubernetes.repo docker-ce.repo 192.168.1.95:/etc/yum.repos.d/

#Master Nodes:都需要安装
yum install docker-ce-18.06.1.ce kubelet-1.11.3 kubeadm-1.11.3 kubectl-1.11.3


vim /usr/lib/systemd/system/docker.service

#使用代理方式获取墙外镜像
Environment="HTTPS_PROXY=http://192.168.10.1:9919"
Environment="NO_PROXY=127.0.0.1/8,172.20.0.0/16"

systemctl daemon-reload
systemctl start docker

docker info
rpm -ql kubelet

Swap设置
cat /etc/sysconfig/kubelet



systemctl enable kubelet
systemctl enable docker
kubeadm init --help

#Kubeadm init 初始化 拉取相关镜像
kubeadm init  --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --ignore-preflight-errors all

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get cs

kubectl get nodes


#部署网络插件 flannel 拉取flannel镜像 并启动
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

kubectl get nodes

查看名称空间 系统级的pods都在kube-system名称空间中
kubectl get ns

获取指定 系统级名称空间 kube-system的pods信息
kubectl  get pods -n kube-system
kubectl  get pods -n kube-system -o wide



#Nodes节点上执行 加入到master中
#修改docker 启动配置文件
vim /usr/lib/systemd/system/docker.service
#使用代理方式获取墙外镜像
Environment="HTTPS_PROXY=http://192.168.10.1:9919"
Environment="NO_PROXY=127.0.0.1/8,172.20.0.0/16"

systemctl enable docker
systemctl start docker
systemctl enable kubelet

#Nodes加入到kube集群
kubeadm join 192.168.1.93:6443 --token z5iekm.4qew53d7k606vm4s --discovery-token-ca-cert-hash sha256:87e9c89efa08b575d20ccd3b04aec86df3ef5735377ec9248f2adb7b1434d70b




Master节点 kubectl相关操作

#Pod:
kubectl --help

kubectl run nginx-proj --image=nginx --port=80 --replicas=1

kubectl get deployment

kubectl get pods

kubectl get pods -o wide

kubectl delete pods nginx-proj-6c45b5788f-dcltj

#Service:
kubectl expose deployment nginx-pro --name=nginx
kubectl get svc
kubectl describe svc nginx
kubectl get pods --show-labels

kubectl edit svc nginx



kubectl run myapp --image=nginx --replicas=2
kubectl get deployment
kubectl get deployment -w
kebuctl get pods -o wide
kubectl expose deployment myapp --name=myapp --port=80

wget -O - -q myapp/

#动态扩展 或缩小
kubectl scale --replicas=5 deployment myapp

#Replicaset
#Deployment
#Statefulet
#daemonset
#Job
#cronjob
#Node





kubectl run client --image=busybox --replicas=1 -it --restart=Never
kubectl get pods

dig -t A nginx.default.svc.cluster.local @10.96.0.10

Service
#使用 nginx-pro pods创建名称为nginx-1的Service
kubectl expose deployment nginx-pro --name=nginx-1 --port=80 --target-port=80 --protocol=TCP

     创建服务                pod名称    Service 名称
kubectl expose deployment nginx-pro --name=nginx-1 --port 80 --target-port=80 --protocol=TCP

#查看所有服务
kubectl get svc

#查看 nginx 服务描述
kubectl describe svc nginx

#编辑服务
kubectl edit svc nginx

#删除服务
kubectl delete svc nginx


kubectl scale --replicas=2 deployment nginx-pro

#更新镜像 更改镜像
kubectl set image deployment myapp myapp=daocloud/myapp:v2
#显示 更改状态
kubectl rollout status deployment myapp

#回滚 到上一个版本
kubectl rollout undo deployment myapp

kubectl get pods




ClusterIP NodePort

client -> NodeIP:NodePort -> ClusterIP:ServicePort -> PodIP:ContainerPort

























































kube-controller 进程通过资源对象RC上定义的Label Selector来筛选要监控的Pod副本的数量
从而实现Pod副本的数量始终符合预期设定的全自动控制流程

Kube-proxy进程通过Servie的Label selector来选择对应的Pod 自动建立起每个service到对应的pod的请求转发路由表
从而实现servie的智能负载均衡机制

通过对某些node定义特定的Label 并且在pod定义文件中使用nodeselector这种标签调度策略
kube-scheduler进程可以实现pod定向调度特性


Replication Controller RC
定义一个期望的场景 声明某种Pod的副本数量在任意时刻都符合某个预期值
Pod 期待副本数量 replicas
用于筛选目标pod的Label Selector
当Pod副本数量小于预期数量的时候 用于创建新Pod的Pod模板 template


定义RC实现Pod的创建过程及副本数量的自动控制
RC里包括完整的Pod定义模板
RC通过label Selector 机制实现对Pod副本的自动控制
通过改变RC里Pod副本数量 实现Pod扩容或缩容功能
通过改变RC里Pod模板中镜像版本 实现Pod滚动升级功能



Deployment 为了更好的解决Pod编排问题
Deployment在内部使用Replica Set来实现
Deployment 相对于RC一个最大升级是我们可以随时知道当前Pod部署 进度


创建Deployment对象来生成对应的Replica Set并完成Pod副本创建过程
检查Deployment状态来看部署是否完成 Pod副本数量是否达到预期的值
更新Deployment 以创建新的Pod 镜像升级
当前Deployment不稳定 可以回滚到早前Deployment版本


HPA Pod横向自动扩容
通过追踪分析RC控制器的所有目标Pod的负载变化情况 来确定是否需要针对性的调整目标Pod的副本数量

HPA可以有以下两种方式作为Pod负载度量标准
  CPUUtilizationPercentage
  应用程序自定义度量标准 比如服务每秒内相应请求书 TPS QPS

  CPUUtilizationPercentage = 当前Pod 的CPU使用量/Pod 的Pod Request值


Service
service 定义了一个服务的访问入口地址
前端应用Pod 通过这个入口地址访问其背后的一组由Pod副本组成的集群服务
Service 与其后端的Pod副本集群之间是通过Label Selector来实现无缝对接的
RC的作用是保证Service的服务能力和服务质量始终处于预期标准


Pod IP   Docker Engine根据doker0网桥IP地址段进行分配
  不同node上pod能够彼此直接通信

Node IP  集群中每个节点的物理网卡的IP地址

Cluster IP
  Service IP
  仅用于kubernetes Service对象 并由Kubernetes管理和分配IP地址
  Cluster IP 无法ping 没有实体网络来响应



Kubernetes中Volume定义在Pod上 被一个Pod里多个容器挂载到具体的文件目录下
Kubernetes中Volume与Pod的生命周期相同 与容器生命周期不相关

emptyDir 是在Pod分配到Node时创建的 初始内容为空 无须指定宿主机上对应目录文件
因为是Kubernetes自动分配的一个目录 当Pod从Node上移除时 emptyDir数据会永久删除

临时空间 某些应用程序运行时所需的临时目录 无需永久保留
长时间任务的中间过程

hostPath为在Pod上挂载宿主机上的文件或目录



Namespace
  在很多情况下用于实现多租户的资源隔离
















