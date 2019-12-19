#!/bin/bash

read -p 'Subscription Id: ' SUBSCRIPTION_ID
read -p 'Cluster name: ' name
read -p 'Environment name: ' env
read -p 'Azure Region: ' location
read -p 'Azure DevOps Org: ' org
read -p 'Azure Pool: ' pool
read -p 'Azure Token: ' token

az account set --subscription $SUBSCRIPTION_ID

echo ""
echo ">>> Creating rbac service principal for terraform"
echo ""

# https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html

rbac=$(az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/${SUBSCRIPTION_ID}")
appId=$(echo ${rbac} | jq -r .appId)
password=$(echo ${rbac} | jq -r .password)

echo ""
echo ">>> Creating keyvault, and adding auth secrets"
echo ""

az group create --name $name$env --location $location
az keyvault create --name $name$env --resource-group $name$env --location $location 
az acr create -n $name$dev -g $name$dev --sku Standard
az keyvault secret set --vault-name $name$env --name ARM-CLIENT-ID --value $appId
az keyvault secret set --vault-name $name$env --name ARM-CLIENT-SECRET --value $password 
az keyvault secret set --vault-name $name$env --name ADO-POOL --value $pool
az keyvault secret set --vault-name $name$env --name ADO-TOKEN --value $token
az keyvault secret set --vault-name $name$env --name ADO-ORG --value $org
az keyvault secret set --vault-name $name$env --name ADO-LOCATION --value $location
az keyvault secret set --vault-name $name$env --name ADO-NAME --value $name
az keyvault secret set --vault-name $name$env --name ADO-ENV --value $env
