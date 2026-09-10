# Amandaba — Cloud Computing (Sprint 3)

Repositório da disciplina **DevOps Tools & Cloud Computing**, referente ao provisionamento de
infraestrutura na Azure do projeto **Amandaba**.

> O código-fonte da aplicação (.NET 8, disciplina *Advanced Business Development with .NET*) está em
> um repositório separado: **[fiap-amandaba-dotnet](https://github.com/FIAP-AMANDABA/fiap-amandaba-dotnet)**.
> Este repositório aqui contém apenas o que diz respeito à entrega de Cloud Computing: script de
> provisionamento via Azure CLI, DDL do banco e a documentação da arquitetura da solução.

---

## 1. Descrição da solução

O Amandaba é uma API REST para gestão da saúde de pets: cadastro de animais, histórico de peso,
vacinas, doenças, alergias, medicamentos, consultas, exames e um plano de cuidados personalizado
gerado por IA Generativa (Google Gemini), cruzando os dados clínicos reais de cada pet.

Detalhes completos de endpoints, camadas e tecnologias estão no README do repositório de código:
[fiap-amandaba-dotnet](https://github.com/FIAP-AMANDABA/fiap-amandaba-dotnet).

## 2. Benefícios para o negócio

- Centraliza em um único lugar informações hoje dispersas entre memória do tutor, papéis e
  prontuários de clínicas diferentes.
- Reduz dúvidas recorrentes na clínica veterinária, já que o tutor tem acesso ao histórico e a um
  plano de cuidados gerado automaticamente.
- Permite cruzar dados clínicos (ex.: medicamentos em uso x alergias registradas) que hoje dependem
  de análise manual da equipe.

## 3. Opção de entrega escolhida

**Serviço de Aplicativo (Azure App Service)** — sem containerização, com banco de dados em nuvem via
PaaS (Oracle, instância da FIAP).

| Recurso | Descrição |
|---|---|
| Resource Group | Agrupador lógico de todos os recursos |
| App Service Plan | Linux, SKU F1 (Free) |
| Web App | Runtime `DOTNETCORE:8.0`, sem container |
| Banco de dados | Oracle (PaaS, FIAP) — **não é o H2** |

Todos os recursos são criados exclusivamente via **Azure CLI**, através do script
[`deploy_auramed_azure.sh`](./deploy_auramed_azure.sh) deste repositório.

## 4. Banco de dados em nuvem

- Banco utilizado: **Oracle** (`oracle.fiap.com.br:1521/ORCL`), acessado via
  `Oracle.EntityFrameworkCore` a partir da aplicação .NET.
- O DDL das tabelas (estrutura, colunas, chaves primárias e comentários) está no arquivo
  [`script_bd.sql`](./script_bd.sql) deste repositório.
- As tabelas utilizadas representam o CORE da solução (ex.: Pets, Consultas, Medicamentos, Vacinas,
  Doenças, Alergias, Histórico de Peso) — nenhuma tabela de apoio genérico (cidade, estado, usuário
  de acesso etc.) é usada para fins de avaliação do CRUD.

## 5. CRUD

O CRUD completo (inclusão, alteração, exclusão e consulta) é implementado na aplicação, sobre pelo
menos duas tabelas relacionadas entre si (ex.: Pets ↔ Consultas). A implementação em si — controllers,
use cases e repositories — está no repositório de código:
[fiap-amandaba-dotnet](https://github.com/FIAP-AMANDABA/fiap-amandaba-dotnet).

## 6. Pré-requisitos para reproduzir o provisionamento

- Azure CLI instalado e autenticado (`az login`)
- Acesso à assinatura Azure usada na disciplina
- Credenciais do banco Oracle da FIAP (usuário e senha)
- Permissão para criar recursos na assinatura (Resource Group, App Service Plan, Web App)

## 7. Como rodar o script de provisionamento

O script [`deploy_auramed_azure.sh`](./deploy_auramed_azure.sh) cria toda a infraestrutura via Azure
CLI. Ele não recebe credenciais fixas no código — todas vêm de variáveis de ambiente, para não expor
dados sensíveis no repositório.

```bash
export RM_AZURE=SEU_RM
export ORACLE_USER=SEU_USUARIO_ORACLE
export ORACLE_PASSWORD=SUA_SENHA_ORACLE

bash deploy_auramed_azure.sh
```

O script executa, nesta ordem:

1. Criação do Resource Group
2. Criação do App Service Plan (Linux, F1)
3. Criação do Web App (.NET 8)
4. Habilitação do build automático no deploy (`SCM_DO_BUILD_DURING_DEPLOYMENT`)
5. Configuração da Connection String do Oracle como App Setting
6. Emissão do Publish Profile do Web App (referência/backup — o pipeline atual de deploy usa
   autenticação via Service Principal, não este XML)

Ao final, o script imprime a URL pública da aplicação:
`https://webapp-amandaba-<RM_AZURE>.azurewebsites.net`.

## 8. Deploy do código e CI/CD

A publicação do código da aplicação (build, publish e deploy) é feita via **GitHub Actions**,
configurado no repositório [fiap-amandaba-dotnet](https://github.com/FIAP-AMANDABA/fiap-amandaba-dotnet),
disparado a cada push na branch `main` daquele repositório. O pipeline:

1. Faz checkout do código e build do projeto .NET 8
2. Publica e compacta o resultado em um `.zip`
3. Autentica na Azure via Service Principal (`AZURE_CREDENTIALS`)
4. Atualiza a Connection String do Oracle como App Setting
5. Faz o deploy do `.zip` no Web App via `az webapp deployment source config-zip`

Os secrets necessários (`AZURE_CREDENTIALS`, `RM_AZURE`, `ORACLE_USER`, `ORACLE_PASSWORD`) ficam
configurados no repositório de código, nunca neste repositório de Cloud Computing.

## 9. Testando a aplicação publicada

Com o deploy concluído, a documentação interativa da API fica disponível em:

```text
https://webapp-amandaba-<RM_AZURE>.azurewebsites.net/swagger
```

## 10. Arquitetura

```text
Tutor / Usuário
      │  HTTPS
      ▼
Azure App Service (.NET 8, Linux, F1)
      │  EF Core / Oracle.EntityFrameworkCore
      ▼
Oracle Database (PaaS, FIAP)

GitHub Actions ──(Zip Deploy)──▶ Azure App Service
```

Nenhum componente é containerizado, em conformidade com os requisitos da opção "Serviço de
Aplicativo (App Service)".

## Links da entrega

- Repositório de código (C# / .NET): https://github.com/FIAP-AMANDABA/fiap-amandaba-dotnet
- Repositório de Cloud Computing (este): https://github.com/FIAP-AMANDABA/fiap-amandaba-cloud-computing
