#!/bin/bash

# check the must-be-done priorities
echo "1. disable swap"
echo "2. static IP"
echo "3. login as root"
echo "4. change the hostname. There should be no matching hostnames between each nodes"
read -p "Did you perform above all things? (yes/no) " answer
if [ ${answer} = yes ] || [ ${answer} = y ] ; then
        echo ""
        else echo "Make them done first!" && exit
fi

read -p "Enter the system's IP : " ip
read -p "Enter the user name you want to give administrator privilege : " user_name

#------------- disable firewalld
systemctl stop firewalld
systemctl disable firewalld

#------------- install docker
yum remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine
yum install -y yum-utils
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io -y
systemctl start docker

#-------------- make docker use systemd not cgroupfs
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker

#------------- letting iptables see bridged traffic
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/k8s.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/k8s.conf
sysctl --system
modprobe br_netfilter

#------------- install kubeadm/kubelete/kubectl
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

#------------- Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet=1.20.11-00 kubeadm=1.20.11-00 kubectl=1.20.11-00 --disableexcludes=kubernetes

sudo systemctl enable --now kubelet
sudo systemctl start kubelet

#------------- enable kubectl in any accounts
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

#------------- enable kubectl & kubeadm auto-completion
echo "source <(kubectl completion bash)" >> $HOME/.bashrc
echo "source <(kubeadm completion bash)" >> $HOME/.bashrc
source $HOME/.bashrc

#------------- install nfs-common for nfs storage class in future use
yum install -y nfs-utils
