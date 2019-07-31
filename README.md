# Setup

- Create Azure DevOps project, and clone or fork this into it
- 



# **AKS - Deployment pipeline**

This article explains how to leverage the shell scripts and terraform templates stored in this repo to setup an AKS cluster on an existing Azure Subscription. The process is orchestrated through **Azure DevOps (ADO) pipelines**. The provided shell scripts will create a storage account to keep the terraform remote state. The terraform configuration will create a vnet with an associated subnet, as well as any specified vnet pairings. The AKS cluster created will make use of Azure AD intregrated RBAC. Upon completion of the cluster creation, helm tiller will be installed on the cluster and kured will be setup to provide automated node restarts when updates are needed.

## Setup the Azure DevOps environment

Follow the step below to setup your environment prior to running the Azure DevOps pipelines.

1. Validate that the following variable in the file **variables.tf** are correct:

    - network: subnet ranges, dns, paired vnets
    - machine size
    - replicas

2. Create an Azure **Service connection** in ADO.

3. Create a **Variable group** in the ADO pipeline library with the following variables:
    - azure_sub (should be set to the name of the connection created above)
    - cluster_name (only use small caps and no special characters)
    - env

4. Get the certificates to use with helm, which will be saved in **helm-certs.zip** as a Secure file for ADO. Use the instruction in [Using SSL Between Helm and Tiller](https://github.com/helm/helm/blob/master/docs/tiller_ssl.md)

5. Add **helm-certs.zip** as a Secure file in the pipeline library and make sure to select the checkbox "Authorize for use in all pipelines"

6. Get the Client ID, Server App ID, and Server App Secret for Kubernetes to use while integrating with Azure Active Directory. Use the instructions in [Integrate Azure Active Directory with Azure Kubernetes Service using the Azure CLI](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli)

7. Create ARM variables that terraform to use with Azure Resource manager following these [instructions](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html)

8. Add **(env).auto.tfvars** as a Secure file in the pipeline library and make sure to select the checkbox "Authorize for use in all pipelines". The following variables must be set in this file.

    ```bash
    ARM_CLIENT_ID="From Step 7"
    ARM_CLIENT_SECRET="From Step 7"
    client_app_id="From Step 6"
    server_app_id="From Step 6"
    server_app_secret="From Step 6"
    location=""
    ```

You are now ready to create an Azure DevOps Pipeline using the azure-pipelines.yml file.  After the Release has sucessfully completed, you need to perform a few manual steps outlined below.

## Post Deployment Steps

Azure DevOps pipelines will make use of the **azure-pipelines.yml** configuration file to automatically build the artifact needed to deploy the AKS cluster duing the Release phase.

After the successfull Build and Release of the AKS cluster, peform the following additional steps:

1. Setup the other ends of the vnet pairs, if you included any paired vnets in variables.tf

2. Setup RBAC roles as needed by leveraging the scripts located in the RBAC folder of this repository (related instructions can be found here: [Control access to cluster resources using RBAC](https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac))

3. Run the following commands to turn on some AKS Preview features used in this implementation:

    ```bash
    az extension add --name aks-preview
    az feature register --name PodSecurityPolicyPreview --namespace Microsoft.ContainerService
    az feature register --name APIServerSecurityPreview --namespace Microsoft.ContainerService
    sleep 30
    az provider register --namespace Microsoft.ContainerService
    ```

## Usage

Use the following commands if you want to run the project locally instead of running it through the Azure DevOps pipelines.

  ```bash
  export TF-ENV=someenv
  export TF-PROJECT=someproject
  ./init.sh -e ${TF-ENV} -c ${TF-PROJECT}
  ./apply.sh -e ${TF-ENV} -c ${TF-PROJECT}
  ./plan.sh -e ${TF-ENV}
  ./plan.sh
  ```

## Contributions

This repo is a work in progress, pull requests and suggestions are greatly appreciated

## Possible Additions

- Automatic creation of service principals
- Simplify peering variables (map)
- Keyvault replace tfvars (script creation)
- Terratest
- Standard Load Balancer

## Maintainers

Thomas Gamble thgamble@microsoft.com
Bahram Rushenas bahram.rushenas@microsoft.com
