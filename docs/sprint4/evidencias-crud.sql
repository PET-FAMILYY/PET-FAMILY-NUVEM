-- Evidências do CRUD direto no PostgreSQL (Azure Database for PostgreSQL).
-- Conexão (psql, DBeaver ou Azure Data Studio) com SSL obrigatório; a senha NÃO fica aqui:
--   psql "host=<servidor>.postgres.database.azure.com port=5432 dbname=petfamily user=<usuario> sslmode=require"
-- (a senha é pedida no prompt; deixe o prompt/histórico fora do enquadramento da gravação).
-- Todas as consultas filtram o registro de demonstração (prefixo DEMO) — nunca dados reais.

-- 0) Antes de começar: confirmar o schema criado pelo Flyway no deploy
SELECT version, description, success FROM flyway_schema_history ORDER BY installed_rank;
-- esperado: 7 linhas (V1..V7) com success = true

-- 1) Após CREATE (POST /pets): 1 linha
SELECT id, nome, especie, raca, idade, peso, tutor_id
  FROM pets
 WHERE nome LIKE 'DEMO-Sprint4%'
 ORDER BY id DESC;
-- esperado: nome = DEMO-Sprint4-Rex, especie = Cachorro, raca = SRD, idade = 3, peso = 12.5

-- 2) Após READ (GET /pets/{id}): conferir com o JSON da API e o dono do pet
SELECT p.id, p.nome, p.especie, p.raca, p.idade, p.peso, t.nome AS tutor, t.email
  FROM pets p
  JOIN tutores t ON t.id = p.tutor_id
 WHERE p.nome LIKE 'DEMO-Sprint4%';
-- esperado: mesmos valores retornados pela API; tutor = "DEMO Sprint4 Tutor <timestamp>"

-- 3) Após UPDATE (PUT /pets/{id}): valores alterados
SELECT id, nome, raca, idade, peso
  FROM pets
 WHERE nome LIKE 'DEMO-Sprint4%';
-- esperado: nome = DEMO-Sprint4-Rex-Atualizado, raca = Labrador, idade = 4, peso = 14

-- 4) Após DELETE (DELETE /pets/{id}): ausência
SELECT COUNT(*) AS pets_demo_restantes
  FROM pets
 WHERE nome LIKE 'DEMO-Sprint4%';
-- esperado: 0

-- 5) Após a limpeza do tutor (DELETE /tutores/{id}): ausência do tutor e do usuário de login
SELECT (SELECT COUNT(*) FROM tutores  WHERE nome LIKE 'DEMO Sprint4 Tutor%') AS tutores_demo,
       (SELECT COUNT(*) FROM usuarios WHERE email LIKE 'demo.sprint4.%')     AS usuarios_demo;
-- esperado: 0 | 0

-- Extra (mostra o tutor e o usuário criados no passo 0, rode ANTES da limpeza):
SELECT u.id AS usuario_id, u.email, u.role, u.tutor_id, u.criado_em
  FROM usuarios u
 WHERE u.email LIKE 'demo.sprint4.%';
-- Obs.: senha_hash existe na tabela; NÃO a inclua nas consultas mostradas no vídeo.
