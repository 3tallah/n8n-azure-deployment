#!/bin/bash

# n8n Azure Deployment Script for Azure Pipelines
# This script deploys n8n to Azure App Service with OpenAI integration
# Optimized for Azure Pipelines with environment variable support

set -e  # Exit on any error

# Configuration - Use environment variables if provided, otherwise use defaults
RESOURCE_GROUP="${RESOURCE_GROUP:-n8n-resources}"
LOCATION="${LOCATION:-eastus}"
APP_NAME="${APP_NAME:-n8n-app-$RANDOM}"
DOCKER_IMAGE="${DOCKER_IMAGE:-docker.n8n.io/n8nio/n8n:latest}"
STORAGE_ACCOUNT="${STORAGE_ACCOUNT:-n8nstorage$RANDOM}"
OPENAI_SERVICE_NAME="${OPENAI_SERVICE_NAME:-n8n-ai-$RANDOM}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
   echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
   echo -e "${GREEN}[SUCCESS]${NC} $1"
}

error() {
   echo -e "${RED}[ERROR]${NC} $1"
}

warning() {
   echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
   error "Azure CLI is not installed. Please install it first."
   exit 1
fi

log "Starting n8n deployment to Azure..."
log "Configuration:"
log "  - Resource Group: $RESOURCE_GROUP"
log "  - Location: $LOCATION"
log "  - App Name: $APP_NAME"
log "  - Storage Account: $STORAGE_ACCOUNT"
log "  - OpenAI Service: $OPENAI_SERVICE_NAME"
log "  - Docker Image: $DOCKER_IMAGE"

# Step 1: Create Resource Group (moved up)
log "Step 1/8: Creating resource group..."
if az group show --name $RESOURCE_GROUP &> /dev/null; then
   warning "Resource group $RESOURCE_GROUP already exists"
else
   az group create --name $RESOURCE_GROUP --location $LOCATION --output none
   success "Resource group $RESOURCE_GROUP created in $LOCATION"
fi

# Step 0: List resources in the resource group and pick existing ones if available
log "Step 0: Checking for existing resources in resource group $RESOURCE_GROUP..."

# Storage Account
EXISTING_STORAGE_ACCOUNT=$(az storage account list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
if [ -n "$EXISTING_STORAGE_ACCOUNT" ]; then
   STORAGE_ACCOUNT="$EXISTING_STORAGE_ACCOUNT"
   warning "Reusing existing storage account: $STORAGE_ACCOUNT"
else
   STORAGE_ACCOUNT="$STORAGE_ACCOUNT"
   log "No storage account found. Will create: $STORAGE_ACCOUNT"
fi

# App Service Plan (Linux)
EXISTING_APP_SERVICE_PLAN=$(az appservice plan list --resource-group $RESOURCE_GROUP --query "[?reserved==\`true\`][0].name" -o tsv)
if [ -n "$EXISTING_APP_SERVICE_PLAN" ]; then
   APP_SERVICE_PLAN="$EXISTING_APP_SERVICE_PLAN"
   warning "Reusing existing Linux App Service Plan: $APP_SERVICE_PLAN"
else
   APP_SERVICE_PLAN="${APP_NAME}-plan"
   log "No Linux App Service Plan found. Will create: $APP_SERVICE_PLAN"
fi

# Web App
EXISTING_WEB_APP=$(az webapp list --resource-group $RESOURCE_GROUP --query "[0].name" -o tsv)
if [ -n "$EXISTING_WEB_APP" ]; then
   APP_NAME="$EXISTING_WEB_APP"
   warning "Reusing existing web app: $APP_NAME"
else
   APP_NAME="$APP_NAME"
   log "No web app found. Will create: $APP_NAME"
fi

# OpenAI Cognitive Service
EXISTING_OPENAI=$(az cognitiveservices account list --resource-group $RESOURCE_GROUP --query "[?kind=='OpenAI'][0].name" -o tsv)
if [ -n "$EXISTING_OPENAI" ]; then
   OPENAI_SERVICE_NAME="$EXISTING_OPENAI"
   warning "Reusing existing OpenAI service: $OPENAI_SERVICE_NAME"
else
   OPENAI_SERVICE_NAME="$OPENAI_SERVICE_NAME"
   log "No OpenAI service found. Will create: $OPENAI_SERVICE_NAME"
fi

# Step 1: Login to Azure (handled by Azure Pipelines)
log "Step 1/8: Checking Azure login status..."
if az account show &> /dev/null; then
   success "Azure login verified"
   CURRENT_SUBSCRIPTION=$(az account show --query name -o tsv)
   log "Current subscription: $CURRENT_SUBSCRIPTION"
else
   error "Azure login required. Please ensure Azure CLI is authenticated."
   exit 1
fi

# Step 2: Create Storage Account
log "Step 2/8: Ensuring storage account exists..."
log "Storage account name: $STORAGE_ACCOUNT"
if az storage account show --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP &> /dev/null; then
   warning "Storage account $STORAGE_ACCOUNT already exists. Reusing."
else
   az storage account create \
      --name $STORAGE_ACCOUNT \
      --resource-group $RESOURCE_GROUP \
      --sku Standard_LRS \
      --output none
   success "Storage account $STORAGE_ACCOUNT created successfully"
fi

# --- New Step: Create Azure File Share for n8n persistent data ---
FILE_SHARE_NAME="n8ndata"
log "Creating Azure File Share '$FILE_SHARE_NAME' for persistent n8n data..."

# Get storage account key
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query [0].value -o tsv)

# Check if file share exists
if az storage share exists --name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --query exists -o tsv | grep -q true; then
   warning "File share $FILE_SHARE_NAME already exists. Skipping creation."
else
   az storage share create --name $FILE_SHARE_NAME --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY --output none
   success "File share $FILE_SHARE_NAME created."
fi
# --- End New Step ---

# Get storage connection string
log "Retrieving storage connection string..."
STORAGE_CONN=$(az storage account show-connection-string \
   --name $STORAGE_ACCOUNT \
   --resource-group $RESOURCE_GROUP \
   --query connectionString -o tsv)
success "Storage connection string retrieved"

# Step 3: Create App Service Plan
log "Step 3/8: Ensuring App Service Plan exists..."
if az appservice plan show --name "${APP_NAME}-plan" --resource-group $RESOURCE_GROUP &> /dev/null; then
   warning "App Service Plan ${APP_NAME}-plan already exists. Reusing."
else
   az appservice plan create \
      --name "${APP_NAME}-plan" \
      --resource-group $RESOURCE_GROUP \
      --is-linux \
      --sku B1 \
      --output none
   success "App Service Plan ${APP_NAME}-plan created with B1 tier"
fi

# Step 4: Create Web App
log "Step 4/8: Ensuring Web App exists..."
if az webapp show --name $APP_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
   warning "Web App $APP_NAME already exists. Reusing."
else
   log "Deploying Docker image: $DOCKER_IMAGE"
   az webapp create \
      --name $APP_NAME \
      --resource-group $RESOURCE_GROUP \
      --plan "${APP_NAME}-plan" \
      --container-image-name $DOCKER_IMAGE \
      --output none
   success "Web App $APP_NAME created successfully"
fi

# --- New Step: Mount File Share to Web App ---
log "Step 5/8: Mounting Azure File Share to Web App at /n8n..."
set +e
az webapp config storage-account add \
   --resource-group $RESOURCE_GROUP \
   --name $APP_NAME \
   --custom-id n8nfileshare \
   --storage-type AzureFiles \
   --account-name $STORAGE_ACCOUNT \
   --share-name $FILE_SHARE_NAME \
   --access-key $STORAGE_KEY \
   --mount-path /n8n \
   --output none
MOUNT_RESULT=$?
set -e
if [ $MOUNT_RESULT -ne 0 ]; then
   error "Failed to mount Azure File Share to /n8n. Exiting."
   exit 1
else
   success "File share $FILE_SHARE_NAME mounted to /n8n."
fi

log "Mount step completed, proceeding to app settings..."
# --- End New Step ---

# Step 6: Configure App Settings
log "Step 6/8: Configuring initial app settings..."
az webapp config appsettings set \
   --name $APP_NAME \
   --resource-group $RESOURCE_GROUP \
   --settings \
      WEBSITES_PORT=5678 \
      N8N_RUNNERS_ENABLED=true \
      APP_SERVICE_STORAGE=true \
      AZURE_STORAGE_CONNECTION_STRING="$STORAGE_CONN" \
      N8N_USER_FOLDER="/n8n/.n8n" \
      DB_TYPE=sqlite \
      DB_SQLITE_VACUUM_ON_STARTUP=true \
   --output none
success "Initial app settings configured"

# Step 7: Create OpenAI Cognitive Service
log "Step 7/8: Ensuring Azure OpenAI service exists..."
if az cognitiveservices account show --name $OPENAI_SERVICE_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
   warning "OpenAI service $OPENAI_SERVICE_NAME already exists. Reusing."
else
   log "OpenAI service name: $OPENAI_SERVICE_NAME"
   # Retry logic for OpenAI service creation
   RETRY_COUNT=0
   MAX_RETRIES=3
   while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
      log "Attempt $((RETRY_COUNT + 1))/$MAX_RETRIES to create OpenAI service..."
      if az cognitiveservices account create \
         --name $OPENAI_SERVICE_NAME \
         --resource-group $RESOURCE_GROUP \
         --kind OpenAI \
         --sku s0 \
         --location $LOCATION \
         --output none; then
         success "OpenAI service created successfully"
         break
      else
         RETRY_COUNT=$((RETRY_COUNT + 1))
         if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            warning "Failed to create OpenAI service, retrying in 10 seconds..."
            sleep 10
         else
            error "Failed to create OpenAI service after $MAX_RETRIES attempts"
            exit 1
         fi
      fi
   done
fi

# Get OpenAI credentials
log "Retrieving OpenAI credentials..."
OPENAI_KEY=$(az cognitiveservices account keys list \
   --name $OPENAI_SERVICE_NAME \
   --resource-group $RESOURCE_GROUP \
   --query key1 -o tsv)
   
OPENAI_ENDPOINT=$(az cognitiveservices account show \
   --name $OPENAI_SERVICE_NAME \
   --resource-group $RESOURCE_GROUP \
   --query properties.endpoint -o tsv)

success "OpenAI credentials retrieved"

# Configure OpenAI settings
log "Configuring OpenAI integration settings..."
az webapp config appsettings set \
   --name $APP_NAME \
   --resource-group $RESOURCE_GROUP \
   --settings \
      AZURE_OPENAI_API_KEY=$OPENAI_KEY \
      AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT \
   --output none

success "OpenAI integration configured"

# Step 8: Restart App Service
log "Step 8/8: Restarting app service to apply all configurations..."
az webapp restart \
   --name $APP_NAME \
   --resource-group $RESOURCE_GROUP \
   --output none

success "App service restarted successfully"

# --- New Step: Delayed Restart for Storage Mount ---
log "New Step: Waiting 10 minutes before a final restart to ensure storage mount is applied..."
sleep 600  # Wait for 600 seconds (10 minutes)
log "Restarting app service again to apply the storage mount..."
az webapp restart \
   --name $APP_NAME \
   --resource-group $RESOURCE_GROUP \
   --output none

success "Final restart completed. Storage mount should now be active."
# --- End New Step ---

# Final output
echo ""
echo "=========================================="
success "🎉 n8n Deployment Complete!"
echo "=========================================="
echo ""
log "Deployment Summary:"
log "  • Resource Group: $RESOURCE_GROUP"
log "  • App Service: $APP_NAME"
log "  • Storage Account: $STORAGE_ACCOUNT"
log "  • OpenAI Service: $OPENAI_SERVICE_NAME"
log "  • Location: $LOCATION"
echo ""
success "🌐 Access your n8n instance at:"
echo "   https://$APP_NAME.azurewebsites.net"
echo ""
log "📝 Note: It may take a few minutes for the application to fully start up."
log "🔧 You can monitor the deployment in the Azure Portal."
echo ""
warning "💡 Remember to:"
log "  • Configure your n8n workflows"
log "  • Set up proper authentication"
log "  • Monitor resource usage and costs"
echo ""
success "Deployment script completed successfully! 🚀"

# Export variables for pipeline use
echo "##vso[task.setvariable variable=appUrl]https://$APP_NAME.azurewebsites.net"
echo "##vso[task.setvariable variable=resourceGroup]$RESOURCE_GROUP"
echo "##vso[task.setvariable variable=appName]$APP_NAME"
echo "##vso[task.setvariable variable=storageAccount]$STORAGE_ACCOUNT"
echo "##vso[task.setvariable variable=openAIService]$OPENAI_SERVICE_NAME"