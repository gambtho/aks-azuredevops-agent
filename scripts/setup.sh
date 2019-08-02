#!/bin/bash
set -e
###############################################################
# Script Parameters                                           #
###############################################################

while getopts n:e:l:c:s:p:z:y: option
do
    case "${option}"
    in
    n) NAME=${OPTARG};;
    e) ENVIRONMENT=${OPTARG};;
    l) LOCATION=${OPTARG};;
    c) CLIENTID=${OPTARG};;
    s) SERVERID=${OPTARG};;
    p) SERVERSECRET=${OPTARG};;
    z) ARMID=${OPTARG};;
    y) ARMSECRET=${OPTARG};;
    esac
done

if [ -z "$NAME" ]; then
    echo "-n is a required argument - Storage account name"
    exit 1
fi
if [ -z "$ENVIRONMENT" ]; then
    echo "-e is a required argument - Environment (dev, prod)"
    exit 1
fi
if [ -z "$LOCATION" ]; then
    echo "-l is a required argument - Location"
    exit 1
fi
if [ -z "$CLIENTID" ]; then
    echo "-c is a required argument - Client ID"
    exit 1
fi
if [ -z "$SERVERID" ]; then
    echo "-s is a required argument - Server ID"
    exit 1
fi
if [ -z "$SERVERSECRET" ]; then
    echo "-p is a required argument - Server Secret"
    exit 1
fi
if [ -z "$ARMID" ]; then
    echo "-z is a required argument - ARM ID"
    exit 1
fi
if [ -z "$ARMSECRET" ]; then
    echo "-y is a required argument - ARM Secret"
    exit 1
fi

###############################################################
# Script Begins                                               #
###############################################################

RESOURCE_GROUP_NAME=${NAME}${ENVIRONMENT}
STORAGE_ACCOUNT_NAME=${NAME}${ENVIRONMENT}

ARM_SUBSCRIPTION_ID=$(az account show --query id --out tsv)
ARM_TENANT_ID=$(az account show --query tenantId --out tsv)

echo $ARM_TENANT_ID
echo $ARM_SUBSCRIPTION_ID
az account show --query tenantId --out tsv

set +e # errors don't matter for a bit

# Create resource group
if [ $(az group exists -n $RESOURCE_GROUP_NAME -o tsv) = false ]
then
    az group create --name $RESOURCE_GROUP_NAME --location $LOCATION
else
    echo "Using resource group $RESOURCE_GROUP_NAME"
fi

set -e # errors matter again

# Create storage account
az storage account show -n $STORAGE_ACCOUNT_NAME -g $RESOURCE_GROUP_NAME > /dev/null
if [ $? -eq 0 ]
then
    echo "Using storage account $STORAGE_ACCOUNT_NAME in resource group $RESOURCE_GROUP_NAME"
else
    az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob
fi

az keyvault show --name $RESOURCE_GROUP_NAME > /dev/null
if [ $? -eq 0 ]
then
    echo "Using keyVault $RESOURCE_GROUP_NAME"
else
    az keyvault create --name $RESOURCE_GROUP_NAME --resource-group  $RESOURCE_GROUP_NAME --location $LOCATION > /dev/null
    echo "KeyVault $RESOURCE_GROUP_NAME created -- this must be populated wth the k8s AAD values"
fi


# Get storage account key
ACCESS_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)

# Create blob container
az storage container create --name $ENVIRONMENT --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCESS_KEY

cd ../terraform

cat <<EOT >> terraform.tfvars
    tenant = "${ARM_TENANT_ID}"
    subscription = "${ARM_SUBSCRIPTION_ID}"
    client_app_id = "${CLIENTID}"
    server_app_id = "${SERVERID}"
    server_app_secret = "${SERVERSECRET}"
    ARM_CLIENT_ID = "${ARMID}"
    ARM_CLIENT_SECRET = "${ARMSECRET}"
    name = "${RESOURCE_GROUP_NAME}"
    ado_token = ${ADO_TOKEN}
    ado_pool = ${ADO_POOL}
    ado_account = ${ADO_ACCOUNT}
EOT




