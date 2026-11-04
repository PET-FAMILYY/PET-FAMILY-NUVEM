# Pet Family API: Sprint 4 · DevOps Tools & Cloud Computing

> **FIAP · Turma 2TDSPG** · Pipeline CI/CD no **Azure DevOps**, deploy automático em **Azure Web App** e banco **PostgreSQL** em nuvem.
> A aplicação (API REST em Java 17 + Spring Boot) já existia; esta entrega adiciona a esteira de DevOps e a infraestrutura na nuvem.

## Integrantes

| Nome | RM | Turma |
|---|---|---|
| Felipe Kirschner Modesto | RM561810 | 2TDSPG |
| João Victor Luiz de Oliveira Resende | RM565139 | 2TDSPG |
| Pedro Henrique Vaz Ferreira | RM566551 | 2TDSPG |
| Vitor Dias dos Santos | RM565422 | 2TDSPG |

## Links da entrega

| Item | Link |
|---|---|
| Repositório GitHub | [PET-FAMILYY/PET-FAMILY-NUVEM](https://github.com/PET-FAMILYY/PET-FAMILY-NUVEM) (branch `master`) |
| Projeto Azure DevOps | [Sprint 4 – Azure DevOps](https://dev.azure.com/petfamily-sprint4/Sprint%204%20%E2%80%93%20Azure%20DevOps) |
| Pipelines (CI/CD) | [Execuções](https://dev.azure.com/petfamily-sprint4/Sprint%204%20%E2%80%93%20Azure%20DevOps/_build) |
| Vídeo (YouTube) | **pendente**, será incluído após a publicação |


---

## Ciclo implementado

**Alteração no código → push na `master` → CI automático (build + testes) → artefato no Azure DevOps → CD automático → deploy no Azure Web App → CRUD validado no PostgreSQL em nuvem.**

![Arquitetura e CI/CD](docs/sprint4/arquitetura-cicd.png)



## Decisões de arquitetura

| Item | Decisão |
|---|---|
| Código-fonte | GitHub; o Azure Pipelines lê o repositório direto (GitHub App), sem espelhar no Azure Repos |
| Pipeline | [`azure-pipelines.yml`](azure-pipelines.yml): estágio **CI** e estágio **CD** no mesmo YAML, para o CD usar o artefato **da mesma execução** |
| Trigger | push em `master` (e `main`); pull request não dispara |
| Hospedagem | **Azure Web App Linux (Java SE 17)** recebendo o `app.jar`, sem registry de contêiner |
| Banco em nuvem | **Azure Database for PostgreSQL – Flexible Server 16** (SSL obrigatório); o schema é criado pelo **Flyway** (V1–V7) na subida |
| Segredos | Nada no repositório: `DB_URL`, `DB_USER`, `DB_PASSWORD` e `JWT_SECRET` são *App Settings* do Web App; a credencial do Azure fica na Service Connection |

## Pipeline

### CI: build e testes (`ubuntu-latest`)

1. Checkout do GitHub.
2. JDK 17 (`JavaToolInstaller@0`).
3. Cache das dependências Maven (`Cache@2`).
4. Preparo do Docker para o Testcontainers (`api.version=1.44`), para o teste de migrations rodar em PostgreSQL real.
5. `Maven@4 verify`: compila, executa os **28 testes** e gera o JAR. Resultados JUnit publicados na aba **Tests**. Falha em teste interrompe o pipeline e o CD não roda.
6. Artefato `petfamily-jar` publicado na aba **Artifacts** (`app.jar` + `build-info.txt`), com o número do build gravado no JAR.

### CD: deploy (automático, sem aprovação)

1. Roda só se o CI passar (`dependsOn: CI`), em um *deployment job* no Environment `petfamily-sprint4`.
2. `AzureWebApp@1` (`webAppLinux`, `zipDeploy`) via Service Connection `sc-azure-sprint4`, baixando o `app.jar` do artefato.
3. **Smoke test:** consulta até 45 vezes `/actuator/health` (deve ser 200) e `/actuator/info` (deve conter o número do build). Só termina com sucesso quando a versão nova está de fato no ar.

## Recursos no Azure

| Recurso | Nome | Detalhe |
|---|---|---|
| Resource Group | `rg-petfamily-sprint4` | região `brazilsouth` |
| PostgreSQL Flexible Server | `petfamily-sprint4-pg` | v16, Burstable B1ms, banco `petfamily`, firewall só para o Web App e o IP de quem consulta |
| Plano do App Service | `plan-petfamily-sprint4` | Linux B1 |
| Web App | `petfamily-sprint4-api` | Java SE 17, HTTPS obrigatório, perfil `prod` |

Todos criados por [`infra/azure/provision.ps1`](infra/azure/provision.ps1) (idempotente; senhas vêm de variáveis de ambiente, nada é impresso nem versionado).

## Configuração do Azure DevOps

| Item | Valor |
|---|---|
| Organização / projeto | `petfamily-sprint4` / **Sprint 4 – Azure DevOps** (privado, Git, Agile); a descrição traz o professor, os RMs, nomes e turma |
| Pipeline | criado a partir do GitHub, branch `master`, arquivo `azure-pipelines.yml` |
| Service Connection | `sc-azure-sprint4` (Azure Resource Manager, escopo no Resource Group) |
| Environment | `petfamily-sprint4`, sem *approvals* nem *checks* (CD automático) |
| Professor | Antonio Sergio Rodrigues Figueiredo, nível de acesso **Basic** e grupo **Contributors** do projeto |

Pontos que afetam o disparo automático: *Disable implied YAML CI trigger* desligado; Azure Pipelines instalado no repositório do GitHub; ao menos 1 job com paralelismo Microsoft-hosted disponível na organização.

## Evidência do CRUD no banco em nuvem

O CRUD de `pets` é feito pelo **Swagger da aplicação publicada** e conferido com `SELECT` direto no PostgreSQL do Azure após cada operação (registro de tutor, criação, leitura, atualização e exclusão).

- Script automatizado equivalente: [`docs/sprint4/crud-demo.ps1`](docs/sprint4/crud-demo.ps1) (`-BaseUrl https://petfamily-sprint4-api.azurewebsites.net -Pausar`).
- SELECTs de conferência: [`docs/sprint4/evidencias-crud.sql`](docs/sprint4/evidencias-crud.sql).
- Os testes automatizados também cobrem o CRUD com SELECT na tabela: `PetCrudPersistenciaIntegrationTest`.



## Como reproduzir

```powershell
az login
$env:PETFAMILY_DB_PASSWORD = '<senha forte, mínimo 12 caracteres>'
./infra/azure/provision.ps1 -ClientIp <SEU_IP_PUBLICO>     # cria Resource Group, PostgreSQL, plano e Web App (gera custo)
./infra/azure/devops-setup.ps1 -Organization <ORG> ...      # cria o projeto e dá acesso ao professor
```

Depois, no Azure DevOps: criar a Service Connection ARM (`sc-azure-sprint4`), criar o pipeline apontando para `azure-pipelines.yml` e fazer push na `master`. Se mudar os nomes dos recursos, atualize `webAppName` e `azureServiceConnection` no YAML.

## Status

| Item | Status |
|---|---|
| Pipeline CI → CD disparado por push, com 28/28 testes, artefato, deploy e smoke test | Verificado (execução `20261103.8`) |
| Web App, PostgreSQL e Flyway V1–V7 no Azure | Verificado |
| CRUD na API publicada com SELECT no PostgreSQL do Azure | Verificado |
| Projeto Azure DevOps privado, Git, Agile, com descrição | Criado |
| Professor com acesso Basic | Convite enviado, aguardando o primeiro acesso dele |
| Vídeo no YouTube e PDF final | Vídeo gravado |

---

## Sobre a aplicação

**Pet Family API** é o backend do acompanhamento contínuo da saúde de pets (tutores, pets, consultas, cuidados preventivos, assistente de IA e dashboard clínico), em Java 17, Spring Boot 3.2.5, JPA, Flyway, Spring Security com JWT e testes automatizados.

Execução local: `mvn spring-boot:run` (H2, `http://localhost:9090/swagger-ui/index.html`).

Documentação completa da aplicação (entidades, segurança, migrations, fluxos de negócio, endpoints, Docker, Oracle, changelog): [`docs/api-java.md`](docs/api-java.md).

## Estrutura do repositório

```
├── azure-pipelines.yml        ← CI/CD do Azure DevOps
├── infra/azure/               ← provisionamento do Azure e do Azure DevOps (scripts)
├── docs/
│   ├── api-java.md            ← documentação da aplicação Java
│   └── sprint4/               ← diagrama, CRUD, SELECTs e gerador do PDF
├── src/                       ← código da API e testes
├── Dockerfile, docker-compose.yml, render.yaml   ← execução local e deploy alternativo (Render)
└── pom.xml
```
