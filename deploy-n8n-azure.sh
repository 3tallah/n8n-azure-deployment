#!/bin/bash
# Full deployment script from our chat history
RESOURCE_GROUP="n8n-resources"
LOCATION="eastus"
APP_NAME="n8n-app-$RANDOM"
DOCKER_IMAGE="docker.n8n.io/n8nio/n8n:latest"

az login
az group create --name $RESOURCE_GROUP --location $LOCATION

STORAGE_ACCOUNT="n8nstorage$RANDOM"
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --sku Standard_LRS
STORAGE_CONN=$(az storage account show-connection-string --name $STORAGE_ACCOUNT --query connectionString -o tsv)

az appservice plan create --name "${APP_NAME}-plan" --resource-group $RESOURCE_GROUP --is-linux --sku B1
az webapp create --name $APP_NAME --resource-group $RESOURCE_GROUP --plan "${APP_NAME}-plan" --deployment-container-image-name $DOCKER_IMAGE

az webapp config appsettings set --name $APP_NAME --resource-group $RESOURCE_GROUP --settings \
  WEBSITES_PORT=5678 \
  N8N_RUNNERS_ENABLED=true \
  APP_SERVICE_STORAGE=true \
  AZURE_STORAGE_CONNECTION_STRING="$STORAGE_CONN"

for i in {1..3}; do
  OPENAI_NAME="n8n-ai-$RANDOM"
  az cognitiveservices account create --name $OPENAI_NAME --resource-group $RESOURCE_GROUP --kind OpenAI --sku s0 && break || sleep 10
done

OPENAI_KEY=$(az cognitiveservices account keys list --name $OPENAI_NAME --resource-group $RESOURCE_GROUP --query key1 -o tsv)
OPENAI_ENDPOINT=$(az cognitiveservices account show --name $OPENAI_NAME --resource-group $RESOURCE_GROUP --query properties.endpoint -o tsv)

az webapp config appsettings set --name $APP_NAME --resource-group $RESOURCE_GROUP --settings \
  AZURE_OPENAI_API_KEY=$OPENAI_KEY \
  AZURE_OPENAI_ENDPOINT=$OPENAI_ENDPOINT

az webapp restart --name $APP_NAME --resource-group $RESOURCE_GROUP

echo "Deployment Complete! Access your n8n instance at:"
echo "https://$APP_NAME.azurewebsites.net"