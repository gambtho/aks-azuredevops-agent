# Azure DevOps - Self Hosted Agents on AKS

[![Build Status](https://dev.azure.com/thomasgamble2/ado-agent/_apis/build/status/ado-agent?branchName=master)](https://dev.azure.com/thomasgamble2/ado-agent/_build/latest?definitionId=7&branchName=master)

This repo provides instructions and configuration to setup Self Hosted Agents for Azure DevOps running on an AKS cluster.  It was derived from this [article](https://medium.com/beyondthecorneroffice/host-azure-devops-build-containers-on-aks-beb7239026b2) by Jonathan Gardner @jgardner04, as well as a similar project by Mate Barbas using ARM templates.   This project utilizes terraform and helm to provide support for a repeatable infrastructure as code approach.  The process is orchestrated through an **Azure DevOps (ADO) pipeline**. The provided shell scripts will create a storage account to keep the terraform remote state.  The AKS cluster created will make use of Azure AD intregrated RBAC. Upon completion of the cluster creation, helm tiller will be installed on the cluster and kured will be setup to provide automated node restarts when updates are needed.

## Setup

1. Create an Azure DevOps (ADO) project (ensure the preview feature multi-stage pipelines is turned on), and clone or fork this repo into it
2. Create an Azure Resource Manager **Service connection** in Azure DevOps
3. In pipeline/library add a variable group named devops_agent, with the following variables

    ```bash
    location = eastus2 # where your resources will be created
    name = unique_name # prefix for resources
    env = env_identifier # suffix for resources
    azure_sub = service_connection_name # sevice connection name from step 2
    terraform_version = 0.12.6 # version of terraform you wish to use
    ```

4. Create ARM variables that terraform and AKS will use for Azure Resource manager following these [instructions](https://www.terraform.io/docs/providers/azurerm/auth/service_principal_client_secret.html).   Save the values for appId and password. To make things easier you can copy these from the output, and export them into your shell.

    ```bash
    export appId=<paste the appID value>
    export password=<paste the password value>
    ```

5. Get the Client ID, Server App ID, and Server App Secret for Kubernetes to use while integrating with Azure Active Directory. Use the instructions in [AKS AAD Integration](https://docs.microsoft.com/en-us/azure/aks/azure-ad-integration-cli#create-azure-ad-server-component). (make sure to run the command from azure cli and not from cloud shell. Currently there is an issue with cloud shell. You can read more in the comments of the document) Use the name from step 3 above plus -aks as the aksname variable ( aksname=${name}-aks ).  You only need to complete the Server and Client Component, do not follow the deploy cluster instructions.    Save the values for $serverApplicationId, $serverApplicationSecret, $clientApplicationId, these are exported as part of the instructions.  

6. Get the url for your Azure DevOps account, will be something like https://dev.azure.com/<your_org> - $ADO_URL, the organization name - $ADO_ACCOUNT, create a [personal access token](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=vsts) - $TOKEN, and create an [agent pool](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/pools-queues?view=vsts) - $POOL

7. Create a resource group and keyvault, then add the variables created in step 4 and 5 into keyvault.  Name and env should be the values you used in step 3 above.  The following commands can be used in your cli, or in [cloud shell](https://shell.azure.com).

    ```bash
    export name=<name from step 3>
    export env=<env from step 3>
    export location=<location from step 3>
    az group create --name $name$env --location $location
    az keyvault create --name $name$env --resource-group $name$env --location $location 
    az keyvault secret set --vault-name $name$env --name ARM-CLIENT-ID --value $appId # from step 4
    az keyvault secret set --vault-name $name$env --name ARM-CLIENT-SECRET --value $password # from step 4 
    az keyvault secret set --vault-name $name$env --name server-app-id --value $serverApplicationId # from step 5
    az keyvault secret set --vault-name $name$env --name server-app-secret --value $serverApplicationSecret # from step 5
    az keyvault secret set --vault-name $name$env --name client-app-id --value $clientApplicationId # from step 5
    az keyvault secret set --vault-name $name$env --name ado-token --value $TOKEN # from step 6
    az keyvault secret set --vault-name $name$env --name ado-pool --value $POOL # from step 6
    az keyvault secret set --vault-name $name$env --name ado-url --value $ADO_URL # from step 6
    az keyvault secret set --vault-name $name$env --name ado-account --value $ADO_ACCOUNT # from step 6
    ```

8. Create another variable group named devops_kv, and associate this with the keyvault you just created.  Add all available variables, and authorize it for use in pipelines

9. Add [Terraform tasks](https://marketplace.visualstudio.com/items?itemName=charleszipp.azure-pipelines-tasks-terraform)  to your ADO organization

10. Follow these [instructions](https://helm.sh/docs/tiller_ssl/) to setup certificates that will be used by helm, and upload them as a library/secure file named helm-certs.zip (make sure to authorize this for use in pipelines)

11. Create a pipeline using the azure-pipelines.yml file, and run it

## Possible additions

- Use [Terraform tasks](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) from Microsoft DevLabs
- Convert to helm 3, and remove tiller
- Simplify service principal setup
- Simplify/reorganize pipeline jobs and stages
- Add 2nd nodepool, with windows agents
- Add cluster/pod autoscale
- Use this [startup script](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)

## Other options

- Use a docker hub image, and remove the need for ACR (gambtho/azure-pipeline-agent)
- Add to azpdocker/Dockerfile any additional tools you may need

## Contributions

This repo is a work in progress, pull requests and suggestions are greatly appreciated

## Maintainers

Thomas Gamble thgamble@microsoft.com
