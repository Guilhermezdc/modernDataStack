# 🚀 stack-modern — Modern Data Stack (README principal)

**Airbyte • Airflow • dbt • PostgreSQL**

Este repositório demonstra uma **plataforma analítica end-to-end** (production-style) que mostra como times de dados modernos ingere, transforma e serve dados usando uma Modern Data Stack.  
Inclui instruções para instalar localmente (Airbyte via `abctl`), orquestrar com Airflow e usar Postgres como data warehouse.

---

## 📁 Estrutura final do repositório

```md
## 📂 Pastas principais

- 📁 [`config/`](config) — Configurações do Airflow  
- 📁 [`dags/`](dags) — DAGs  
- 📁 [`prodDataBuilder/`](prodDataBuilder) — dbt (models, macros, analyses)  
- 📄 [`Dockerfile`](Dockerfile)

```
---

## 🧠 ARCHITECTURE — Modern Data Stack

Este projeto implementa uma **Modern Data Stack** com:

- **Airbyte** para ingestão
- **PostgreSQL** como Data Warehouse
- **dbt** para transformações
- **Airflow** para orquestração

### 🔄 High-level flow

```text
Source Systems
      │
      ▼
   Airbyte
      │
      ▼
PostgreSQL (raw)
      │
      ▼
     dbt
      │
      ▼
PostgreSQL (analytics)
      │
      ▼
   BI / SQL
```

Layers

Layer	Purpose
raw	Dados exatamente como ingeridos pelo Airbyte (raw tables)
staging	Dados limpos e padronizados (stg_*)
marts	Tabelas analíticas: facts & dimensions otimizadas para BI

Por que essa arquitetura
Este design alinha com práticas de times de dados reais para garantir:

Qualidade de dados

Escalabilidade

Reprodutibilidade

Modelos prontos para análise

## 🧰 SETUP — Instalação Local

Requisitos
Docker & Docker Compose (V2 preferível)

Git & Python 3.9+

Memória: Mínimo 8GB RAM (12GB+ recomendado)

### 1) Iniciar PostgreSQL (Docker Compose)

Antes de tudo você precisar de criar um arquivo .envS

Suba o banco de dados:

```bash
docker-compose -f docker-compose-postgres.yaml up -d
```
Depois suba os serviços do airflow:

```bash
docker compose up -d
```
Acesse:

Airflow UI: http://localhost:8080 (user: admin / pass: admin)

Postgres: host=localhost, port=5432, user=root, password=`2skj(Hk2hksf2`, db=analytics

Observação: para ambientes Docker em Mac/Windows, se precisar que containers acessem serviços host, use host.docker.internal como host para conexões a serviços rodando na máquina host.

### 2) Instalar e rodar Airbyte via abctl (local)

abctl é o instalador CLI oficial do Airbyte para setups locais.

Instalar abctl:

```bash
curl -LsfS https://get.airbyte.com | bash
```
Instalar Airbyte localmente:

```bash
abctl local install
```
Isso:

cria um cluster/local runtime e instala Airbyte (k8s/kit usado pelo abctl)

expõe UI do Airbyte em http://localhost:8000

Abra http://localhost:8000 e siga o assistente para criar sources e destinations.

### 3) Conectar Airbyte → PostgreSQL
No Airbyte UI:

Create Destination

Tipo: PostgreSQL

Host: host.docker.internal ou postgres (se você rodar tudo no mesmo compose e apontar via network)

Port: 5432

Database: analytics

User: root

Password: `2skj(Hk2hksf2`

Schema: raw

Create Source (ex.: API pública, MySQL local, CSV, etc.)

Create Connection

Sync frequency: conforme desejar (manual, hourly, daily)

Namespace / Schema: raw

Modo: incremental quando disponível (CDC) ou full-refresh conforme o caso

Depois do sync, dados aparecerão como analytics.raw.<nome_da_tabela>.

### 4) Instalar e configurar dbt (local)

> Notas: Nesse projeto ao rodar o docker-compose o dbt já é configurado automaticamente, porém, vou deixar uma breve explicação.
Instale o adaptador Postgres do dbt:

```bash
Copiar código
pip install dbt-core
pip install dbt-postgres
```
Inicie um projeto dbt:

```bash
dbt init prodDataBuilder
cd analytics_platform
```
Exemplo mínimo de profiles.yml (em ~/.dbt/profiles.yml):

```yaml
analytics_platform:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: root
      password: 2skj(Hk2hksf2
      port: 5432
      dbname: analytics
      schema: analytics
```
Verifique a conexão:

bash
Copiar código
dbt debug
Rodar modelos:

bash
Copiar código
dbt run
dbt test
dbt docs generate
dbt docs serve

## 🔁 PIPELINES — Fluxo dos dados
Ingestão
Airbyte extrai dados de APIs / DBs e grava no schema raw do Postgres:
analytics.raw.*

Transformação
dbt cria camadas:

staging (stg_*) — limpeza e padronização

marts — facts & dims prontos para BI

Orquestração
Airflow DAG (exemplo) executa em sequência:

Trigger Airbyte sync (via API)

dbt run

dbt test

Notificação / validação

Fluxo lógico:

text
Copiar código
Airbyte Sync → dbt run → dbt test → (alerts)

## 🧱 DBT — Como modelar
Estrutura sugerida
pgsql
Copiar código
models/
  staging/
    stg_customers.sql
    stg_orders.sql
  marts/
    dim_customers.sql
    fact_orders.sql
Boas práticas
Use ref() e evite hard-coded table names.

Separe camadas: staging → marts.

Escreva testes (not_null, unique, relationships).

Documente modelos com schema.yml.

Use incremental models quando a fonte permitir.

Exemplo simples de fact_orders.sql:

sql
Copiar código
select
  order_id,
  customer_id,
  order_date,
  total_amount
from {{ ref('stg_orders') }}
Comandos dbt comuns:

bash
Copiar código
dbt run --models marts
dbt test --models +marts
dbt docs generate
⏱ AIRFLOW — Orquestração
Airflow orquestra a execução dos passos do pipeline. Um DAG típico deve:

Fazer chamada à API do Airbyte para iniciar o sync (Airbyte API)

Aguardar conclusão / checar status

Executar dbt run (via BashOperator ou DockerOperator)

Executar dbt test

Emitir alertas (Slack / email) em caso de falha

DAG flow (visual):

text
Copiar código
airbyte_sync_task -> dbt_run_task -> dbt_test_task -> notify_task
Observação: para integração Airbyte ↔ Airflow, existem patterns:

Usar o requests para chamar a API do Airbyte (start sync / check job status)

Usar DockerOperator ou KubernetesPodOperator para rodar dbt de forma isolada

📊 DATA — Fontes de dados
Este projeto suporta:

REST APIs (ex.: JSON públicos)

Bancos relacionais (MySQL/Postgres)

CSVs / arquivos locais (upload via Airbyte)

Event streams (quando usar Kafka)

Fluxo: toda fonte → raw → staging → marts → analytics
