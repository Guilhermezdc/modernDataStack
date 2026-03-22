from airflow.sdk import DAG
from airflow.providers.http.operators.http import HttpOperator
from airflow.providers.standard.sensors.python import PythonSensor
from airflow.providers.standard.operators.bash import BashOperator
from datetime import datetime, timedelta
from airflow.providers.standard.operators.python import PythonOperator
from airflow.models import Variable
import requests
import json
from airflow.utils.task_group import TaskGroup
import logging

logger = logging.getLogger(__name__)

# Configuration from Airflow Variables (manage via UI or environment)
AIRBYTE_CONN_ID = "airbyte_http"
AIRBYTE_API_URL = Variable.get("AIRBYTE_API_URL", default_var="http://localhost:8000")
CONNECTION_IDS = Variable.get("AIRBYTE_CONNECTION_IDS", default_var=[
    "0b67ce7b-ab7a-4e52-9447-1eae1eb388c1",
    "c1c4f031-72cc-4b3e-9033-9d29ddd22790",
    "9bb53dcf-67cf-49d7-b437-842df483cdeb"
], deserialize_json=True)

# Note: Use Airflow Connection UI to configure Airbyte credentials securely
# See: http://localhost:8080/connection/list/


def check_airbyte_job(connection_id):
    """Check the status of an Airbyte replication job.

    Credentials are retrieved from the Airbyte Connection configured in Airflow UI.
    This avoids storing sensitive data in code or environment variables.
    """
    url = f"{AIRBYTE_API_URL}/api/v1/jobs/get_last_replication_job"
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    payload = {"connectionId": connection_id}

    try:
        # Use Airflow Connection for authentication (managed securely)
        from airflow.hooks.http import HttpHook
        http_hook = HttpHook(method="POST", http_conn_id=AIRBYTE_CONN_ID)
        response = http_hook.run(
            endpoint="api/v1/jobs/get_last_replication_job",
            json=payload,
            headers=headers
        )

        if isinstance(response, str):
            import json
            data = json.loads(response)
        else:
            data = response

        status = data["job"]["status"]
        logger.info(f"[{connection_id}] Job status: {status}")

        if status == "succeeded":
            return True
        elif status in ["failed", "incomplete", "error"]:
            raise Exception(f"[{connection_id}] Airbyte job failed with status {status}")
        else:
            return False
    except Exception as e:
        logger.error(f"[{connection_id}] Error checking job status: {str(e)}")
        raise


default_args = {
    'retries': 3,
    'retry_delay': timedelta(minutes=5),
    'owner': 'data-team',
}

with DAG(
        dag_id="airbyte_dbt_powerbi_pipeline",
        default_args=default_args,
        start_date=datetime(2025, 1, 1),
        schedule="*/30 * * * *",
        catchup=False,
        dagrun_timeout=timedelta(minutes=30),
        max_active_runs=1,
        tags=["airbyte", "dbt", "powerbi"],
        description="ETL pipeline: Airbyte sync → dbt run → dbt test",
) as dag:
    sync_tasks = []
    previous_task = None
    for cid in CONNECTION_IDS:
        with TaskGroup(group_id=f"airbyte_sync_{cid[:8]}") as tg:
            trigger = HttpOperator(
                task_id="trigger",
                http_conn_id=AIRBYTE_CONN_ID,
                endpoint="api/v1/connections/sync",
                method="POST",
                headers={"Content-Type": "application/json"},
                data=json.dumps({"connectionId": cid}),
                log_response=True,
            )

            wait = PythonSensor(
                task_id="wait_for_completion",
                python_callable=lambda connection_id=cid: check_airbyte_job(connection_id),
                poke_interval=30,
                timeout=60 * 30,
                mode="reschedule",
            )

            trigger >> wait

            if previous_task:
                previous_task >> tg
            previous_task = tg

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command="cd /opt/airflow/prodDataBuilder && dbt run",
        doc="Build all dbt models (staging and marts)",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/airflow/prodDataBuilder && dbt test",
        doc="Run all dbt data quality and schema tests",
    )

    previous_task >> dbt_run >> dbt_test