# kubernetes-ha-kubeadm

## 项目介绍
项目致力于让有意向使用原生kubernetes集群的企业或个人，可以方便的、系统的使用**kubeadm**的方式搭建kubernetes高可用集群。并且让相关的人员可
以更好的理解kubernetes集群的运作机制。
- **集群部署过程严格按照[官方文档][6]的流程。**
- **非科学上网的同学同样适用。**
- **持续跟进kubernetes最新版本**

> PS：如果想学习使用**二进制**的方式部署高可用集群参见姊妹篇：[《使用二进制的方式部署kubernetes-v1.11.2高可用集群》][5]

## 软件版本
- os centos7.2（ubuntu也适用，需要替换部分命令）
- kubernetes (yum源最新版本-目前是v1.11.0)
- etcd 3.2.18
- docker 17.03
- calico 3.1.3

## 安装教程
#### [一、实践环境准备][1]
#### [二、高可用集群部署][2]
#### [三、集群可用性测试][3]
#### [四、部署dashboard][4]

[1]:https://gitee.com/pa/kubernetes-ha-kubeadm/blob/master/docs/1-prepare.md
[2]:https://gitee.com/pa/kubernetes-ha-kubeadm/blob/master/docs/2-ha-deploy.md
[3]:https://gitee.com/pa/kubernetes-ha-kubeadm/blob/master/docs/3-test.md
[4]:https://gitee.com/pa/kubernetes-ha-kubeadm/blob/master/docs/4-dashboard.md
[5]:https://gitee.com/pa/kubernetes-ha-binary
[6]:https://kubernetes.io/docs/setup/independent/high-availability/
