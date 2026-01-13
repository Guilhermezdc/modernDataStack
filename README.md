# 🚀 stack-modern — Modern Data Stack (README principal)

**Airbyte • Airflow • dbt • PostgreSQL**

Este repositório demonstra uma **plataforma analítica end-to-end** (production-style) que mostra como times de dados modernos ingere, transforma e serve dados usando uma Modern Data Stack.  
Inclui instruções para instalar localmente (Airbyte via `abctl`), orquestrar com Airflow e usar Postgres como data warehouse.

---

## 📁 Estrutura final do repositório

stack-modern/
├── README.md ← Página principal (este arquivo)
├── ARCHITECTURE.md ← Arquitetura técnica (opcional: separado)
├── SETUP.md ← Como rodar tudo local (opcional: separado)
├── PIPELINES.md ← Como os dados fluem (opcional: separado)
├── DBT.md ← Como você modela dados (opcional: separado)
├── AIRFLOW.md ← Como você orquestra (opcional: separado)
├── DATA.md ← Fontes de dados (opcional: separado)
└── .gitignore

markdown
Copiar código

> **Nota rápida para recrutadores técnicos:** os quatro arquivos que você provavelmente abrirá primeiro são:
> - `README.md` (este)  
> - `SETUP.md`  
> - `ARCHITECTURE.md`  
> - `DBT.md`  

---

## 🧠 ARCHITECTURE — Modern Data Stack

Este projeto implementa uma **Modern Data Stack** com:

- **Airbyte** para ingestão
- **PostgreSQL** como Data Warehouse
- **dbt** para transformações
- **Airflow** para orquestração

### High-level flow

Source Systems → Airbyte → PostgreSQL (raw)
                          ↓
                         dbt
                          ↓
                 PostgreSQL (analytics)
                          ↓
                     BI / SQL
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

🧰 SETUP — Como rodar local
Requisitos
Docker

Docker Compose (v2 preferível)

Git

Python 3.9+ (para dbt local / utilitários)

Pelo menos 8GB de RAM (ideal 12GB+)

1) Iniciar PostgreSQL & Airflow (Docker Compose)
Crie um arquivo docker-compose.yml no repositório com o conteúdo abaixo (exemplo mínimo):

yaml
Copiar código
version: "3.8"

services:
  postgres:
    image: postgres:15
    container_name: warehouse
    environment:
      POSTGRES_USER: analytics
      POSTGRES_PASSWORD: analytics
      POSTGRES_DB: analytics
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  airflow:
    image: apache/airflow:2.8.1
    container_name: airflow
    environment:
      AIRFLOW__CORE__LOAD_EXAMPLES: "false"
      AIRFLOW__CORE__EXECUTOR: "SequentialExecutor"
      AIRFLOW__DATABASE__SQL_ALCHEMY_CONN: "postgresql+psycopg2://analytics:analytics@postgres/analytics"
    depends_on:
      - postgres
    ports:
      - "8080:8080"
    command: >
      bash -c "
      airflow db init &&
      airflow users create --username admin --password admin --firstname Guilherme --lastname Stefano --role Admin --email admin@example.com &&
      airflow webserver & airflow scheduler
      "

volumes:
  pgdata:
Suba os serviços:

bash
Copiar código
docker compose up -d
Acesse:

Airflow UI: http://localhost:8080 (user: admin / pass: admin)

Postgres: host=localhost, port=5432, user=analytics, password=analytics, db=analytics

Observação: para ambientes Docker em Mac/Windows, se precisar que containers acessem serviços host, use host.docker.internal como host para conexões a serviços rodando na máquina host.

2) Instalar e rodar Airbyte via abctl (local)
abctl é o instalador CLI oficial do Airbyte para setups locais.

Instalar abctl:

bash
Copiar código
curl -LsfS https://get.airbyte.com | bash
Verifique a versão:

bash
Copiar código
abctl version
Instalar Airbyte localmente:

bash
Copiar código
abctl local install
Isso:

cria um cluster/local runtime e instala Airbyte (k8s/kit usado pelo abctl)

expõe UI do Airbyte em http://localhost:8000

Abra http://localhost:8000 e siga o assistente para criar sources e destinations.

3) Conectar Airbyte → PostgreSQL
No Airbyte UI:

Create Destination

Tipo: PostgreSQL

Host: host.docker.internal ou postgres (se você rodar tudo no mesmo compose e apontar via network)

Port: 5432

Database: analytics

User: analytics

Password: analytics

Schema: raw

Create Source (ex.: API pública, MySQL local, CSV, etc.)

Create Connection

Sync frequency: conforme desejar (manual, hourly, daily)

Namespace / Schema: raw

Modo: incremental quando disponível (CDC) ou full-refresh conforme o caso

Depois do sync, dados aparecerão como analytics.raw.<nome_da_tabela>.

4) Instalar e configurar dbt (local)
Instale o adaptador Postgres do dbt:

bash
Copiar código
pip install dbt-postgres
Inicie um projeto dbt:

bash
Copiar código
dbt init analytics_platform
cd analytics_platform
Exemplo mínimo de profiles.yml (em ~/.dbt/profiles.yml):

yaml
Copiar código
analytics_platform:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: analytics
      password: analytics
      port: 5432
      dbname: analytics
      schema: analytics
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
🔁 PIPELINES — Fluxo dos dados
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
🧱 DBT — Como modelar
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
