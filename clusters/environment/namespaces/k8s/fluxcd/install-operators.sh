#!/bin/bash
set -e
if ! command -v fluxctl &> /dev/null
then
    echo "fluxctl could not be found; please install fluxctl (<v2) https://docs.fluxcd.io/en/latest/references/fluxctl/"
    exit
fi
if ! command -v helm &> /dev/null
then
    echo "helm could not be found; please install helm 3 https://helm.sh/docs/intro/install/"
    exit
fi
# Directory where the flux deployment lives. ../namespaces/fluxcd/flux
FLUX_YAML_DIR="flux"
# Namespace that operators will live in
OP_NAMESPACE=fluxcd
cat << EOF > namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: $OP_NAMESPACE
EOF
kubectl apply -f namespaces.yaml
# Install flux operator
fluxctl install --git-email=flux@noreply.com --git-url=git@github.com:devopsidiot/gitops-k8s-reference.git --git-path=clusters/environment --manifest-generation=true --git-branch=master --namespace=$OP_NAMESPACE > $FLUX_YAML_DIR/flux.yaml
echo "$(awk '/name: ssh-config/{c=3} c&&c--{sub(/# /,"")} 1' $FLUX_YAML_DIR/flux.yaml)" > $FLUX_YAML_DIR/flux.yaml
echo """---
apiVersion: v1
data:
  known_hosts: |
    # gitlab
    ssh keys for connection to internal git server
kind: ConfigMap
metadata:
  name: flux-ssh-config
  namespace: fluxcd
""" >> $FLUX_YAML_DIR/flux.yaml
kubectl apply -f $FLUX_YAML_DIR/flux.yaml
# Install helm operator (never figured out how to do this declaratively, would be good to solve)
helm repo add fluxcd https://charts.fluxcd.io
helm upgrade -i helm-operator fluxcd/helm-operator --wait --namespace $OP_NAMESPACE --set git.ssh.secretName=flux-git-deploy --set helm.versions=v3
echo Push $FLUX_YAML_DIR/flux.yaml and namespaces.yaml to the repo before the next step.
echo Run the following command and add pubkey to gitlab user with write access: "fluxctl identity --k8s-fwd-ns $OP_NAMESPACE"
