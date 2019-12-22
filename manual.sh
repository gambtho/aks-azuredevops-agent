#!/bin/bash
###############################################################
# Script Parameters                                           #
###############################################################

while getopts s:p: option
do
    case "${option}"
    in
    s) appId=${OPTARG};;
    p) password=${OPTARG};;
    esac
done

read -p 'Subscription Id: ' SUBSCRIPTION_ID
read -p 'Cluster name: ' name
read -p 'Environment name: ' env
read -p 'Azure Region: ' location
read -p 'Azure DevOps Org: ' org
read -p 'Azure Pool: ' pool
read -p 'Azure Token: ' token

az account set --subscription $SUBSCRIPTION_ID

# https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html
if [ -z $appId ]; then
    echo ""
    echo ">>> Creating rbac service principal for terraform"
    echo ""
    rbac=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
    appId=$(echo ${rbac} | jq -r .appId)
    password=$(echo ${rbac} | jq -r .password)
else
    echo ""
    echo "Using existing secret and password. $appId"
fi
echo ""
echo ">>> Creating keyvault, and adding auth secrets"
echo ""
az group create --name $name$env --location $location
az keyvault create --name $name$env --resource-group $name$env --location $location 
az keyvault secret set --vault-name $name$env --name ARM-CLIENT-ID --value $appId
az keyvault secret set --vault-name $name$env --name ARM-CLIENT-SECRET --value $password 
az keyvault secret set --vault-name $name$env --name ADO-POOL --value $pool
az keyvault secret set --vault-name $name$env --name ADO-TOKEN --value $token
az keyvault secret set --vault-name $name$env --name ADO-ORG --value $org
az keyvault secret set --vault-name $name$env --name ADO-LOCATION --value $location
az keyvault secret set --vault-name $name$env --name ADO-NAME --value $name
az keyvault secret set --vault-name $name$env --name ADO-ENV --value $env
echo "Adding permissions to keyvault."
az keyvault set-policy --name $name$env --spn $appId --secret-permissions get list
echo ""
echo ">>> Creating acr $name$env"
echo ""
az acr create -n $name$env -g $name$env --sku Standard
