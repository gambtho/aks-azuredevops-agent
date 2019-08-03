#!/bin/bash
set -e
###############################################################
# Script Parameters                                           #
###############################################################

while getopts n:e:v:w:x:l: option
do
    case "${option}"
    in
    n) NAME=${OPTARG};;
    e) ENVIRONMENT=${OPTARG};;
    v) ADO_TOKEN=$(echo ${OPTARG} | base64);;
    w) ADO_POOL=$(echo ${OPTARG} | base64);;
    x) ADO_URL=$(echo ${OPTARG} | base64);;
    l) LOCATION=${OPTARG};;
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

RESOURCE_GROUP_NAME=${NAME}${ENVIRONMENT}
ARM_SUBSCRIPTION_ID=$(az account show --query id --out tsv)
az account set --subscription $ARM_SUBSCRIPTION_ID

# get kubeconfig
az aks get-credentials --admin --name $RESOURCE_GROUP_NAME-aks --resource-group $RESOURCE_GROUP_NAME



az configure --defaults acr=${RESOURCE_GROUP_NAME}
az acr build -t devops-agent:latest ../dockeragent/

# deploy tiller
mv ../helm-certs.zip .
unzip helm-certs.zip

set +e ## ignore errors if these exist already
kubectl create namespace tiller-world
kubectl create namespace ingress
kubectl create namespace cert-manager
# # Label the cert-manager namespace to disable resource validation
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true
set -e

kubectl apply -f ../config/helm-rbac.yaml
# kubectl apply -f ../config/pod-security.yaml
kubectl apply -f ../config/kured.yaml

helm init --tiller-tls --tiller-tls-cert ./tiller.cert.pem \
    --tiller-tls-key ./tiller.key.pem --tiller-tls-verify --tls-ca-cert ca.cert.pem \
    --tiller-namespace=tiller-world --service-account=tiller

cp ca.cert.pem ~/.helm/ca.pem
cp helm.cert.pem ~/.helm/cert.pem
cp helm.key.pem ~/.helm/key.pem

az acr helm repo add
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Use Helm to deploy an NGINX ingress controller
helm upgrade --tls --install --tiller-namespace=tiller-world nginx stable/nginx-ingress \
    --namespace ingress \
    --set controller.replicaCount=1 \
    --set controller.nodeSelector."beta\.kubernetes\.io/os"=linux \
    --set defaultBackend.nodeSelector."beta\.kubernetes\.io/os"=linux

helm repo add azure-samples https://azure-samples.github.io/helm-charts/
helm install azure-samples/aks-helloworld --namespace ingress-basic
helm install azure-samples/aks-helloworld \
    --namespace ingress \
    --set title="AKS Ingress Demo" \
    --set serviceName="ingress-demo"

kubectl apply -f config/hello-world-ingress.yaml

# # Install the CustomResourceDefinition resources separately
kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml

# # Install the cert-manager Helm chart
helm upgrade --tls --install --tiller-namespace=tiller-world cert-manager \
    jetstack/cert-manager --namespace cert-manager
  
# wait for cert-manager to be available
sleep 5
kubectl apply -f ../config/cluster-issuer.yaml

echo "pushing agent to helm"

cd ../agent 
set +e
helm package .
ls -l *.tgz
az acr helm push --force *.tgz
rm -rf *.tgz
set -e
cd - 

helm repo update


helm fetch ${RESOURCE_GROUP_NAME}/agent

echo "####################################################"
az acr helm list

set +e
helm delete --purge --tls --tiller-namespace=tiller-world agent
set -e
echo "deploying agent to k8s"

helm upgrade --tls --install --tiller-namespace=tiller-world agent ${RESOURCE_GROUP_NAME}/agent \
    --set azp.url=${ADO_URL},azp.token=${ADO_TOKEN},azp.pool=${ADO_POOL} \
    --set image.repository=${RESOURCE_GROUP_NAME}.azurecr.io/devops-agent \
    --set domain=${RESOURCE_GROUP_NAME}.${LOCATION}.cloudapp.azure.com \
    --set ingress.tls[0].hosts[0]=${RESOURCE_GROUP_NAME}.${LOCATION}.cloudapp.azure.com \
    --set ingress.tls[0].secretName=tls-secret


IP=$(kubectl get svc nginx-nginx-ingress-controller -n ingress -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
DNSNAME="${RESOURCE_GROUP_NAME}"

# Get the resource-id of the public ip
PUBLICIPID=$(az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '$IP')].[id]" --output tsv)

# Update public ip address with DNS name
az network public-ip update --ids $PUBLICIPID --dns-name $DNSNAME