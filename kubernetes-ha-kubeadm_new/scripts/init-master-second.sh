#!/bin/bash
#kubelet 引导配置
kubeadm alpha phase certs all --config kubeadm-config.yaml
kubeadm alpha phase kubelet config write-to-disk --config kubeadm-config.yaml
kubeadm alpha phase kubelet write-env-file --config kubeadm-config.yaml
kubeadm alpha phase kubeconfig kubelet --config kubeadm-config.yaml
systemctl start kubelet

sleep 2

#加入etcd集群
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl exec -n kube-system etcd-{{MASTER_0_HOSTNAME}} -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://{{MASTER_0_IP}}:2379 member add {{MASTER_1_HOSTNAME}} https://{{MASTER_1_IP}}:2380
sleep 2
kubeadm alpha phase etcd local --config kubeadm-config.yaml

sleep 3
#部署主节点组件
kubeadm alpha phase kubeconfig all --config kubeadm-config.yaml
kubeadm alpha phase controlplane all --config kubeadm-config.yaml
kubeadm alpha phase mark-master --config kubeadm-config.yaml

