# Azure DevOps - Self Hosted Agents on AKS

[![Build Status](https://dev.azure.com/thomasgamble2/ado-agent/_apis/build/status/ado-agent?branchName=master)](https://dev.azure.com/thomasgamble2/ado-agent/_build/latest?definitionId=7&branchName=master)

This repo provides instructions and configuration to setup Self Hosted Agents for Azure DevOps running on an AKS cluster.  It was derived from this [article](https://medium.com/beyondthecorneroffice/host-azure-devops-build-containers-on-aks-beb7239026b2) by Jonathan Gardner @jgardner04, as well as a similar project by Mate Barbas using ARM templates.   This project utilizes terraform and helm to provide support for a repeatable infrastructure as code approach.  The process is orchestrated through an **Azure DevOps (ADO) pipeline**. 

## Setup

1. Create an Azure DevOps (ADO) project, and clone or fork this repo into it
    - Make sure you enable the **Multi-stage pipelines** preview feature for your user or your org  by following the directions [here](https://docs.microsoft.com/en-us/azure/devops/project/navigation/preview-features?view=azure-devops) 
---
2. Create an Azure Resource Manager **Service connection** in Azure DevOps
---
3. Run the manual setup script **./manual.sh** from [Azure CLI](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart) or [Windows Subsystem for Linux (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10) on your wokstation, this script does the following:
    - Create service principals for use by terraform and AKS
    - Save service principal and other provided variables in keyvault
    
   This command will ask for your Azure subscription id, as well as the name (arbitrary string of your choice), env (arbitrary string of your choice), and location (valid Azure region) for your AKS cluster.
---
4. Create a variable group named "ado-kv" and associate it with the key vault you just created:
   - Toggle **Link secrets from an Azure key vault as variables**
   - Select your subscription and the key vault you created in the previous step
   - **Authorize** it for use in the pipelines
   - Add all the variables aviable in your key vault
---
5. Create another variable group named "ado-config":
    - Add a variable named azure_sub
    - Set that value for the created variable as the name used for the Service Connection in step 2
    - **Authorize** it for use in the pipelines
---
6. Create a pipeline using the provided YAML file **./pipelines/aks-pipelines.yml**, and run it:
    - From Azure DevOps click on **Pipelines** in the left navigation bar and click on **Create pipeline**
    - On the page **Where is your code?** select **Azure Repos Git YAML**
    - Select your repository in Azure DevOps
    - On the page **Configure your pipeline** select **Existing Azure Pipelines YAML file** and set the path to **/aks/pipelines/aks-pipelines.yml** 
    - Click on **Continue** and then on **Run**
---

## Possible additions

- Consider AAD integrated AKS cluster (not currently used, as it makes the AD permissions required a bit complex )
- Add 2nd nodepool, with windows agents
- Add cluster/pod autoscale

## Other options

- Use a docker hub image, and remove the need for ACR (gambtho/azure-pipeline-agent)
- Add to azpdocker/Dockerfile any additional tools you may need

## Contributions

This repo is a work in progress, pull requests and suggestions are greatly appreciated

## Maintainers

Thomas Gamble thgamble@microsoft.com


