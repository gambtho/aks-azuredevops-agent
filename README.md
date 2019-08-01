# Azure DevOps - Self Hosted Agents on AKS

This repo provides instructions and configuration to setup Self Hosted Agents for Azure DevOps running on an AKS cluster.   It was derived from this [article](https://medium.com/beyondthecorneroffice/host-azure-devops-build-containers-on-aks-beb7239026b2) by Jonathan Gardner @jgardner04, as well as a previous project by Mate Barbas.   This project utilizes terraform and helm to provide support for a repeatable infrastructure as code approach.  The process is orchestrated through an **Azure DevOps (ADO) pipeline**. The provided shell scripts will create a storage account to keep the terraform remote state.  The AKS cluster created will make use of Azure AD intregrated RBAC. Upon completion of the cluster creation, helm tiller will be installed on the cluster and kured will be setup to provide automated node restarts when updates are needed.

## Setup

1. Create Azure DevOps (ADO) project (ensure the preview feature multi-stage pipelines is turned on), and clone or fork this repo into it
2. Create an Azure Resource Manager **Service connection** in Azure DevOps
3. In pipeline/library a variable group named devops_agent, with the following variables
    ```bash
    location = eastus2 # where your resources will be created
    name = unique_name # prefix for resources
    env = env_identifier # suffix for resources
    azure_sub = service_connection_name # name from step 2
    terraform_version = 0.12.5 # version of terraform you wish to use
    ```
4. Create ARM variables that terraform and AKS will use for Azure Resource manager following these [instructions](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html).   Save the values for appId and password. To make things easier you can copy these from the output, and export them into your shell.
    ```bash
    export appId=<paste the appID value>
    export password=<paste the password value>
    ```
5. Get the Client ID, Server App ID, and Server App Secret for Kubernetes to use while integrating with Azure Active Directory. Use the instructions in [AKS AAD Integration](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli#create-azure-ad-server-component). Use the name from step 3 above plus -aks as the aksname variable ( aksname=${name}-aks ).  You only need to complete the Server and Client Component, do not follow the deploy cluster instructions.    Save the values for $serverApplicationId, $serverApplicationSecret, $clientApplicationId, these are exported as part of the instructions.  

6. Create a resource group and keyvault, then add the variables created in step 4 and 5 into keyvault.  Name and env should be the values you used in step 3 above.
    ```bash
    export name=<name from step 3>
    export env=<name from step 3>
    export location=<location from step 3>
    az group create --name $name --location $location
    az keyvault create --name $name$env --resource-group $name$env --location $location 
    az keyvault secret set --vault-name $name$env --name ARM-CLIENT-ID --value $appId # from step 4
    az keyvault secret set --vault-name $name$env --name ARM-CLIENT-SECRET --value $password # from step 4 
    az keyvault secret set --vault-name $name$env --name server-app-id --value $serverApplicationId # from step 5
    az keyvault secret set --vault-name $name$env --name server-app-secret --value $serverApplicationSecret # from step 5
    az keyvault secret set --vault-name $name$env --name client-app-id --value $clientApplicationId # from step 5

    ```
7. Add [Terraform tasks](https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform)  to your ADO organization 

8. Create another variable group devops_kv, and associate this with the keyvault you created earlier.  Add all available variables, and authorize it for use in pipelines.

9. Follow these [instructions](https://helm.sh/docs/tiller_ssl/) to setup certificates that will be used by helm, and upload them as a library/secure file named helm-certs.zip (make sure to authorize this for use in pipelines)

10. Create a new pipeline using the azure-pipelines.yml file, and run it

## Possible additions

- Use [Terraform tasks](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) from Microsoft DevLabs
- Convert to helm 3, and remove tiller
- Simplify service principal setup
- Simplify/reorganize pipeline jobs and stages

## Contributions

This repo is a work in progress, pull requests and suggestions are greatly appreciated

## Maintainers

Thomas Gamble thgamble@microsoft.com

