#!/bin/bash

#------------- Before executing this script, all GPU worker nodes must be installed with NVIDIA driver and nvidia-docker 2.0 !!!
#------------- install NVIDIA dependencies

# install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
  && chmod 700 get_helm.sh \
  && ./get_helm.sh

# add NVIDIA Helm repository
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
  && helm repo update

# install NVIDIA device plugin

# add nvidia device plugin helm repository
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin \
  && helm repo update

# deploy nvidia device plugin
helm install --generate-name nvdp/nvidia-device-plugin
