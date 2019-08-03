#!/bin/bash
set -e
###############################################################
# Script Parameters                                           #
###############################################################

while getopts n:e:v:w:x:l:p: option
do
    case "${option}"
    in
    n) NAME=${OPTARG};;
    e) ENVIRONMENT=${OPTARG};;
    v) ADO_TOKEN=$(echo ${OPTARG} | base64);;
    w) ADO_POOL=$(echo ${OPTARG} | base64);;
    x) ADO_URL=$(echo ${OPTARG} | base64);;
    l) LOCATION=${OPTARG};;
    p) ADO_ACCOUNT=$(echo ${OPTARG} | base64);;
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
# az acr build -t azpagent:latest ../azpdocker/
az acr build -t vstsagent:latest ../vstsdocker/

# deploy tiller
mv ../helm-certs.zip .
unzip helm-certs.zip

set +e ## ignore errors if these exist already
kubectl create namespace tiller-world
set -e

kubectl apply -f ../config/helm-rbac.yaml
kubectl apply -f ../config/kured.yaml

helm init --tiller-tls --tiller-tls-cert ./tiller.cert.pem \
    --tiller-tls-key ./tiller.key.pem --tiller-tls-verify --tls-ca-cert ca.cert.pem \
    --tiller-namespace=tiller-world --service-account=tiller

cp ca.cert.pem ~/.helm/ca.pem
cp helm.cert.pem ~/.helm/cert.pem
cp helm.key.pem ~/.helm/key.pem

az acr helm repo add

echo "pushing agent to helm"

# cd ../azpagent 
# set +e
# helm package .
# ls -l *.tgz
# az acr helm push --force *.tgz
# rm -rf *.tgz
# set -e
# cd - 

cd ../vstsagent 
set +e
helm package .
ls -l *.tgz
az acr helm push --force *.tgz
rm -rf *.tgz
set -e
cd - 

helm repo update
az acr helm list

# set +e
# helm delete --purge --tls --tiller-namespace=tiller-world azpagent
# set -e
echo "deploying agent to k8s"

ADO_TOKEN=$(tr -dc '[[:print:]]' <<< ${ADO_TOKEN})
ADO_POOL=$(tr -dc '[[:print:]]' <<< ${ADO_POOL})
ADO_URL=$(tr -dc '[[:print:]]' <<< ${ADO_URL})
ADO_ACCOUNT=$(tr -dc '[[:print:]]' <<< ${ADO_ACCOUNT})

# helm upgrade --tls --install --tiller-namespace=tiller-world azpagent ${RESOURCE_GROUP_NAME}/azpagent \
#     --set azp.url=${ADO_URL},azp.token=${ADO_TOKEN},azp.pool=${ADO_POOL} \
#     --set image.repository=${RESOURCE_GROUP_NAME}.azurecr.io/azpagent 

helm upgrade --tls --install --tiller-namespace=tiller-world vstsagent ${RESOURCE_GROUP_NAME}/vstsagent \
    --set vsts.account=${ADO_ACCOUNT},vsts.token=${ADO_TOKEN},vsts.pool=${ADO_POOL} \
    --set image.repository=${RESOURCE_GROUP_NAME}.azurecr.io/vstsagent 
