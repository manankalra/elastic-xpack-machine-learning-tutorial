HOST='localhost'
PORT=9200
JOB_ID='<job-id>'
INDEX_NAME='<index-name>'
ROOT="http://${HOST}:${PORT}/_xpack/ml"
JOBS="${ROOT}/anomaly_detectors"
DATAFEEDS="${ROOT}/datafeeds"
USERNAME=<username>
PASSWORD=<password>
printf "\n== Script started for... $JOBS/$JOB_ID"

printf "\n\n== Stopping datafeed... "
curl -s -u ${USERNAME}:${PASSWORD} -X POST ${DATAFEEDS}/datafeed-${JOB_ID}/_stop

printf "\n\n== Deleting datafeed... "
curl -s -u ${USERNAME}:${PASSWORD} -X DELETE ${DATAFEEDS}/datafeed-${JOB_ID}

printf "\n\n== Closing job... "
curl -s -u ${USERNAME}:${PASSWORD} -X POST ${JOBS}/${JOB_ID}/_close

printf "\n\n== Deleting job... "
curl -s -u ${USERNAME}:${PASSWORD} -X DELETE ${JOBS}/${JOB_ID}

printf "\n\n== Creating job... \n"
curl -s -u ${USERNAME}:${PASSWORD} -X PUT -H 'Content-Type: application/json' ${JOBS}/${JOB_ID}?pretty -d '{
    "description" : "Anomalies in CPU, Memory and Disk usage.",
    "analysis_config" : {
        "bucket_span":"1m",
        "detectors" :[
          {
            "detector_description": "CPU detector",
            "function": "high_mean",
            "field_name": "system.cpu.user.pct"
          },
          {
            "detector_description": "Memory detector",
            "function": "high_mean",
            "field_name": "system.memory.actual.used.pct"
          },
	        {
            "detector_description": "Disk detector",
            "function": "high_mean",
            "field_name": "system.filesystem.used.pct"
          }		
        ],
        "influencers": ["metricset.name", "beat.hostname"]
        },
        "data_description" : {
          "time_field":"@timestamp",
	  "time_format": "epoch_ms"
    }
}'

printf "\n\n== Creating Datafeed... \n"
curl -s -u ${USERNAME}:${PASSWORD} -X PUT -H 'Content-Type: application/json' ${DATAFEEDS}/datafeed-${JOB_ID}?pretty -d '{
      "job_id" : "'"$JOB_ID"'",
      "query_delay": "60s", 
      "frequency": "60s",
      "indexes" : [
        "'"$INDEX_NAME"'"
      ],
      "types" : [
        "metricsets", "_default_"
      ]
}'

printf "\n\n== Opening job for ${JOB_ID}... "
curl -u ${USERNAME}:${PASSWORD} -X POST ${JOBS}/${JOB_ID}/_open

printf "\n\n== Starting datafeed-${JOB_ID}... "
curl -u ${USERNAME}:${PASSWORD} -X POST "${DATAFEEDS}/datafeed-${JOB_ID}/_start?start=YYYY-MM-DDThh:mm:ssZ"

sleep 20s

printf "\n\n== Finished creating a multi-metric job for CPU, Memory and Disk usage. :) ==\n\n"