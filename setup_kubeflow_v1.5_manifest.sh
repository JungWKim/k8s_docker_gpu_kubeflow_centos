#!/bin/bash

# Turn off ufw or open a specific port for kubeflow installation

#---------------- install nfs-utils for binding pv to PVCs by storage class
apt install -y nfs-common

#---------------- set nfs-client storage class as default
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

#---------------- download kubeflow manifest repository
git clone https://github.com/kubeflow/manifests.git

#---------------- download kustomize.exe file 3.2.0 for linux which is stable with over kubeflow version 1.5.0
wget https://github.com/kubernetes-sigs/kustomize/releases/download/v3.2.0/kustomize_3.2.0_linux_amd64

#---------------- copy kustomize exe into /bin/bash
chmod +x kustomize_3.2.0_linux_amd64
mv kustomize_3.2.0_linux_amd64 /usr/bin/kustomize

#---------------- install kubeflow as a single command
cd manifests
while ! kustomize build example | kubectl apply -f -; do echo "Retrying to apply resources"; sleep 10; done
