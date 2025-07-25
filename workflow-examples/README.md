**This basic `ai-assistant.json` sample workflow** that integrates:

* **Outlook 365 (Microsoft Graph API)** – to read recent emails
* **Azure OpenAI (ChatGPT)** – to summarize email content
* Designed for **self-hosted n8n** with environment variables (`AZURE_OPENAI_API_KEY`, `AZURE_OPENAI_ENDPOINT`, `OUTLOOK_ACCESS_TOKEN`) already configured.

---

### ✅ `ai-assistant.json` – Basic Outlook + Azure OpenAI Integration

```json
{
  "nodes": [
    {
      "parameters": {
        "authentication": "headerAuth",
        "url": "https://graph.microsoft.com/v1.0/me/messages?$top=1",
        "method": "GET",
        "headerParametersUi": {
          "parameter": [
            {
              "name": "Authorization",
              "value": "Bearer {{$env.OUTLOOK_ACCESS_TOKEN}}"
            }
          ]
        }
      },
      "name": "Get Latest Email",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 2,
      "position": [200, 300],
      "credentials": {
        "httpHeaderAuth": {
          "id": "outlook-token",
          "name": "OutlookToken"
        }
      }
    },
    {
      "parameters": {
        "authentication": "headerAuth",
        "url": "={{$env.AZURE_OPENAI_ENDPOINT}}/openai/deployments/gpt-35-turbo/chat/completions?api-version=2023-07-01-preview",
        "method": "POST",
        "headerParametersUi": {
          "parameter": [
            {
              "name": "Content-Type",
              "value": "application/json"
            },
            {
              "name": "api-key",
              "value": "={{$env.AZURE_OPENAI_API_KEY}}"
            }
          ]
        },
        "options": {},
        "bodyParametersJson": "={\n  \"messages\": [\n    {\"role\": \"system\", \"content\": \"You are a helpful assistant that summarizes emails.\"},\n    {\"role\": \"user\", \"content\": \"Summarize this email:\n\nSubject: {{$json['value'][0]['subject']}}\n\nBody: {{$json['value'][0]['body']['content']}}\"}\n  ],\n  \"temperature\": 0.7\n}"
      },
      "name": "Summarize with Azure OpenAI",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 2,
      "position": [500, 300],
      "credentials": {
        "httpHeaderAuth": {
          "id": "azure-openai-headers",
          "name": "AzureOpenAIHeader"
        }
      }
    },
    {
      "parameters": {
        "mode": "passThrough",
        "responseCode": 200
      },
      "name": "Return Summary",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1,
      "position": [800, 300]
    }
  ],
  "connections": {
    "Get Latest Email": {
      "main": [
        [
          {
            "node": "Summarize with Azure OpenAI",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Summarize with Azure OpenAI": {
      "main": [
        [
          {
            "node": "Return Summary",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "name": "Outlook Email Summarizer",
  "active": false,
  "settings": {},
  "tags": ["azure", "openai", "outlook", "graphapi", "summarizer"]
}
```

---

### 🔧 Requirements

* `AZURE_OPENAI_API_KEY`: Stored as environment variable or App Setting.
* `AZURE_OPENAI_ENDPOINT`: Like `https://<your-resource>.openai.azure.com`
* `OUTLOOK_ACCESS_TOKEN`: Bearer token for Graph API. Use OAuth2 setup or manual token for testing.

---

### 📝 Behavior

1. **Get Latest Email** using Microsoft Graph.
2. **Send Subject + Body** to Azure OpenAI Chat endpoint.
3. **Return the summary** via webhook or UI (depending on usage).