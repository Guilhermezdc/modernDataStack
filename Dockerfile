# Imagem base do Airflow
FROM apache/airflow:3.0.6

# Variáveis de ambiente
ENV PYTHONUNBUFFERED=1 \
    AIRFLOW_HOME=/opt/airflow

# Usuário root para instalar pacotes e criar pastas
USER root

# Atualizar apt e instalar vim
RUN apt-get update \
  && apt-get install -y --no-install-recommends vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Criar pasta de logs se não existir
RUN mkdir -p /logs \
  && chown -R airflow: "${AIRFLOW_HOME}" /logs

# Voltar para usuário airflow para instalar pacotes Python
USER airflow

# Instalar Airflow, providers e requests
RUN pip install --no-cache-dir \
    "apache-airflow==${AIRFLOW_VERSION}" \
    lxml \
    "apache-airflow-providers-airbyte==5.2.3" \
    "apache-airflow-providers-http==5.3.3" \
    "apache-airflow-providers-microsoft-azure==12.6.1" \
    "requests==2.32.5"

# Instalar dbt com versões específicas
RUN pip install --no-cache-dir \
    "dbt-core==1.10.11" \
    "dbt-postgres==1.9.1"

# Definir diretório de trabalho
WORKDIR /opt/airflow
