# Roteiro do vídeo — Sprint 4 (até 80 pontos)

Requisitos: **mínimo 720p**, **áudio claro com explicação por voz**, **sem legendas**, ferramentas já abertas.
Duração-alvo: 12–15 min. Só grave depois de o pipeline ter rodado ao menos uma vez com sucesso (aquece a Service
Connection, o Environment e o Web App).

## Alteração de código para a gravação (NÃO aplicar antes)

Arquivo: [`OpenApiConfig.java`](../../src/main/java/br/com/fiap/petfamily/config/OpenApiConfig.java)

```java
// antes
.version("1.0.0")
// depois
.version("1.1.0-sprint4")
```

- **Antes** (mostrar na aplicação publicada): `https://<webapp>.azurewebsites.net/swagger-ui/index.html` exibe a badge `1.0.0`;
  `curl https://<webapp>.azurewebsites.net/api-docs | jq .info.version` → `"1.0.0"`.
- **Depois** do deploy: a badge e o `info.version` passam a `1.1.0-sprint4`, e `/actuator/info` mostra o novo
  `build.buildId` (número do build do Azure DevOps). Alteração pequena, visível e sem risco para os testes.

## Preparação (antes de gravar)

- [ ] Resolução da gravação ≥ 1280×720; microfone testado; fechar notificações.
- [ ] Abas abertas: **IDE** (projeto), **GitHub** (repositório/commits), **Azure DevOps** (Pipelines + Artifacts), **Portal Azure** (Resource Group), **cliente SQL** já conectado ao banco (psql/DBeaver), **Swagger** do Web App, terminal PowerShell na pasta do projeto.
- [ ] Pipeline com 1 execução verde anterior; Web App respondendo; `GET /actuator/health` = 200.
- [ ] Banco com schema migrado: `SELECT version, success FROM flyway_schema_history;` → 7 linhas.
- [ ] **Segredos fora da tela:** não abrir *App Settings → valores*, *Service Connection → credenciais*, Key/connection strings, senha do PostgreSQL, tokens do GitHub/Azure DevOps. No cliente SQL, conecte antes e minimize o diálogo de conexão. No `psql`, a senha vem de `PGPASSWORD`/prompt — limpe o terminal. Mostre o Portal só nas telas *Overview*, *Deployment Center/Log stream* e na lista de recursos.
- [ ] Dados reais intocados: o CRUD usa apenas registros `DEMO…` (e-mail `demo.sprint4.<timestamp>@exemplo.com`).
- [ ] Copiar para um bloco de notas: URL do Web App e `docs/sprint4/evidencias-crud.sql`.
- [ ] Trocar a branch para a de avaliação (`master`) e confirmar `git status` limpo.

## Sequência obrigatória e fala sugerida

| # | Tempo | Ação na tela | O que explicar (voz) |
|---|---|---|---|
| 1 | 0:00 | Mostrar IDE, GitHub, Azure DevOps, cliente SQL (banco) e Portal Azure, um por vez | Papel de cada ferramenta; abrir `docs/sprint4/arquitetura-cicd.svg` e percorrer o diagrama: caminho de entrega (1–10) × caminho de uso |
| 2 | 2:00 | Abrir `azure-pipelines.yml` na IDE e depois na UI do pipeline | Trigger em `master`; estágio **CI**: Cache, `Maven@4` com JDK 17 (`verify` = restore + compile + testes), publicação JUnit, `PublishPipelineArtifact`; estágio **CD**: `dependsOn CI`, `deployment` com Environment sem aprovação, `AzureWebApp@1` via Service Connection, smoke test |
| 3 | 4:00 | Na aplicação publicada, mostrar o **antes** (Swagger com `1.0.0`; `/actuator/info` com o buildId atual). Na IDE, editar `OpenApiConfig.java` | Que a mudança é pequena e que o `buildId` vai mudar com o novo build |
| 4 | 5:00 | Terminal: `git add -A; git commit -m "chore: versão 1.1.0-sprint4 da API"; git push origin master` | Commit direto na branch monitorada |
| 5 | 5:30 | Azure DevOps → Pipelines: execução surge sozinha (*Individual CI*, branch master, commit certo) | O disparo é automático via GitHub App; ninguém clicou em *Run* |
| 6 | 6:00 | Abrir a execução: expandir cada step do CI em andamento | Checkout, cache, `mvn verify` (testes unitários/integração e Testcontainers/PostgreSQL), cópia do `app.jar`, publicação do artefato |
| 7 | 8:00 | Aba **Tests** (total/aprovados, inclusive `PetCrudPersistenciaIntegrationTest`) e aba **Artifacts** (`petfamily-jar`: `app.jar`, `build-info.txt`) | Falha em teste/build interrompe o pipeline e o CD não roda; o artefato é o mesmo que será implantado |
| 8 | 9:00 | Estágio CD iniciando sozinho: logs do `AzureWebApp@1` e do *Smoke test* | Baixa o artefato da mesma execução; deploy; verificação de `health` e do `buildId` |
| 9 | 10:30 | Portal Azure: Resource Group → Web App (*Overview*, *Deployment Center*/*Log stream*), PostgreSQL Flexible Server | Recursos reais criados; banco em nuvem separado do Web App (sem mostrar segredos) |
| 10 | 11:30 | Swagger publicado mostra `1.1.0-sprint4`; `/actuator/info` com o novo buildId | **Depois** da alteração: prova de que a versão nova está no ar |
| 11 | 12:00 | Rodar `./docs/sprint4/crud-demo.ps1 -BaseUrl https://<webapp>.azurewebsites.net -Pausar` | CRUD completo, pausando após cada etapa |
| 12 | durante o CRUD | Alternar para o cliente SQL após cada pausa (tabela abaixo) | Dado gravado/alterado/removido diretamente no PostgreSQL do Azure |

## CRUD × SELECT (ordem exata, resultados esperados)

| Etapa do script | Requisição | SELECT (`evidencias-crud.sql`) | Resultado esperado |
|---|---|---|---|
| 0 Registro | `POST /auth/registrar` → 201 | "Extra" (usuarios) | 1 linha: e-mail `demo.sprint4.…`, role `TUTOR` |
| 1 Inserção | `POST /pets` → 201 | SELECT 1 | 1 linha: `DEMO-Sprint4-Rex`, Cachorro, SRD, idade 3, peso 12.5 |
| 2 Consulta | `GET /pets/{id}` e `GET /pets` → 200 | SELECT 2 | Mesmos valores do JSON; tutor = `DEMO Sprint4 Tutor …` |
| 3 Atualização | `PUT /pets/{id}` → 200 | SELECT 3 | `DEMO-Sprint4-Rex-Atualizado`, Labrador, idade 4, peso 14 |
| 4 Exclusão | `DELETE /pets/{id}` → 204; `GET` → 404 | SELECT 4 | `pets_demo_restantes = 0` |
| 5 Limpeza | `DELETE /tutores/{id}` → 204 | SELECT 5 | `0 | 0` (tutor e usuário removidos) |

Requisições equivalentes por `curl` (token em `$TOKEN`, obtido em `POST /auth/login`):

```bash
curl -s -X POST $URL/pets -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"nome":"DEMO-Sprint4-Rex","especie":"Cachorro","raca":"SRD","idade":3,"peso":12.5}'
curl -s $URL/pets/ID -H "Authorization: Bearer $TOKEN"
curl -s -X PUT $URL/pets/ID -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"nome":"DEMO-Sprint4-Rex-Atualizado","especie":"Cachorro","raca":"Labrador","idade":4,"peso":14.0}'
curl -s -o /dev/null -w "%{http_code}\n" -X DELETE $URL/pets/ID -H "Authorization: Bearer $TOKEN"
```

## Depois da gravação

- [ ] Conferir resolução, áudio e que nenhum segredo apareceu; sem legendas.
- [ ] Publicar no YouTube (público ou não listado, **acessível sem login**) e testar o link em janela anônima.
- [ ] Anotar o link para o PDF (`docs/sprint4/pdf/`).
- [ ] Reverter ou manter a alteração (`1.1.0-sprint4`); remover qualquer registro `DEMO` remanescente (SELECT 5).
