# 🚀 Modern Data Stack - Production Data Pipeline

**Airbyte • Airflow • dbt • PostgreSQL**

A complete, production-ready Modern Data Stack implementation demonstrating best practices for building scalable data platforms. This project ingests data from multiple sources, transforms it through dbt, and orchestrates everything with Apache Airflow.

---

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Quick Start](#-quick-start)
- [Data Models](#-data-models)
- [Testing & Quality](#-testing--quality)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)

---

## 🏗 Architecture

### High-Level Data Flow

```
Source Systems
      │
      ▼
   Airbyte (Extraction & Loading)
      │
      ▼
PostgreSQL - raw schema (Raw Data)
      │
      ▼
     dbt (Transformation Layer)
      │
      ├─▶ staging schema (stg_*) - Data cleaning & standardization
      │
      └─▶ mart schema (fact_*, dim_*) - Analytics-ready tables
      │
      ▼
PostgreSQL - mart schema (Analytical Views)
      │
      ▼
   BI Tools / SQL Analytics
```

### Technology Stack

| Component | Purpose | Version |
|-----------|---------|---------|
| **PostgreSQL** | Data Warehouse | 15+ |
| **dbt** | Transformation & Testing | 1.5+ |
| **Airflow** | Orchestration | 2.6+ |
| **Airbyte** | Data Integration | Abctl Local |
| **Docker** | Containerization | V2+ |

### Layers & Schemas

| Layer | Schema | Purpose | Materialization |
|-------|--------|---------|-----------------|
| **Raw** | `raw_producao`, `raw_bolsa`, `raw_nibo` | Exact copy from sources via Airbyte | Tables |
| **Staging** | `staging` | Cleaned, standardized data | **Views** |
| **Mart** | `mart` | Analytics-ready facts & dimensions | **Tables** |

---

## 📂 Project Structure

```
modernDataStack/
├── config/                    # Airflow configuration
├── dags/                      # Airflow DAG definitions
│   └── maindags.py           # Main ETL orchestration pipeline
├── prodDataBuilder/          # dbt project root
│   ├── dbt_project.yml       # dbt configuration
│   ├── profiles.yml          # Database connection settings (uses env vars for security)
│   ├── models/
│   │   ├── staging/          # Transformation layer 1 (data cleaning)
│   │   │   ├── stg_*.sql     # Staging models
│   │   │   └── sources.yml   # Source definitions & column-level tests
│   │   └── mart/             # Transformation layer 2 (analytical models)
│   │       ├── fact_*.sql    # Fact tables (events, transactions)
│   │       ├── dim_*.sql     # Dimension tables (entities)
│   │       ├── agg_*.sql     # Aggregation tables
│   │       └── schema.yml    # Mart model documentation & tests
│   ├── tests/                # Custom SQL tests for data quality
│   ├── macros/               # dbt macros (reusable SQL functions)
│   ├── snapshots/            # SCD Type 2 snapshots (currently unused)
│   └── seeds/                # CSV seed files for dimension data
├── docker-compose.yaml       # Container orchestration
├── docker-compose-postgres.yaml  # PostgreSQL container
├── .env.example              # Environment variable template
└── README.md                 # This file
```

---

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose V2
- Git
- Python 3.9+
- 8GB RAM minimum (24GB+ recommended)

### 1. Set Up Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your settings:

```env
AIRFLOW_UID=1000
DBT_HOST=localhost
DBT_USER=root
DBT_PASSWORD=your_secure_password
DBT_DBNAME=analytics
DBT_SCHEMA_DEV=staging
DBT_SCHEMA_PROD=mart
```

### 2. Start PostgreSQL

```bash
docker-compose -f docker-compose-postgres.yaml up -d
```

Verify connection:
```bash
psql -h localhost -U root -d analytics
```

### 3. Start Airflow

```bash
docker-compose up -d
```

Access UI: http://localhost:8080 (user: admin / pass: admin)

### 4. Install Airbyte (Local via abctl)

```bash
curl -LsfS https://get.airbyte.com | bash
abctl local install
```

Access UI: http://localhost:8000

### 5. Run dbt Transforms

```bash
cd prodDataBuilder

# Test connection
dbt debug

# Run all models
dbt run

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve  # http://localhost:8001
```

---

## 📊 Data Models

### Staging Models (Raw → Staging)

**Location**: `prodDataBuilder/models/staging/`

Staging models perform:
- Column renaming & standardization
- Data type conversions
- Basic deduplication
- NULL handling

**Key staging models**:
- `stg_tb_processos` - Process/case data
- `stg_tb_crm_clientes` - CRM lead records
- `stg_tb_sedes` - Branch/office locations
- `stg_tb_servicos` - Service definitions with classification (AVA+/AVB/AVA)
- 25+ more staging models

### Mart Models (Staging → Marts)

**Location**: `prodDataBuilder/models/mart/`

#### Fact Tables (Events/Transactions)

1. **`fact_vendas`** - Sales transactions
   - Combines old & new business models
   - Matches processes with payment transactions
   - Includes all columns for sales analytics

2. **`fact_crm_leads`** - CRM lead journey
   - Tracks lead progression through actions
   - Maps action IDs: 3,9,15 (entry) → 4,8,22 (exit)
   - Outputs: Contact Made → Won/Lost/Disputed

3. **`fact_leads_contestados`** - Disputed/contested leads
   - Tracks dispute flows and resolutions
   - Complex multi-table joins

4. **`fact_leads_leiloados`** - Auction leads
   - Leads that went through auction process
   - Captures winning bids and values

5. **`fact_vendas_bolsa`** - Auction to sales matching
   - Links auction leads to completed sales
   - **Lead matching window: 75 days** (configured from sales analysis)
   - Regional office mapping logic

#### Dimension Tables (Entities)

1. **`dim_crm_leads`** - Customer dimension
   - Customer attributes (name, contact, location)
   - Original source: CRM system

---

## ✅ Testing & Quality

### Test Coverage

All models and sources include comprehensive tests:

```yaml
tests:
  - unique         # No duplicate keys
  - not_null       # Required fields populated
  - relationships  # Foreign key integrity
  - accepted_values # Valid enumerated values
  - dbt_utils.*    # Custom range/expectation tests
```

### Running Tests

```bash
# All tests
dbt test

# Specific model
dbt test --select fact_vendas

# Specific test type
dbt test --select test_type:unique
```

### Test Configuration

- **Column-level tests**: Defined in `sources.yml` and `schema.yml`
- **Data freshness**: Tracked via `_loaded_at` metadata fields
- **Custom tests**: Can be added to `tests/` directory

### Documentation

All models are fully documented:

```bash
dbt docs generate
dbt docs serve
```

Browse at http://localhost:8001

---

## ⚙️ Configuration

### Environment Variables

Key variables (all in `.env`):

```
# Database
DBT_HOST          - PostgreSQL host
DBT_USER          - Database user
DBT_PASSWORD      - Database password (use secure vault in production)
DBT_DBNAME        - Database name
DBT_SCHEMA_DEV    - Development schema
DBT_SCHEMA_PROD   - Production schema

# Airflow
AIRFLOW_UID       - Airflow user ID for container permissions

# Airbyte
AIRBYTE_API_URL   - Airbyte API endpoint (stored securely in Airflow Connections)
```

### dbt Configuration

**profiles.yml** uses environment variables for credentials:

```yaml
outputs:
  dev:
    host: "{{ env_var('DBT_HOST', 'localhost') }}"
    user: "{{ env_var('DBT_USER') }}"
    password: "{{ env_var('DBT_PASSWORD') }}"
    threads: 4
  prod:
    threads: 8
```

**dbt_project.yml** defines:
- Model materialization (views vs tables)
- Schema naming conventions
- Seed configurations

### Airflow Configuration

**maindags.py** creates a daily pipeline:

1. Triggers Airbyte sync (3 connections in sequence)
2. Waits for Airbyte job completion (polls every 30 seconds)
3. Runs `dbt run` to build/refresh all models
4. Runs `dbt test` for data quality validation
5. Sends alerts on failure (configurable Slack/email)

---

## 📝 Business Logic Documentation

### Magic Numbers & Constants

**Service Classification** (`stg_tb_servicos.sql`):
- **AVA+** (Premium): Categories {7, 9} or Service IDs {47, 48, 49, 51, 52, 53}
- **AVB** (Secondary): Categories {1, 5, 10, 11, 12}
- **AVA** (Standard): All other categories

**Lead Status Mapping** (`fact_crm_leads.sql`):
- Entry Actions: 3=Contact Made, 9=Interested, 15=Qualified
- Exit Actions: 4=Lost, 8=Won, 22=Disputed

**Lead Matching Window** (`fact_vendas_bolsa.sql`):
- **75-day window**: Sales within 75 days of auction entry are matched
- Determined by BI team based on historical lead-to-sale patterns

**Branch Mapping** (`fact_vendas_bolsa.sql`):
- Branch 1 (central) transactions mapped to regional offices 85 or 54 when applicable

### Data Freshness SLA

- **Airbyte syncs**: Every 30 minutes
- **dbt transforms**: Follow Airbyte completion
- **Total latency**: ~35-40 minutes (end-to-end)

---

## 🔍 Troubleshooting

### Connection Issues

**dbt connection fails**:
```bash
dbt debug
# Check: DBT_HOST, DBT_USER, DBT_PASSWORD in .env
# Verify PostgreSQL is running: docker-compose ps
```

**Airflow can't reach dbt models**:
```bash
# Verify dbt project path in BashOperator
# Check: DAG log output in Airflow UI
```

### Data Issues

**Missing data in staging**:
1. Check Airbyte run logs: http://localhost:8000/workspace
2. Verify sync settings and destination schema
3. Confirm raw tables exist: `SELECT * FROM raw_producao.tb_processos LIMIT 1;`

**Test failures**:
```bash
dbt test --debug
# Review specific test failure message
# Check: are unique/not_null tests passing on source data?
```

### Performance Issues

**Slow dbt run**:
- Increase threads: Edit `profiles.yml` threads=8 (or higher)
- Run subset: `dbt run --select staging` (or specific models)
- Check PostgreSQL slow logs

**Large model materialization**:
- Consider incremental models for large fact tables
- Check: Are all models necessary or can some be views?

---

## 📚 Additional Resources

### Documentation

- **dbt Docs**: http://localhost:8001 (after `dbt docs serve`)
- **Airflow Docs**: http://localhost:8080
- **Data Lineage**: Available in dbt docs under "DAG" tab

### dbt Best Practices Used

✅ ref() for model dependencies
✅ Column-level testing (unique, not_null, relationships)
✅ Documentation via YAML schema files
✅ Staging → Marts layered architecture
✅ Meaningful naming (stg_, fact_, dim_)
✅ Config blocks for materialization

### Git Workflow

```bash
git status
git add prodDataBuilder/ dags/
git commit -m "Refactor: improve data quality tests and documentation"
git push origin main
```

---

## 🔐 Security Best Practices

✅ Credentials in `.env` (not in code)
✅ Environment variables in profiles.yml
✅ Airflow Connections for API credentials
✅ No hardcoded passwords in dbt models
✅ .gitignore includes .env, *.local

---

## 📈 Future Enhancements

- [ ] Implement incremental models for large fact tables
- [ ] Add SCD Type 2 snapshots for slowly changing dimensions
- [ ] Create dbt tests for data anomaly detection
- [ ] Set up CI/CD pipeline for model validation
- [ ] Implement data observability (Great Expectations)
- [ ] Add cost optimization monitoring

---

## 🤝 Support

For issues or questions:
1. Check dbt logs: `dbt run --debug`
2. Review test results: `dbt test`
3. Check Airflow DAG logs in UI

---

**Last Updated**: 2025-03-22
**Project Version**: 2.0 (with comprehensive documentation and testing)
