Master 192.168.1.83
Node1  192.168.1.84
Node2  192.168.1.85

systemctl stop firrewalld && systemctl disable firewalld && setenforce 0
yum install -y epel-release

######部署master######

vim /etc/hosts
192.168.1.83 etcd
192.168.1.83 registry
192.168.1.83 k8s-master

使用yum安装etcd
etcd作为kubernetes集群的主数据库 在安装kubernetes各服务之前需要先安装和启动
yum -y install etcd

vim /etc/etcd/etcd.conf
#监控的网卡和接口
ETCD_LISTEN_CLIENT_URLS = "http://0.0.0.0:2379,http://0.0.0.0:4001"
#etcd数据库名字 maste
ETCD_NAME="master"
#用户访问时路径 在host中配置好的域名解析
ETCD_ADVERTISE_CLIENT_URLS="http://etcd:2379,http://etcd:4001"


启动并验证状态
systemctl start etcd

测试etcd数据库的可用性
etcdctl set testdir/testkey0 0
etcdctl get testdir/testkey0

#健康检查
etcdctl -C http://etcd:4001 cluster-health
etcdctl -C http://etcd:2379 cluster-health

安装docker
yum install docker
配置docker配置文件
vim /etc/sysconfig/docker
OPTIONS='--insecure-registry registry:5000'

#设置服务并开机启动
systemctl enable docker
systemctl start docker

安装kubernetes
yum install kubernetes -y

配置并启动kubernetes
在kubernetes master上运行以下组件
    Kubernetes API Server
    Kubernetes Controller Manager
    Kubernetes Scheduler

vim /etc/kubernetes/apiserver
#本地监控地址
KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"
#本地监控端口
KUBE_API_PORT="--PORT=8080"
#在etcd集群中以逗号分隔的节点列表
KUBE_ETCD_SERVERS="--etcd-servers=http://etcd:2379"
#kubernetes都支持那些控制器
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"


vim /etc/kubernetes/config
#kubernetes的controller-magaer scheduler 和proxy 联系apiserver的地址
KUBE_MASTER="--master=http://k8s-master:8080"

启动服务并设置开机启动
systemctl enable kube-apiserver.service
systemctl start kube-apiserver.service

systemctl enable kube-controller-manager.service
systemctl start kube-controller-manager.service

systemctl enable kube-scheduler.service
systemctl start kube-scheduler.service


######部署node######
vim /etc/hosts
192.168.1.83 registry
192.168.1.83 etcd
192.168.1.83 k8s-master
192.168.1.84 k8s-node-1

安装配置启动docker(两台node一样)
yum install -y docker
配置docker配置文件
vim /etc/sysconfig/docker
OPTIONS='--insecure-registry registry:5000'

#设置服务并开机启动
systemctl enable docker
systemctl start docker

安装配置启动kubernetes(两台node一样)
yum install kubernetes -y

配置并启动kubernetes
  在kubernetes node节点上需要运行以下组件
    Kubelet
    Kubernetes Proxy

vim /etc/kubernetes/config
#其他组件如何连接 apiserver节点
KUBE_MASTER="--master=http://k8s-master:8080"

vim /etc/kubernetes/kubelet
#kubernetes minion 监听地址
KUBELET_ADDRESS="--address=0.0.0.0"
#minion node 主机名称
KUBELET_HOSTNAME="--hostname-override=k8s-node-1"
#api server地址
KUBELET_API_SERVER="--api-servers=http://k8s-master:8080"

配置并启动服务 proxy没有配置 直接启动
systemctl enable kubelet.service
systemctl start kubelet.service

systemctl enable kube-proxy.service
systemctl start kube-proxy.service

查看状态 Master上操作
在Master上查看集群中节点及节点状态
kubectl -s http://k8s-master:8080 get node
kubectl get nodes



创建覆盖网络 -- Flannel
安装Flannel
  在master 和 node 上均执行如下命令 进行安装
yum install -y flannel

配置
在master和node上均编辑/etc/sysconfig/flanneld 进行配置

vim /etc/sysconfig/flanneld
#etcd数据库的地址 (若etcd数据安装在了独立的机器上 则此机器上也需要安装flannel)
FLANNEL_ETCD_ENDPOINTS="http://etcd:2379"

#配置etcd中关于flannel的key
#flannel使用etcd进行配置 来保证多个flannel实例之间的配置一致性 所以需要在etcd上进行如下配置
#'/atomic.io/network/config'这个key与上下文/etc/sysconfig/flanneld中的配置项FLANNEL_ETCD_PREFIX
#是相对应的 错误的话启动就出问题
#/atomic.io/network 指的是一个目录 在目录中创建配置文件 网络配置记录到配置文件中
FLANNEL_ETCD_PREFIX="/atomic.io/network"

管理员 配置 flannel使用network 并将配置保存在etcd中
在安装了etcd数据库的机器上操作
etcdctl mk /atomic.io/network/config '{"Network":"172.17.0.0/16"}'
刷新网络(部署的时候不使用 排错 时使用 或)
etcdctl update /automic.io/network/config '{"Network":"172.17.0.0/16"}'

在每个minion节点上 flannel启动 它从etcd中获取network配置 并为本节点产生一个subnet 也保存在etcd中
并且产生/run/flannel/subnet.env文件
FLANNEL_NETWORK=172.17.0.0/16 #这是全局的flannel network
FLANNEL_SUBNET=172.17.78.1/24 #这是本节点上flannel subnet
FLANNEL_MTU=1400              #本节点上flannel mtu
FLANNEL_IPMASQ=false

启动
启动flannel之后 要一次重启 docker kubernetes

master执行
systemctl enable flanneld.service
systemctl start flannel.service
systemctl restart docker
systemctl restart kube-apiserver.service
systemctl restart kube-controller-manager.service
systemctl restart kube-scheduler.service


重启所有服务
systemctl restart flanneld.service



Yaml
map指的是字典 即一个key:value的键值对
--- 为可选的分隔符 当需要在一个文件中定义多个结构的时候需要使用
maps的value即能够对应字符串 也能对应一个maps

使用yaml 创建pod

---
apiVersion: v1 #k8s master 节点的api server
kind:Pod           #创建的4种资源类型
metadata:           #元数据类型 描述类型
  name: dc-nginx    #名称随便
  labels:            #标签
    name: value      #一行 key value整体为一个标签
    name1: value1    #标签值不能为纯数字
spec:                #指定属性 典型的定义容器
  containers:       #容器属性 都是由列表指定 指定多个名称表示不同的容器
    - name: front-end           #容器名称
      image: nginx              #容器镜像位置
      ports:
        - containerPort: 80     #容器开放端口
    - name: other               #每个容器用自己的一套属性来表示
      image: nginx
      ports:
        - containerPort: 80

一个pod里可以包含多个容器 containers下可以指定多个容器key value
apiVersion 此处值v1 这个版本号需要根据安装的kubernets版本和资源类型进行变化 不是写死的
kind 可以是pod Deployment Job Ingress Service
spec 包含一些container storage volume 及其他kubernets需要的参数 诸如是否在容器失败时重新启动容器的属性
创建
kubectl create -f dc-nginx.yaml
查看
kubectl get pod dc-nginx
kubectl get pods
kubectl get pod dc-nginx -o wide  #查看pod运行在哪个节点上
验证yaml语法 --validate会告诉你发现的问题 但是仍然会按照配置文件的声明来创建资源
kubectl create -f ./xxx.yaml --validate

查看pods定义的详细信息
kubectl get pods -o yaml

kubectl get pod nginx-xsdr --output yaml

kubectl get支持以go template方式过滤指定的信息 比如查询pod的运行状态
kubectl get pods busybox --output=go-template --template={{.status.phase}}

进入pod对应的容器内部
kubectl exec -it myweb-xxx /bin/bash

删除单个pod
kubectl delete pod pod名
批量删除
kubectl delete pod --all

k8s通过Replication Controller来创建和管理各个不同的重复容器集合 实际上是重复的pods
Replication Controller会确保pod的数量在运行的时候会保持在一个特殊的数字 即replicas的设置

apiVersion: v1
kind: RepicationController
metadata:
  name: my-nginx
  labels:
    testrc: test-nginx-rc
spec:
  replicas: 2                   #pod模板 两个一模一样的pod
  template:
    metadata:
      labels:
        app: nginx
      spec:
        containers:
          - name: nginx
            image: nginx
            ports:
              - containerPort: 80


apiVersion: v1
kind: Pod
metadata:
  labels:
    name: test-hostpath
  name: test-hostpath
spec:
  containers:
    - name: test-hostpath
      image: daocloud.io/library/nginx
      volumeMounts:
        - name: testpath                #容器内挂载名称 想要挂载到真实的宿主机的卷 只需要名称和宿主机名称一样
          mountPath: /testpath          #容器内挂载点
  volumes:
    - name: testpath
      hostPath:
        path: /testpath

kebectl create -f testvolume.yaml



apiVersion: v1
kind: ReplicationController
metadata:
  name: x-nginx-rc
spec:
  replicas: 2
  selector:
    name: x-nginx
  template:
    metadata:
      labels:
        name: x-nginx
    spec:
      containers:
        - name: x-nginx
          image: daocloud.io/library/nginx
          ports:
            - containerPort: 80

apiVersion: v1
kind: Service
metadata:
  name: xp-nginx-service-nodeport
spec:
  ports:
    - port: 8001        #k8s集群内部访问的端口 集群外边无法访问
      targetPort: 80    #pod上对应容器的端口
      protocol: TCP
  type: NodePort
  selector:             #service给 哪个rc关联的
    name: nginx


kubectl get service
CLUSTER-IP 集群内部IP 外部无法访问
EXTERNAL-IP 外部扩展IP

nodePort是kubernets提供给集群外部客户访问service入口的一种方式 另一种是loadbalancer
nodeIP:nodePort是提供给集群外部客户访问service的入口

targetPort 是pod上的端口 从port和nodePort上到来的数据最终经过kube-proxy流入到后端pod的targetPort上进入容器






