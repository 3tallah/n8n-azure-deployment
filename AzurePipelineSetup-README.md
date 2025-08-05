# Azure Pipeline Setup for n8n Deployment

This guide explains how to set up and use the Azure Pipeline for automated n8n deployment to Azure App Service.

## 📋 Prerequisites

Before setting up the Azure Pipeline, ensure you have:

1.  **Azure DevOps Organization** with a project
2.  **Azure Subscription** with Contributor permissions
3.  **Azure Service Connection** configured in Azure DevOps
4.  **Repository** containing the n8n deployment files

## 🚀 Quick Setup

### Step 1: Configure Azure Service Connection

1.  Go to your Azure DevOps project
2.  Navigate to **Project Settings** → **Service Connections**
3.  Click **New Service Connection**
4.  Select **Azure Resource Manager**
5.  Choose **Service Principal (automatic)**
6.  Select your Azure subscription
7.  Set the scope to **Subscription**
8.  Name it `Azure Subscription` (this name is used in the pipeline)
9.  Click **Save**

### Step 2: Create Environment

1.  Go to **Pipelines** → **Environments**
2.  Click **New Environment**
3.  Name it `production`
4.  Click **Create**

### Step 3: Upload Pipeline

1.  Go to **Pipelines** → **Pipelines**
2.  Click **New Pipeline**
3.  Choose **Azure Repos Git** (or your source)
4.  Select your repository
5.  Choose **Existing Azure Pipelines YAML file**
6.  Select the path: `n8n-azure-deployment/azure-pipelines.yml`
7.  Click **Continue**
8.  Review and click **Run**

## 📁 Pipeline Files

The pipeline uses the following files:

-   `azure-pipelines.yml` - Main pipeline configuration
-   `deploy-n8n-azure-pipeline.sh` - Pipeline-optimized deployment script
-   `deploy-n8n-azure.sh` - Original deployment script (backup)

## 🔧 Pipeline Stages

### 1. Validate Stage
-   Checks Azure CLI installation
-   Verifies Azure login status
-   Validates subscription permissions

### 2. Build Stage
-   Copies deployment scripts
-   Makes scripts executable
-   Publishes artifacts for deployment

### 3. Deploy Stage
-   Runs only on `main` branch
-   Executes the deployment script
-   Creates all Azure resources
-   Configures n8n with OpenAI integration

### 4. Test Stage
-   Waits for application to start
-   Performs health checks
-   Validates Azure resources

### 5. Notify Stage
-   Outputs deployment summary
-   Provides access URLs
-   Shows Azure Portal links

## ⚙️ Configuration Variables

The pipeline uses these variables (defined in `azure-pipelines.yml`):

```yaml
variables:
  resourceGroupName: 'n8n-resources'
  location: 'eastus'
  appName: 'n8n-app-$(Build.BuildId)'
  storageAccountName: 'n8nstorage$(Build.BuildId)'
  openAIServiceName: 'n8n-ai-$(Build.BuildId)'
  dockerImage: 'docker.n8n.io/n8nio/n8n:latest'
````

### Customizing Variables

You can modify these in the pipeline YAML or set them as pipeline variables:

1.  Go to **Pipelines** → **Edit Pipeline**
2.  Click **Variables**
3.  Add/modify variables as needed

## 🔐 Security Considerations

### Service Principal Permissions

Ensure your Azure Service Connection has these permissions:

  - **Contributor** role on the subscription or resource group
  - **Cognitive Services Contributor** (for OpenAI service creation)

### Environment Variables

The pipeline script accepts these environment variables:

  - `RESOURCE_GROUP` - Azure resource group name
  - `LOCATION` - Azure region
  - `APP_NAME` - App Service name
  - `STORAGE_ACCOUNT` - Storage account name
  - `OPENAI_SERVICE_NAME` - OpenAI service name
  - `DOCKER_IMAGE` - n8n Docker image

## 📊 Monitoring and Troubleshooting

### Pipeline Logs

1.  Go to **Pipelines** → **Runs**
2.  Click on a specific run
3.  View logs for each stage

### Common Issues

| Issue | Solution |
|---|---|
| Azure login fails | Check service connection permissions |
| Resource creation fails | Verify subscription has required quotas |
| OpenAI service creation fails | Ensure OpenAI is available in your region |
| App doesn't start | Check container logs in Azure Portal |
| App doesn’t find storage mount | The script includes a delayed restart to fix this. Check the pipeline logs for the "Delayed Restart" step to ensure it ran successfully. |

### Debugging

Enable debug mode by adding this to the pipeline YAML:

```yaml
variables:
  system.debug: 'true'
```

## 🎯 Deployment Output

After successful deployment, you'll get:

  - **Application URL**: `https://n8n-app-{buildId}.azurewebsites.net`
  - **Resource Group**: `n8n-resources`
  - **Storage Account**: `n8nstorage{buildId}`
  - **OpenAI Service**: `n8n-ai-{buildId}`

## 🔄 Continuous Deployment

### Branch Policies

To enable automatic deployment:

1.  Go to **Repositories** → **Branches**
2.  Click on `main` branch
3.  Click **Branch Policies**
4.  Enable **Build Validation**
5.  Add the pipeline as a required build

### Pull Request Validation

The pipeline will run on:

  - `main` branch (full deployment)
  - `develop` branch (validation only)

## 📈 Cost Optimization

### Resource Sizing

The pipeline creates:

  - **App Service Plan**: B1 tier (\~$13/month)
  - **Storage Account**: Standard\_LRS (\~$0.02/GB/month)
  - **OpenAI Service**: s0 tier (\~$0.03/1K tokens)

### Cleanup

To avoid costs, delete resources after testing:

```bash
az group delete --name n8n-resources --yes --no-wait
```

## 🛠️ Customization

### Adding Custom App Settings

Modify the deployment script to add custom settings:

```bash
az webapp config appsettings set \
    --name $APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --settings \
        CUSTOM_SETTING=value \
        ANOTHER_SETTING=value
```

### Using Different Docker Images

Change the `dockerImage` variable:

```yaml
dockerImage: 'your-registry/n8n:custom-tag'
```

### Multi-Environment Deployment

Create separate pipelines for different environments:

  - `azure-pipelines-dev.yml` (development)
  - `azure-pipelines-staging.yml` (staging)
  - `azure-pipelines-prod.yml` (production)

## 📞 Support

For issues or questions:

1.  Check the pipeline logs for detailed error messages
2.  Review the Azure Portal for resource status
3.  Verify service connection permissions
4.  Ensure all prerequisites are met

## 🔗 Related Resources

  - [Azure Pipelines Documentation](https://docs.microsoft.com/en-us/azure/devops/pipelines/)
  - [n8n Documentation](https://docs.n8n.io/)
  - [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)
  - [Azure OpenAI Documentation](https://docs.microsoft.com/en-us/azure/cognitive-services/openai/)

## 🤝 Contributing

Feel free to open issues or submit pull requests. All contributions are welcome\!

## 📄 License

Distributed under the MIT License. See `LICENSE` for full details.

## 👤 Author

**Mahmoud A. ATALLAH**

  * GitHub: [@3tallah](https://github.com/3tallah)
  * LinkedIn: [Mahmoud A. Atallah](https://www.linkedin.com/in/mahmoudatallah)