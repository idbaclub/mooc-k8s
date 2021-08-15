# 二. 搭建高可用集群
## 1. 部署keepalived - apiserver高可用（任选两个master节点）
#### 1.1 安装keepalived
```bash
# 在两个主节点上安装keepalived（一主一备）
$ yum install -y keepalived
```
#### 1.2 创建keepalived配置文件
```bash
# 创建目录
$ ssh <user>@<master-ip> "mkdir -p /etc/keepalived"
$ ssh <user>@<backup-ip> "mkdir -p /etc/keepalived"

# 分发配置文件
$ scp target/configs/keepalived-master.conf <user>@<master-ip>:/etc/keepalived/keepalived.conf
$ scp target/configs/keepalived-backup.conf <user>@<backup-ip>:/etc/keepalived/keepalived.conf

# 分发监测脚本
$ scp target/scripts/check-apiserver.sh <user>@<master-ip>:/etc/keepalived/
$ scp target/scripts/check-apiserver.sh <user>@<backup-ip>:/etc/keepalived/
```

#### 1.3 启动keepalived
```bash
# 分别在master和backup上启动服务
$ systemctl enable keepalived && service keepalived start

# 检查状态
$ service keepalived status

# 查看日志
$ journalctl -f -u keepalived

# 查看虚拟ip
$ ip a
```

## 2. 部署第一个主节点
```bash
# 准备配置文件
$ scp target/<node-ip>/kubeadm-config.yaml <user>@<node-ip>:~
# ssh到第一个主节点，执行kubeadm初始化系统（注意保存最后打印的加入集群的命令）
$ kubeadm init --config ~/kubeadm-config.yaml

# 配置kubectl
$ mkdir -p ~/.kube
$ cp /etc/kubernetes/admin.conf ~/.kube/config

# 测试
$ kubectl get pods --all-namespaces
```

## 3. copy相关配置

#### 3.1 copy证书和秘钥
> 其他节点需要用到的证书文件列表：  
/etc/kubernetes/pki/ca.crt  
/etc/kubernetes/pki/ca.key  
/etc/kubernetes/pki/sa.key  
/etc/kubernetes/pki/sa.pub  
/etc/kubernetes/pki/front-proxy-ca.crt  
/etc/kubernetes/pki/front-proxy-ca.key  
/etc/kubernetes/pki/etcd/ca.crt  
/etc/kubernetes/pki/etcd/ca.key  
/etc/kubernetes/admin.conf
```bash
# 在中转节点把文件copy回来
$ scp -r <user>@<node-ip>:/etc/kubernetes/pki .
$ scp <user>@<node-ip>:/etc/kubernetes/admin.conf .

# 删除多余的文件
$ cd pki
$ rm -f apiserver*
$ rm -f front-proxy-client.*
$ rm -f etcd/healthcheck-client.* etcd/peer.* etcd/server.*

# 分别copy到另外两个master节点
$ scp -r pki <user>@<node-ip>:/etc/kubernetes/
$ scp admin.conf <user>@<node-ip>:/etc/kubernetes/
```

#### 3.2 copy kubeadm-config
```bash
# copy kubeadm-config.yaml到另外两个节点
$ scp target/<node-ip>/kubeadm-config.yaml <user>@<node-ip>:~
```

## 4. 部署第二个master节点

```bash
# 上传生成的初始化脚本
$ scp target/scripts/init-master-second.sh <user>@<node-ip>:~

# 在第二个master节点上执行初始化脚本
$ sh init-master-second.sh

# 查看节点运行情况
$ netstat -ntlp
$ docker ps
$ journalctl -f

# 配置kubectl（可选）
$ mkdir -p ~/.kube
$ mv /etc/kubernetes/admin.conf ~/.kube/config
```

## 5. 部署第三个master节点
```bash
# 上传生成的初始化脚本
$ scp target/scripts/init-master-thrid.sh <user>@<node-ip>:~

# 在第三个master上执行初始化脚本
$ sh init-master-thrid.sh

# 查看节点运行情况
$ netstat -ntlp
$ docker ps
$ journalctl -f

# 配置kubectl（可选）
$ mkdir -p ~/.kube
$ mv /etc/kubernetes/admin.conf ~/.kube/config
```

## 6. 部署网络插件 - calico
我们使用calico官方的安装方式来部署。
```bash
# 创建目录（在配置了kubectl的节点上执行）
$ mkdir -p /etc/kubernetes/addons

# 上传calico配置到配置好kubectl的节点（一个节点即可）
$ scp target/addons/calico* <user>@<node-ip>:/etc/kubernetes/addons/

# 部署calico
$ kubectl create -f /etc/kubernetes/addons/calico-rbac-kdd.yaml
$ kubectl create -f /etc/kubernetes/addons/calico.yaml

# 查看状态
$ kubectl get pods -n kube-system
```
## 7. 加入worker节点
```bash
# 使用之前保存的join命令加入集群
$ kubeadm join 172.18.41.14:6443 --token xxxxx.xxxxxxxxxx --discovery-token-ca-cert-hash sha256:22a5c37383578710dc1c52888c1e4589002844fe2dc72bd6ff706ea3f5ad989f

# 耐心等待一会，并观察日志
$ journalctl -f

# 查看集群状态
# 1.查看节点
$ kubectl get nodes
# 2.查看pods
$ kubectl get pods --all-namespaces
```
