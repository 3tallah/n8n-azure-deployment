# n8n Azure Deployment Toolkit

[![n8n + Azure + OpenAI Integration](https://3tallah.com/wp-content/uploads/2025/07/Deploy-n8n-on-Azure-with-OpenAI-Azure-App-Services-Step-by-Step-591x394.png)](https://3tallah.com/ultimate-guide-deploy-n8n-on-azure-with-openai-azure-app-services-step-by-step/)

## 📦 Contents
- [Features](#-features)
- [Quick Start](#-quick-start)
- [Scripts](#-scripts)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

## ✨ Features
- **One-click deployment** of n8n to Azure App Service
- **Automated Azure OpenAI integration** with retry logic
- **Outlook OAuth2 setup** with proper permission scopes
- **Persistent storage** configuration
- **Visual guides** for each deployment step

## 🚀 Quick Start

### Prerequisites
- Azure account with contributor permissions
- Azure CLI installed ([installation guide](https://docs.microsoft.com/cli/azure/install-azure-cli))
- Bash shell (Linux/macOS/WSL)

### Deployment
```bash
# Clone repository
git clone https://github.com/3tallah/n8n-azure-deployment.git
cd n8n-azure-deployment

# Make scripts executable
chmod +x *.sh

# Run main deployment
./deploy-n8n-azure.sh

# Configure Outlook integration
./setup-outlook-oauth.sh
```

## 📜 Scripts

### Main Deployment Script
`deploy-n8n-azure.sh` - Handles:
1. Resource group creation
2. Storage account setup
3. App Service configuration
4. Azure OpenAI integration
5. Environment variables setup


### Outlook Integration
`setup-outlook-oauth.sh` - Creates:
1. Azure AD app registration
2. Outlook API permissions
3. Client secret (valid 1 year)
4. Admin consent URL


### Support Files
- `workflow-examples/` - Sample n8n JSON workflows
- `docs/` - Visual guides and troubleshooting

## ⚙️ Configuration

### Environment Variables
| Variable | Description | Required |
|----------|-------------|----------|
| `APP_NAME` | n8n application name | ❌ (auto-generated) |
| `RESOURCE_GROUP` | Azure resource group | ❌ (default: n8n-resources) |
| `N8N_CALLBACK_URL` | For Outlook OAuth2 | ✅ |

### Customizing Deployment
Edit `config.sh` to modify:
```bash
# Azure region
LOCATION="eastus"

# App Service SKU
SKU="B1"

# OpenAI model
OPENAI_MODEL="text-davinci-003"
```

## 🛠 Troubleshooting

### Common Issues
| Error | Solution |
|-------|----------|
| `ResourceNotFound` | Wait 2 minutes after app creation |
| `PermissionDenied` | Run `az login` with admin account |
| `ContainerNotStarting` | Verify `WEBSITES_PORT=5678` |

### View Logs
```bash
az webapp log tail --name <app-name> --resource-group n8n-resources
```

# Deployment Package Structure
```
n8n-azure-deployment/
├── deploy-n8n-azure.sh         # Main deployment script
├── setup-outlook-oauth.sh      # Outlook OAuth2 setup
├── config.sh                   # Configuration defaults
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
- [n8n Documentation](https://docs.n8n.io)
- [Azure App Service Docs](https://docs.microsoft.com/azure/app-service)
- [Microsoft Graph Permissions](https://learn.microsoft.com/graph/permissions-reference)



## 🤝 Contributing
1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

## 👤 Author
**Your Name**  
- GitHub: [@3tallah](https://github.com/3tallah)
- LinkedIn: [Mahmoud A. ATALLAH](https://www.linkedin.com/in/mahmoudatallah)


