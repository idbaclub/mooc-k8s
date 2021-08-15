# 一、实践环境准备
## 1. 服务器说明
我们这里使用的是五台centos 7.2实体机，具体信息如下表：

| 系统类型 | IP地址 | 节点角色 | CPU | Memory | Hostname |
| :------: | :--------: | :-------: | :-----: | :---------: | :-----: |
| centos-7.2 | 172.18.41.18 | master |   \>=2    | \>=2G | m7-a2-15-41.18-jiagou.cn |
| centos-7.2 | 172.18.41.19 | master |   \>=2    | \>=2G | m7-a2-15-41.19-jiagou.cn |
| centos-7.2 | 172.18.41.20 | master |   \>=2    | \>=2G | m7-a2-15-41.20-jiagou.cn |
| centos-7.2 | 172.18.64.41 | worker |   \>=2    | \>=2G | syq-g05-64.41-jiagou.cn |
| centos-7.2 | 172.18.64.42 | worker |   \>=2    | \>=2G | syq-g05-64.42-jiagou.cn |

## 2. 系统设置（所有节点）
#### 2.1 主机名
主机名必须每个节点都不一样，并且保证所有点之间可以通过hostname互相访问。
```bash
# 查看主机名
$ hostname
# 修改主机名
$ hostnamectl set-hostname <your_hostname>
# 配置host，使所有节点之间可以通过hostname互相访问
$ vi /etc/hosts
# <node-ip> <node-hostname>
```
#### 2.2 安装依赖包
```bash
# 更新yum
$ yum update
# 安装依赖包
$ yum install -y conntrack ipvsadm ipset jq sysstat curl iptables libseccomp
```
#### 2.3 关闭防火墙、swap，重置iptables
```bash
# 关闭防火墙
$ systemctl stop firewalld && systemctl disable firewalld
# 重置iptables
$ iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat && iptables -P FORWARD ACCEPT
# 关闭swap
$ swapoff -a
$ sed -i '/swap/s/^\(.*\)$/#\1/g' /etc/fstab
# 关闭selinux
$ setenforce 0
# 关闭dnsmasq(否则可能导致docker容器无法解析域名)
$ service dnsmasq stop && systemctl disable dnsmasq
```
#### 2.4 系统参数设置

```bash
# 制作配置文件
$ cat > /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
EOF
# 生效文件
$ sysctl -p /etc/sysctl.d/kubernetes.conf
```
## 3. 安装docker（所有节点）
根据kubernetes对docker版本的兼容测试情况，我们选择17.03.1版本
由于近期docker官网速度极慢甚至无法访问，使用yum安装很难成功。我们直接使用rpm方式安装
```bash
# 手动下载rpm包
$ mkdir -p /opt/kubernetes/docker && cd /opt/kubernetes/docker
$ wget http://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-selinux-17.03.1.ce-1.el7.centos.noarch.rpm
$ wget http://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-17.03.1.ce-1.el7.centos.x86_64.rpm
$ wget http://yum.dockerproject.org/repo/main/centos/7/Packages/docker-engine-debuginfo-17.03.1.ce-1.el7.centos.x86_64.rpm
# 清理原有版本
$ yum remove -y docker* container-selinux
# 安装rpm包
$ yum localinstall -y *.rpm
# 开机启动
$ systemctl enable docker
# 设置参数
# 1.查看磁盘挂载
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda2        98G  2.8G   95G   3% /
devtmpfs         63G     0   63G   0% /dev
/dev/sda5      1015G  8.8G 1006G   1% /tol
/dev/sda1       197M  161M   37M  82% /boot
# 2.选择比较大的分区（我这里是/tol）
$ mkdir -p /tol/docker-data
$ cat <<EOF > /etc/docker/daemon.json
{
    "graph": "/tol/docker-data"
}
EOF
# 启动docker服务
service docker restart
```

## 4. 安装必要工具（所有节点）
#### 4.1 工具说明
- **kubeadm:**  部署集群用的命令
- **kubelet:** 在集群中每台机器上都要运行的组件，负责管理pod、容器的生命周期
- **kubectl:** 集群管理工具

#### 4.2 安装方法（科学上网）
```bash
# 配置yum源
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# 安装工具
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# 启动kubelet
systemctl enable kubelet && systemctl start kubelet
```
#### 4.2 安装方法（普通上网）
不能科学上网需要把yum源改成阿里云的镜像
```bash
# 配置yum源
$ cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 安装工具
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# 启动kubelet
systemctl enable kubelet && systemctl start kubelet
```


## 5. 准备配置文件（任意节点）
#### 5.1 下载配置文件
我这准备了一个项目，专门为大家按照自己的环境生成配置的。它只是帮助大家尽量的减少了机械化的重复工作。它并不会帮你设置系统环境，不会给你安装软件。总之就是会减少你的部署工作量，但不会耽误你对整个系统的认识和把控。
```bash
$ cd ~ && git clone https://gitee.com/pa/kubernetes-ha-kubeadm.git
# 看看git内容
$ ls -l kubernetes-ha-kubeadm
addons/
configs/
scripts/
init.sh
global-configs.properties
```
#### 5.2 文件说明
- **addons**
> kubernetes的插件，比如calico和dashboard。

- **configs**
> 包含了部署集群过程中用到的各种配置文件。

- **scripts**
> 包含部署集群过程中用到的脚本，比如下载镜像脚本、keepalive检查脚本等。

- **global-configs.properties**
> 全局配置，包含各种易变的配置内容。

- **init.sh**
> 初始化脚本，配置好global-config之后，会自动生成所有配置文件。

#### 5.3 生成配置
这里会根据大家各自的环境生成kubernetes部署过程需要的配置文件。
在每个节点上都生成一遍，把所有配置都生成好，后面会根据节点类型去使用相关的配置。
```bash
# cd到之前下载的git代码目录
$ cd kubernetes-ha-kubeadm

# 编辑属性配置（根据文件注释中的说明填写好每个key-value）
$ vi global-config.properties

# 生成配置文件，确保执行过程没有异常信息
$ ./init.sh

# 查看生成的配置文件，确保脚本执行成功
$ find target/ -type f
```
> **执行init.sh常见问题：**
> 1. Syntax error: "(" unexpected
> - bash版本过低，运行：bash -version查看版本，如果小于4需要升级
> - 不要使用 sh init.sh的方式运行（sh和bash可能不一样哦）
> 2. global-config.properties文件填写错误，需要重新生成
> 再执行一次./init.sh即可，不需要手动删除target

#### 5.4 配置好免密登录
为了方便文件的copy我们选择一个中转节点，配置好跟其他所有节点的免密登录
```bash
# 看看是否已经存在rsa公钥
$ cat ~/.ssh/id_rsa.pub

# 如果不存在就创建一个新的
$ ssh-keygen -t rsa

# 把id_rsa.pub文件内容copy到其他机器的授权文件中
$ cat ~/.ssh/id_rsa.pub

# 在其他节点执行下面命令（包括worker节点）
$ echo "<file_content>" >> ~/.ssh/authorized_keys
```

## 6. 预先下载镜像（科学上网同学请跳过）
kubeadm方式构建的服务都是通过容器的方式运行的，而镜像都会从google的仓库中拉取，非科学上网的同学会有镜像下载的问题。
我预先把所有需要的镜像都放到了阿里的仓库里。并且准备了脚本下载所有需要的镜像并且tag回原镜像的名字。从而解决大家不能下载镜像的问题。
#### 6.1 下载master节点镜像
```bash
# 上传到目标节点
$ scp target/scripts/download-image-master.sh <user>@<node-ip>:~

# 下载镜像
$ sh ~/download-image-master.sh
```

#### 6.2 下载worker节点镜像
```bash
# 上传到目标节点
$ scp target/scripts/download-image-worker.sh <user>@<node-ip>:~

# 下载镜像
$ sh ~/download-image-worker.sh
```
