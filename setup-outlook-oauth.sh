#!/bin/bash
APP_NAME="n8n-outlook-$(date +%s)"
N8N_CALLBACK_URL="https://your-n8n-instance.com/oauth2/callback"

TENANT_ID=$(az account show --query tenantId -o tsv)
APP_ID=$(az ad app create --display-name "$APP_NAME" --sign-in-audience "AzureADandPersonalMicrosoftAccount" --web-redirect-uris "$N8N_CALLBACK_URL" --query appId -o tsv)

OBJECT_ID=$(az ad app show --id $APP_ID --query id -o tsv)
az rest --method PATCH --uri "https://graph.microsoft.com/v1.0/applications/$OBJECT_ID" --headers 'Content-Type=application/json' --body '{
    "requiredResourceAccess": [
        {
            "resourceAppId": "00000003-0000-0000-c000-000000000000",
            "resourceAccess": [
                {"id": "570282fd-fa5c-430d-a7fd-fc8dc98a9dca", "type": "Scope"},
                {"id": "e383f46e-2787-4529-855e-0e479a3ffac0", "type": "Scope"}
            ]
        }
    ]
}'

CLIENT_SECRET=$(az ad app credential reset --id $APP_ID --years 1 --query password -o tsv)

cat <<EOF
=== n8n Outlook Configuration ===
Client ID: $APP_ID
Client Secret: $CLIENT_SECRET
Callback URL: $N8N_CALLBACK_URL
Admin Consent URL: https://login.microsoftonline.com/$TENANT_ID/adminconsent?client_id=$APP_ID
EOF