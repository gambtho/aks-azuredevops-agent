#!/bin/bash
set -e
###############################################################
# Script Parameters                                           #
###############################################################

while getopts n:e: option
do
    case "${option}"
    in
    n) NAME=${OPTARG};;
    e) ENVIRONMENT=${OPTARG};;
    esac
done

if [ -z "$NAME" ]; then
    echo "-n is a required argument - Name"
    exit 1
fi
if [ -z "$ENVIRONMENT" ]; then
    echo "-e is a required argument - Environment (dev, prod)"
    exit 1
fi

###############################################################
# Script Begins                                               #
###############################################################

RESOURCE_GROUP_NAME=${CLUSTER_NAME}${ENVIRONMENT}
ARM_SUBSCRIPTION_ID=$(az account show --query id --out tsv)
az account set --subscription $ARM_SUBSCRIPTION_ID

# get kubeconfig
az aks get-credentials --admin --name $RESOURCE_GROUP_NAME-aks --resource-group $RESOURCE_GROUP_NAME

# add helm repo to acr
az configure --defaults acr=${RESOURCE_GROUP_NAME}
az acr helm repo add

az acr build -t devops-agent:latest ./agents

kubectl apply -f ../config/helm-rbac.yml
kubectl apply -f ../config/pod-security.yml
kubectl apply -f ../config/kured.yml

# deploy tiller
mv ../helm-certs.zip .
unzip helm-certs.zip

set +e ## ignore errors if these exist already
kubectl create namespace tiller-world
kubectl create namespace ingress
set -e

helm init --force-upgrade --tiller-tls --tiller-tls-cert ./tiller.cert.pem --tiller-tls-key ./tiller.key.pem --tiller-tls-verify --tls-ca-cert ca.cert.pem --tiller-namespace=tiller-world --service-account=tiller

# cp ca.cert.pem ~/.helm/ca.pem
# cp helm.cert.pem ~/.helm/cert.pem
# cp helm.key.pem ~/.helm/key.pem

# rm -rf *.pem && rm -rf *.zip
 

# # Install the CustomResourceDefinition resources separately
# kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# # Create the namespace for cert-manager
# kubectl create namespace cert-manager

# # Label the cert-manager namespace to disable resource validation
# kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

# # Add the Jetstack Helm repository
# helm repo add jetstack https://charts.jetstack.io

# # Update your local Helm chart repository cache
# helm repo update

# # Install the cert-manager Helm chart
# helm install \
#   --name cert-manager \
#   --namespace cert-manager \
#   --version v0.8.1 \
#   jetstack/cert-manager



# publicIp=$(az network public-ip create --resource-group MC_${RESOURCE_GROUP_NAME}-resources_${RESOURCE_GROUP_NAME}-aks_eastus --name ${RESOURCE_GROUP_NAME} --allocation-method static --query publicIp.ipAddress -o tsv)
# helm install --tls --tiller-namespace=tiller-world stable/nginx-ingress \
#     --namespace ingress \
#     --set controller.replicaCount=2 \
#     --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
#     --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux \
#     --set controller.service.loadBalancerIP=${publicIp}

# kubectl apply -f agents/agent.yaml

# echo $publicIp

# rm -rf *.pem && rm -rf *.zip
# cp ca.cert.pem ~/.helm/ca.pem
# cp helm.cert.pem ~/.helm/cert.pem
# cp helm.key.pem ~/.helm/key.pem


## tls and vsts secret


