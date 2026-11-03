# Sprint 4 — Configuração do Azure DevOps e do Azure

Ordem de execução. Tudo aqui está **preparado, mas não executado**: nenhum recurso foi criado
e nenhum convite foi enviado (ver [Pendências](#pendências-reais) no README).

## 0. Relação com o material de aula (Módulo 19)

Os PDFs e arquivos do professor ficam fora do repositório (apenas consulta). O exemplo que melhor corresponde a este
projeto é o **PlayMix** (Java 17 + Spring Boot + Maven → Web App Linux, CI e CD como *stages* de um YAML).
O exemplo Pricewhisper (.NET/Oracle, com estágio de infraestrutura) não se aplica.

| Aproveitado do exemplo | Adaptado para este projeto |
|---|---|
| Estrutura `stages: CI → CD`, `deployment` com `environment`, artefato do pipeline consumido pelo deploy | Trigger em `master` **e** `main` (o exemplo usa só `Main`) |
| `JavaToolInstaller@0` + `Maven@4` (JDK 17) + `PublishPipelineArtifact@1` | `mvn verify` (testes reais, inclusive Testcontainers), artefato `app.jar` + `build-info.txt`, `-Dbuild.id` |
| `AzureWebApp@1` com `webAppLinux` + `zipDeploy`, runtime `JAVA:17-java17`, região `brazilsouth` | Nomes próprios (`petfamily-sprint4-api`, `sc-azure-sprint4`), smoke test do `buildId` |
| Segredos do banco fora do repositório | Banco **PostgreSQL** em nuvem (o exemplo usa Oracle FIAP); App Settings `DB_URL`/`DB_USER`/`DB_PASSWORD`/`JWT_SECRET` definidos por `provision.ps1` a partir de variável de ambiente (o `criar-infra.sh` do exemplo tem usuário/senha dentro do arquivo) |

Não adotados, de propósito: Azure Boards, branch policy/PR do Azure Repos, pipeline *classic*/Release, Application Insights
(não são exigidos pela Sprint) e as instruções de limpeza do laboratório (os recursos precisam ficar disponíveis para avaliação).
O código **permanece no GitHub**: o pipeline é conectado diretamente a ele, então cada push dispara o CI. Importar o código
para o Azure Repos exigiria sincronizar os dois repositórios continuamente; por isso não foi feito.

## 1. Pré-requisitos

- Conta Azure com assinatura ativa e **Azure CLI** (`az`) instalado: `winget install Microsoft.AzureCLI`.
- Organização no Azure DevOps (https://dev.azure.com) criada com a mesma conta Microsoft.
- Código da aplicação em um repositório GitHub com `azure-pipelines.yml` na raiz (ver README, seção "GitHub").

## 2. Projeto Azure DevOps

Via script (recomendado) — [`infra/azure/devops-setup.ps1`](../../infra/azure/devops-setup.ps1):

```powershell
az login
./infra/azure/devops-setup.ps1 -Organization <ORG> -NomeProfessor '<NOME DO PROFESSOR>' `
  -Integrantes '566551 - Pedro Vaz Ferreira - <TURMA>','565139 - João Victor Luiz Oliveira Resende - <TURMA>',`
               'RM565422 - Vitor Dias dos Santos - <TURMA>','RM561810 - Felipe Kirschner Modesto - <TURMA>' `
  -EmailProfessor <EMAIL_DO_PROFESSOR> -EnviarConvite
```

Cria o projeto exatamente com:

| Campo | Valor |
|---|---|
| Nome | `Sprint 4 – Azure DevOps` |
| Descrição | `Projeto para entrega da Sprint 4 do professor <nome>` + uma linha `<RM> - <nome completo> - <turma>` por integrante |
| Visibilidade | Private |
| Controle de versão | Git |
| Processo | Agile |

> Sem `-EnviarConvite` o script concede licença e permissão **sem e-mail**; o professor ainda precisa
> aceitar/entrar com a conta correta. Sem `-EmailProfessor`, nada é concedido.

## 3. Acesso do professor (dois níveis diferentes)

| Conceito | O que controla | Valor exigido | Onde configurar |
|---|---|---|---|
| **Nível de acesso** (access level / license) | Quais serviços a pessoa pode usar na organização (Repos, Pipelines, Boards, Test Plans) | **Basic** | Organization settings → Users |
| **Permissões no projeto** | O que a pessoa vê/faz dentro deste projeto | Grupo **Readers** (visualizar projeto, repositórios, pipelines e execuções) | Project settings → Permissions → Groups → Readers |

Sem Basic, o professor entra como Stakeholder e **não** vê Repos/Pipelines normalmente. Sem permissão
no projeto, ele aparece na organização mas não enxerga o projeto privado. Se, ao testar com a conta do
professor, algo não aparecer (ex.: Environments), suba o grupo para **Contributors**.

**Validação obrigatória (ainda não feita):** abrir o projeto com a conta do professor (janela anônima) e conferir
Repos, Pipelines → execuções e aba Tests/Artifacts.

## 4. Conectar o GitHub e criar o pipeline

1. Project settings → **Service connections** → New → GitHub (ou, na criação do pipeline, autorizar o *Azure Pipelines* GitHub App no repositório).
2. Pipelines → New pipeline → **GitHub** → escolher o repositório → *Existing Azure Pipelines YAML file* → `/azure-pipelines.yml` → Save.
3. Nome sugerido do pipeline: `petfamily-ci-cd`.

### Configurações fora do YAML que afetam o disparo automático

| Item | Valor | Por quê |
|---|---|---|
| Branch de avaliação | `master` (o YAML também aceita `main`) | O repositório GitHub hoje tem `main` como padrão. Para o vídeo, ou crie/use `master` no GitHub, ou faça o push em `main`. O trigger cobre as duas. **Não altere a branch padrão remota sem decidir isso.** |
| Pipeline settings → *Disable implied YAML CI trigger* | **desligado** | Se ligado, o `trigger:` do YAML é ignorado |
| Repositório GitHub → Settings → Webhooks / Apps | Azure Pipelines instalado no repositório | É o que entrega o evento de push ao Azure DevOps |
| Paralelismo (Organization settings → Pipelines → Parallel jobs) | ≥ 1 job Microsoft-hosted **ou** agente self-hosted | Contas novas não recebem paralelismo automaticamente: sem isso o pipeline falha com *"No hosted parallelism has been purchased or granted"*. Formulário de pedido gratuito: https://aka.ms/azpipelines-parallelism-request (pode levar dias; peça com antecedência) |
| Environment `petfamily-sprint4` | Sem approvals/checks | É criado na 1ª execução; **não** adicione aprovação (o CD precisa ser automático) |

## 5. Provisionar o Azure (gera custo)

```powershell
az login
az account show            # confirme a assinatura
$env:PETFAMILY_DB_PASSWORD = '<defina uma senha forte, ≥ 12 caracteres>'
./infra/azure/provision.ps1 -ClientIp <SEU_IP_PUBLICO>
```

Cria: Resource Group, PostgreSQL Flexible Server 16 (Burstable B1ms) com banco `petfamily`, plano Linux B1,
Web App Java SE 17 com App Settings (`SPRING_PROFILES_ACTIVE=prod`, `DB_URL`, `DB_USER`, `DB_PASSWORD`,
`JWT_SECRET`, `CORS_ALLOWED_ORIGINS`, `SWAGGER_ENABLED`) e regras de firewall só para os IPs de saída do
Web App e o seu IP. Os valores sensíveis vão direto ao App Service; nada é impresso nem versionado.

Se o nome `petfamily-sprint4-api` (ou do servidor PG) já existir no Azure, passe `-WebAppName`/`-PgServerName`
e **atualize `webAppName` em `azure-pipelines.yml`** para o mesmo valor.

Limitações assumidas: a aplicação usa o usuário administrador do PostgreSQL (simplicidade acadêmica; em produção
use um papel com privilégios mínimos) e os IPs de saída do Web App podem mudar se o plano for alterado — nesse
caso reexecute a parte de firewall.

## 6. Service Connection do Azure

Project settings → Service connections → New → **Azure Resource Manager** → *Service principal (automatic)* →
escopo: **Resource Group `rg-petfamily-sprint4`** → nome **`sc-azure-sprint4`** (igual a `azureServiceConnection` no YAML) →
*Grant access permission to all pipelines* marcado (ou autorize na 1ª execução).

## 7. Primeira execução e verificação

1. Faça push na `master`/`main` (ou *Run pipeline*). Autorize a Service Connection/Environment se o Azure DevOps pedir.
2. Estágio **CI**: aba *Tests* com os resultados; aba *Artifacts* com `petfamily-jar` (`app.jar`, `build-info.txt`).
3. Estágio **CD** inicia sozinho; o passo *Smoke test* confirma `/actuator/health` = 200 e que `/actuator/info` mostra
   `build.buildId` igual ao `Build.BuildNumber` da execução.
4. Abra `https://<webapp>.azurewebsites.net/swagger-ui/index.html` e rode `docs/sprint4/crud-demo.ps1`.

## 8. Riscos conhecidos de configuração

- Primeiro start do Web App (Flyway + JVM em B1) pode passar de 2 min: já há `WEBSITES_CONTAINER_START_TIME_LIMIT=600`
  e o smoke test espera até 5 min.
- Porta: o `provision.ps1` fixa `--server.port=80` no *startup command*; se a plataforma não responder, confira o *Log stream*.
- O trigger só dispara se o evento de push chegar ao Azure DevOps (App do GitHub instalado). Sem o App, nada roda.
