from airflow.sdk import DAG
from airflow.providers.http.operators.http import HttpOperator
from airflow.providers.standard.sensors.python import PythonSensor
from airflow.providers.standard.operators.bash import BashOperator
from datetime import datetime, timedelta
from airflow.providers.standard.operators.python import PythonOperator
import requests
import json
from airflow.utils.task_group import TaskGroup

AIRBYTE_CONN_ID = "airbyte_http"
CONNECTION_IDS = [
    "0b67ce7b-ab7a-4e52-9447-1eae1eb388c1",
    "c1c4f031-72cc-4b3e-9033-9d29ddd22790",
    "9bb53dcf-67cf-49d7-b437-842df483cdeb"
]
AUTH = ("tism@somultas.com", "NJ9M071OH6JPvrRyG412QwnwOgmi24bL")


def check_airbyte_job(connection_id):
    url = "https://localhost:8080/api/v1/jobs/get_last_replication_job"
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    payload = {"connectionId": connection_id}
    response = requests.post(url, auth=AUTH, headers=headers, json=payload)
    response.raise_for_status()
    data = response.json()
    status = data["job"]["status"]
    print(f"[{connection_id}] Job status: {status}")

    if status == "succeeded":
        return True
    elif status in ["failed", "incomplete", "error"]:
        raise Exception(f"[{connection_id}] Airbyte job failed with status {status}")
    else:
        return False


with DAG(
        dag_id="airbyte_dbt_powerbi_pipeline",
        start_date=datetime(2025, 1, 1),
        schedule="*/30 * * * *",
        catchup=False,
        dagrun_timeout=timedelta(minutes=30),
        max_active_runs=1,
        tags=["airbyte", "dbt", "powerbi"],
    
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
    )


    previous_task >> dbt_run