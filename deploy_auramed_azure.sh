#!/bin/bash
# =========================================================================
# DEPLOY - PROJETO AMANDABA
# =========================================================================

set -e

# ---------- Credenciais/valores obrigatórios via variável de ambiente ----------
# Injeção via GitHub Actions Secrets):
: "${RM_AZURE:?defina RM_AZURE antes de rodar}"
: "${ORACLE_USER:?defina ORACLE_USER antes de rodar}"
: "${ORACLE_PASSWORD:?defina ORACLE_PASSWORD antes de rodar}"
: "${GITHUB_TOKEN:?defina GITHUB_TOKEN antes de rodar}"

LOCATION="canadasouth"
RESOURCE_GROUP="rg-amandaba-${RM_AZURE}"
APP_SERVICE_PLAN="plan-amandaba-${RM_AZURE}"
WEBAPP_NAME="webapp-amandaba-${RM_AZURE}"
RUNTIME="DOTNETCORE:8.0"
SKU="F1"

GITHUB_BRANCH="main"

ORACLE_DATASOURCE="oracle.fiap.com.br:1521/ORCL"
ORACLE_CONNECTION_STRING="User Id=${ORACLE_USER};Password=${ORACLE_PASSWORD};Data Source=${ORACLE_DATASOURCE};"

# =========================================================================
# 1. Criar o Resource Group
# =========================================================================
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# =========================================================================
# 2. Criar o App Service Plan (Linux)
# =========================================================================
az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --is-linux \
  --sku "$SKU"

# =========================================================================
# 3. Criar o Web App com runtime .NET
# =========================================================================
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_SERVICE_PLAN" \
  --name "$WEBAPP_NAME" \
  --runtime "$RUNTIME"

# =========================================================================
# 4. Habilitar build automático durante o deploy
# =========================================================================
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT="true"

# =========================================================================
# 5. Configurar a Connection String do Oracle como App Setting
# =========================================================================
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings \
    ConnectionStrings__Oracle="$ORACLE_CONNECTION_STRING"

# =========================================================================
# 6. Configurar o deploy a partir do repositório GitHub via GitHub Actions
# =========================================================================
az webapp deployment github-actions add \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --repo "FIAP-AMANDABA/fiap-amandaba-dotnet" \
  --branch "$GITHUB_BRANCH" \
  --token "$GITHUB_TOKEN"

# =========================================================================
# 7. Exibir a URL final da aplicação
# =========================================================================
echo "Deploy configurado com sucesso!"
echo "URL da aplicação: https://${WEBAPP_NAME}.azurewebsites.net"