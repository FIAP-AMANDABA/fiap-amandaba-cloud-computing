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

## 10. Roteiro de testes no Swagger (dados prontos para copiar e colar)

Esta seção existe para agilizar a gravação do vídeo: é só abrir o `/swagger`, clicar em **"Try it out"**
em cada endpoint, colar o corpo (`body`) correspondente e executar (`Execute`). O roteiro cobre o par
de tabelas relacionadas usado na avaliação do CRUD — **Pets ↔ Consultas** — com pelo menos 2 registros
significativos em cada uma, além das quatro operações (inserir, alterar, excluir, consultar) exigidas
pelo enunciado.

> **Antes de começar:** você precisa de um `idTutor` válido (já existente no banco) e de um `idEspecie`
> válido. Se não souber os valores, rode primeiro `GET /api/especies` e anote o `id` da espécie que vai
> usar (ex.: Cachorro, Gato). Substitua `{idTutor}` pelos valores reais nos exemplos abaixo.

### Passo 1 — `GET /api/especies`
Sem corpo. Execute e anote o `id` de "Cachorro" e de "Gato" (ou as espécies disponíveis no seu banco).

### Passo 2 — Cadastrar 2 pets (`POST /api/tutores/{idTutor}/pets`)

**Pet 1 — Thor (cachorro):**
```json
{
  "idEspecie": 1,
  "nome": "Thor",
  "fotoUrl": "https://exemplo.com/fotos/thor.jpg",
  "raca": "Labrador",
  "sexo": "MACHO",
  "dataNascimento": "2021-03-15T00:00:00.000Z",
  "cor": "Caramelo",
  "castrado": true,
  "microchip": "981000012345678"
}
```

**Pet 2 — Luna (gata):**
```json
{
  "idEspecie": 2,
  "nome": "Luna",
  "fotoUrl": "https://exemplo.com/fotos/luna.jpg",
  "raca": "Siamês",
  "sexo": "FEMEA",
  "dataNascimento": "2022-07-02T00:00:00.000Z",
  "cor": "Cinza e branco",
  "castrado": true,
  "microchip": "981000087654321"
}
```

Execute os dois `POST` e anote o `petId` retornado em cada resposta (201) — você vai usá-los nos
próximos passos.

### Passo 3 — Consultar pets cadastrados (`GET /api/pets/{petId}`)
Sem corpo. Chame uma vez para o `petId` do Thor e uma vez para o `petId` da Luna, para evidenciar o
"Consultar" (SELECT) do pet recém-criado.

### Passo 4 — Cadastrar 2 consultas (`POST /api/pets/{petId}/consultas`)

**Consulta do Thor (check-up de rotina):**
```json
{
  "dataConsulta": "2026-09-10T13:00:00.000Z",
  "horario": "13:00",
  "veterinario": "Dra. Camila Souza",
  "clinica": "Clínica Veterinária Vida Animal",
  "motivo": "Check-up de rotina",
  "sintomas": "Nenhum sintoma relatado",
  "peso": 28.4,
  "diagnostico": "Animal saudável",
  "tratamento": "Nenhum tratamento necessário",
  "observacao": "Retorno recomendado em 6 meses",
  "retorno": true,
  "dataRetorno": "2027-03-10T13:00:00.000Z",
  "status": "AGENDADA"
}
```

**Consulta da Luna (consulta por vômito):**
```json
{
  "dataConsulta": "2026-09-08T09:30:00.000Z",
  "horario": "09:30",
  "veterinario": "Dr. Rafael Menezes",
  "clinica": "Clínica Veterinária Vida Animal",
  "motivo": "Vômito e falta de apetite",
  "sintomas": "Vômito nas últimas 24h, apatia",
  "peso": 4.1,
  "diagnostico": "Gastrite leve",
  "tratamento": "Dieta leve por 3 dias e omeprazol",
  "observacao": "Reavaliar se sintomas persistirem",
  "retorno": true,
  "dataRetorno": "2026-09-15T09:30:00.000Z",
  "status": "AGENDADA"
}
```

Use o `petId` do Thor para a primeira e o `petId` da Luna para a segunda. Anote o `consultaId`
retornado em cada resposta (201).

### Passo 5 — Alterar (UPDATE) uma consulta (`PUT /api/pets/{petId}/consultas/{consultaId}`)
Use o `petId` e `consultaId` da consulta do Thor:
```json
{
  "dataConsulta": "2026-09-10T13:00:00.000Z",
  "horario": "14:00",
  "veterinario": "Dra. Camila Souza",
  "clinica": "Clínica Veterinária Vida Animal",
  "motivo": "Check-up de rotina",
  "sintomas": "Nenhum sintoma relatado",
  "peso": 28.9,
  "diagnostico": "Animal saudável, ganho de peso leve",
  "tratamento": "Ajuste na quantidade de ração",
  "observacao": "Reavaliar peso no próximo retorno",
  "retorno": true,
  "dataRetorno": "2027-03-10T13:00:00.000Z",
  "status": "AGENDADA"
}
```
(Alterei o horário, o peso e o diagnóstico para deixar claro no vídeo que é uma edição de um
registro já existente.)

### Passo 6 — Alterar apenas o status (`PATCH /api/pets/{petId}/consultas/{consultaId}/status`)
Use o `petId` e `consultaId` da consulta da Luna:
```json
{
  "status": "REALIZADA"
}
```

### Passo 7 — Consultar novamente para evidenciar as alterações
- `GET /api/pets/{petId}/consultas/{consultaId}` para a consulta do Thor → mostra o novo peso/horário.
- `GET /api/pets/{petId}/consultas?status=REALIZADA` para a Luna → mostra a consulta filtrada pelo
  novo status.

### Passo 8 — Excluir (DELETE) um registro
`DELETE /api/pets/{petId}/consultas/{consultaId}` — use o `petId` e `consultaId` da consulta da Luna
(a que você acabou de marcar como `REALIZADA`), para fechar o ciclo completo de CRUD sobre a tabela
de Consultas. Em seguida, chame `GET /api/pets/{petId}/consultas` novamente para mostrar que o
registro não aparece mais na listagem.

### Passo 9 (opcional, se quiser reforçar o relacionamento) — Histórico de peso (`POST /api/pets/{petId}/pesos`)
Como reforço opcional do relacionamento Pets ↔ outra tabela, dá pra registrar peso para o Thor:
```json
{
  "peso": 28.9,
  "dataMedicao": "2026-09-10T13:00:00.000Z"
}
```
e depois consultar com `GET /api/pets/{petId}/pesos/atual`.

---

**Resumo para o vídeo:** os passos 2–8 acima já cobrem, nas duas tabelas relacionadas (Pets e
Consultas), inserção de 2 registros significativos em cada uma, alteração (`PUT` e `PATCH`),
exclusão (`DELETE`) e consulta (`GET`) — exatamente o que o item 9.3 do enunciado pede para ser
demonstrado por SELECT no banco após cada operação no Swagger.

## 11. Arquitetura

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
