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
# configure your own detectors
curl -s -u ${USERNAME}:${PASSWORD} -X PUT -H 'Content-Type: application/json' ${JOBS}/${JOB_ID}?pretty -d '{
    "description" : "Anomalies in Apache access logs.",
    "analysis_config" : {
        "bucket_span":"5m",
        "detectors": [
    		{
		      "detector_description": "",
		      "function": "",
		      "field_name": "",
		      "partition_field_name": "geoip.country_name",
		      "detector_rules": [
		        
		      ]
		    }
		  ],
	"influencers": [ "geoip.ip", "geoip.country_name", "geoip.city_name.raw", "geoip.continent_code" ]
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
        "logs", "_default_"
      ]
}'

printf "\n\n== Opening job for ${JOB_ID}... "
curl -u ${USERNAME}:${PASSWORD} -X POST ${JOBS}/${JOB_ID}/_open

printf "\n\n== Starting datafeed-${JOB_ID}... "
curl -u ${USERNAME}:${PASSWORD} -X POST "${DATAFEEDS}/datafeed-${JOB_ID}/_start?start=YYYY-MM-DDThh:mm:ssZ&end=YYYY-MM-DDThh:mm:ssZ"

sleep 20s

printf "\n\n== Finished creating a multi-metric job for Apache access logs. :) ==\n\n"