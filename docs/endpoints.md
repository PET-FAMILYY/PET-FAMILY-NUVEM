# Endpoints — Pet Family API

Base URL: `http://localhost:8080`

---

## Tutores

### POST /tutores
```json
{
  "nome": "Carlos Souza",
  "email": "carlos@email.com",
  "telefone": "(11) 98765-4321"
}
```

### GET /tutores
```
GET /tutores
GET /tutores?nome=Pedro
GET /tutores?page=0&size=10&sort=nome,asc
```

### GET /tutores/{id}
```
GET /tutores/1
```

### PUT /tutores/{id}
```json
{
  "nome": "Carlos Souza Jr.",
  "email": "carlos@email.com",
  "telefone": "(11) 91234-5678"
}
```

### DELETE /tutores/{id}
```
DELETE /tutores/1
```

---

## Pets

### POST /pets
```json
{
  "nome": "Rex",
  "especie": "Cachorro",
  "raca": "Labrador",
  "idade": 4,
  "peso": 32.0,
  "observacoesSaude": "Castrado. Sem alergias.",
  "tutorId": 1
}
```

### GET /pets
```
GET /pets
GET /pets?tutorId=1
GET /pets?especie=Gato
GET /pets?page=0&size=10&sort=nome,asc
```

### GET /pets/{id}
```
GET /pets/1
```
Retorna resumo clínico com `totalConsultas` e `totalLembretesPendentes`.

### PUT /pets/{id}
```json
{
  "nome": "Rex",
  "especie": "Cachorro",
  "raca": "Labrador",
  "idade": 5,
  "peso": 33.5,
  "observacoesSaude": "Castrado. Alergia ao frio.",
  "tutorId": 1
}
```

### DELETE /pets/{id}
```
DELETE /pets/1
```

---

## Consultas

### POST /consultas
```json
{
  "data": "2026-06-20",
  "horario": "14:00",
  "tipoConsulta": "Vacinação",
  "status": "AGENDADA",
  "observacoes": "V10 + antirrábica",
  "petId": 1
}
```

Status válidos: `AGENDADA`, `REALIZADA`, `CANCELADA`

### GET /consultas
```
GET /consultas
GET /consultas?status=AGENDADA
GET /consultas?page=0&size=10&sort=data,asc
```

### GET /consultas/futuras
```
GET /consultas/futuras
```
Retorna consultas com data >= hoje, ordenadas por data.

### PUT /consultas/{id}
```json
{
  "data": "2026-06-20",
  "horario": "15:30",
  "tipoConsulta": "Vacinação",
  "status": "REALIZADA",
  "observacoes": "Realizada com sucesso.",
  "petId": 1
}
```

---

## Lembretes

### POST /lembretes
```json
{
  "titulo": "Vermifugação",
  "descricao": "Vermifugação trimestral",
  "dataLembrete": "2026-07-15",
  "tipo": "Preventivo",
  "status": "PENDENTE",
  "petId": 1
}
```

Status válidos: `PENDENTE`, `CONCLUIDO`, `CANCELADO`

### GET /lembretes
```
GET /lembretes
GET /lembretes?status=PENDENTE
GET /lembretes?page=0&size=10&sort=dataLembrete,asc
```

### GET /lembretes/pet/{petId}/pendentes
```
GET /lembretes/pet/1/pendentes
```
Lista todos os lembretes PENDENTE de um pet específico.

---

## Interações IA

### POST /interacoes-ia
```json
{
  "pergunta": "Meu cachorro está tossindo muito, o que pode ser?",
  "categoria": "Sintomas",
  "petId": 1
}
```

### GET /interacoes-ia
```
GET /interacoes-ia
GET /interacoes-ia?page=0&size=10
```

### GET /interacoes-ia/pet/{petId}
```
GET /interacoes-ia/pet/1
```
Retorna histórico do pet ordenado do mais recente para o mais antigo.

---

## Dashboard

### GET /dashboard/resumo
```json
{
  "totalTutores": 4,
  "totalPets": 5,
  "totalConsultas": 6,
  "totalLembretesPendentes": 4,
  "totalInteracoesIA": 3,
  "taxaAdesaoPreventiva": 33.3
}
```

`taxaAdesaoPreventiva` = (consultasRealizadas / totalConsultas) × 100

---

## Respostas de Erro

```json
{
  "timestamp": "2026-05-12T10:30:00",
  "status": 404,
  "error": "Not Found",
  "message": "Pet não encontrado com id: 99",
  "path": "/pets/99"
}
```

| Código | Situação |
|---|---|
| 200 | Sucesso |
| 201 | Criado com sucesso |
| 204 | Removido com sucesso |
| 400 | Dados inválidos (validation error) |
| 404 | Recurso não encontrado |
| 500 | Erro interno |
