#!/bin/bash
# =========================================================================
# DEPLOY AUTOMATIZADO - PROJETO AMANDABA
# Disciplina: DevOps Tools & Cloud Computing - Sprint 3
# Opção escolhida: Azure App Service (SEM containerização) + Banco Oracle PaaS
# =========================================================================
# RECURSOS CRIADOS NESTA EXECUÇÃO:
#   1) Resource Group          -> agrupa todos os recursos do projeto
#   2) App Service Plan (Linux)-> infraestrutura (VM/SKU) que hospeda o app
#   3) Web App (.NET 8)        -> onde a aplicação de fato roda
#   4) App Settings             -> variáveis de ambiente da aplicação em nuvem
#   5) Connection String Oracle -> credencial de acesso ao banco (não vai no código)
#   6) Publish Profile          -> credencial usada pelo GitHub Actions para deployar
#
# OBS: o deploy do CÓDIGO da aplicação em si acontece depois, via GitHub
# Actions (arquivo .github/workflows/deploy.yml), disparado a cada push
# na branch main. Este script aqui só prepara a infraestrutura na Azure.
# =========================================================================

set -e 
# -------------------------------------------------------------------------
# CREDENCIAIS OBRIGATÓRIAS (via variável de ambiente, nunca hardcoded)
# -------------------------------------------------------------------------
# Antes de rodar, exporte no terminal:
#   export RM_AZURE=123456
#   export ORACLE_USER=rmXXXXX
#   export ORACLE_PASSWORD=suasenha
: "${RM_AZURE:?defina RM_AZURE antes de rodar}"
: "${ORACLE_USER:?defina ORACLE_USER antes de rodar}"
: "${ORACLE_PASSWORD:?defina ORACLE_PASSWORD antes de rodar}"

# -------------------------------------------------------------------------
# VARIÁVEIS DE CONFIGURAÇÃO DO AMBIENTE AZURE
# -------------------------------------------------------------------------
LOCATION="canadacentral"                        # região do datacenter Azure
RESOURCE_GROUP="rg-amandaba-${RM_AZURE}"        # agrupador lógico dos recursos
APP_SERVICE_PLAN="plan-amandaba-${RM_AZURE}"    # plano de hospedagem (SKU F1 = Free)
WEBAPP_NAME="webapp-amandaba-${RM_AZURE}"       # nome público do Web App
RUNTIME="DOTNETCORE:8.0"                        # stack .NET 8 (Advanced Business Development with .NET)
SKU="F1"                                        # camada gratuita do App Service

# String de conexão com o banco Oracle da FIAP
ORACLE_DATASOURCE="oracle.fiap.com.br:1521/ORCL"
ORACLE_CONNECTION_STRING="User Id=${ORACLE_USER};Password=${ORACLE_PASSWORD};Data Source=${ORACLE_DATASOURCE};"

echo ">> Iniciando provisionamento da infraestrutura na Azure via CLI..."

# =========================================================================
# 1. CRIAR O RESOURCE GROUP
# =========================================================================
echo ""
echo "[1/6] Criando Resource Group '$RESOURCE_GROUP'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

# =========================================================================
# 2. CRIAR O APP SERVICE PLAN (LINUX)
# =========================================================================
echo ""
echo "[2/6] Criando App Service Plan '$APP_SERVICE_PLAN' (Linux, SKU $SKU)..."
az appservice plan create \
  --name "$APP_SERVICE_PLAN" \
  --resource-group "$RESOURCE_GROUP" \
  --is-linux \
  --sku "$SKU"

# =========================================================================
# 3. CRIAR O WEB APP COM RUNTIME .NET 8
# =========================================================================
echo ""
echo "[3/6] Criando Web App '$WEBAPP_NAME' (runtime $RUNTIME)..."
az webapp create \
  --resource-group "$RESOURCE_GROUP" \
  --plan "$APP_SERVICE_PLAN" \
  --name "$WEBAPP_NAME" \
  --runtime "$RUNTIME"

# =========================================================================
# 4. HABILITAR BUILD AUTOMÁTICO DURANTE O DEPLOY
# =========================================================================
echo ""
echo "[4/6] Habilitando build automático (SCM_DO_BUILD_DURING_DEPLOYMENT)..."
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT="true"

# =========================================================================
# 5. CONFIGURAR A CONNECTION STRING DO ORACLE COMO APP SETTING
# =========================================================================
echo ""
echo "[5/6] Configurando Connection String do Oracle no App Service..."
az webapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --settings \
    ConnectionStrings__Oracle="$ORACLE_CONNECTION_STRING"

# =========================================================================
# 6. OBTER O PUBLISH PROFILE
#    Credencial que o GitHub Actions (azure/webapps-deploy@v3) usa para
#    autenticar e enviar o build do app para este Web App específico.
#    Deve ser copiado e salvo no GitHub como o secret
#    AZURE_WEBAPP_PUBLISH_PROFILE (Settings > Secrets and variables > Actions).
# =========================================================================
echo ""
echo "[6/6] Obtendo Publish Profile para configurar o GitHub Actions..."
echo "=========================================================================="
echo "Copie TODO o XML abaixo e cole como o secret AZURE_WEBAPP_PUBLISH_PROFILE"
echo "no GitHub (Settings > Secrets and variables > Actions > New repository secret)"
echo "=========================================================================="
az webapp deployment list-publishing-profiles \
  --resource-group "$RESOURCE_GROUP" \
  --name "$WEBAPP_NAME" \
  --xml

# =========================================================================
# RESUMO FINAL
# =========================================================================
echo ""
echo ">> Infraestrutura provisionada com sucesso na Azure!"
echo ">> URL da aplicação: https://${WEBAPP_NAME}.azurewebsites.net"
echo ">> Próximo passo: configure o secret AZURE_WEBAPP_PUBLISH_PROFILE no GitHub"
echo ">> e faça 'git push' na branch main para disparar o deploy do código via"
echo ">> GitHub Actions (.github/workflows/deploy.yml)."