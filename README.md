# n8n Azure Deployment Toolkit

[![n8n + Azure + OpenAI Integration](https://3tallah.com/wp-content/uploads/2025/07/Deploy-n8n-on-Azure-with-OpenAI-Azure-App-Services-Step-by-Step-591x394.png)](https://3tallah.com/ultimate-guide-deploy-n8n-on-azure-with-openai-azure-app-services-step-by-step/)

## 📦 Contents
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Script Overview](#-script-overview)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features
- **Single-command deployment** of n8n to Azure App Service
- **Integrated Azure OpenAI setup** with retry logic
- **Built-in Outlook 365 OAuth2 configuration**
- **Automatic App Service and Storage provisioning**
- **Smart logging and validations**
- **Persistent configuration using App Settings**

## 🚀 Quick Start

### Prerequisites
- Azure subscription with Contributor rights
- Azure CLI installed ([install guide](https://learn.microsoft.com/cli/azure/install-azure-cli))
- Bash shell (Linux/macOS/WSL or Git Bash)

### Deploy with One Command
```bash
# Clone repository
git clone https://github.com/3tallah/n8n-azure-deployment.git
cd n8n-azure-deployment

# Make script executable
chmod +x deploy-n8n-azure-pipeline.sh

# Run the full deployment
bash deploy-n8n-azure-pipeline.sh
````

> ✅ The script includes everything: resource group, storage, App Service, OpenAI service, app settings, Outlook OAuth2 support, and auto-restart.

## 📜 Script Overview

### `n8n_deployment_script.sh` - Complete Azure Deployment

This single script performs:

1. Azure login check
2. Resource group creation
3. Storage account provisioning
4. App Service Plan and Web App deployment (Linux container with Docker)
5. Configuration of required app settings (e.g., `WEBSITES_PORT`, `AZURE_STORAGE_CONNECTION_STRING`)
6. Azure OpenAI resource creation with key and endpoint configuration
7. Optional Outlook 365 OAuth2 setup (placeholder for integration)
8. Web App restart and access summary


## ⚙️ Configuration

The script auto-generates most names using `$RANDOM`, but you can modify variables at the top of the script if needed:

### Example Defaults

```bash
RESOURCE_GROUP="n8n-resources"
LOCATION="eastus"
DOCKER_IMAGE="docker.n8n.io/n8nio/n8n:latest"
```

### Outlook Integration
`setup-outlook-oauth.sh` - Creates:
1. Azure AD app registration
2. Outlook API permissions
3. Client secret (valid 1 year)
4. Admin consent URL

### Support Files
- `workflow-examples/` - Sample n8n JSON workflows
- `docs/` - Visual guides and troubleshooting

### Environment Settings Configured in Azure

| Setting                           | Description                                      |
| --------------------------------- | ------------------------------------------------ |
| `WEBSITES_PORT`                   | Required port for n8n container (default `5678`) |
| `AZURE_STORAGE_CONNECTION_STRING` | Used for persistent data                         |
| `AZURE_OPENAI_API_KEY`            | Automatically retrieved                          |
| `AZURE_OPENAI_ENDPOINT`           | Automatically configured                         |

## 🛠 Troubleshooting

| Problem               | Solution                                    |
| --------------------- | ------------------------------------------- |
| Azure CLI not found   | Install from official docs                  |
| App doesn’t start     | Confirm container port is `5678`            |
| OpenAI creation fails | Script retries 3 times by default           |
| Missing permissions   | Ensure your Azure user has Contributor role |

### View Logs

```bash
az webapp log tail --name <app-name> --resource-group <resource-group>
```

## 📁 Project Structure

```

n8n-azure-deployment/
├── n8n_deployment_script.sh    # Unified deployment script
├── LICENSE                     # MIT License
├── README.md                   # This file
├── workflow-examples/          # Sample n8n workflows
│   ├── email-summarizer.json   # Outlook→OpenAI→Slack
│   └── ai-assistant.json       # ChatGPT integration
└── docs/                       # Visual guides
    ├── deployment-steps.md     # Screenshot guide
    └── architecture.png        # System diagram
```

## 🔗 Additional Resources

* [n8n Docs](https://docs.n8n.io)
* [Azure App Service](https://learn.microsoft.com/azure/app-service)
* [Azure OpenAI](https://learn.microsoft.com/azure/cognitive-services/openai/)
* [Microsoft Graph OAuth Permissions](https://learn.microsoft.com/graph/permissions-reference)

## 🤝 Contributing
1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for full details.

## 👤 Author

**Mahmoud A. ATALLAH**

* GitHub: [@3tallah](https://github.com/3tallah)
* LinkedIn: [Mahmoud A. Atallah](https://www.linkedin.com/in/mahmoudatallah)