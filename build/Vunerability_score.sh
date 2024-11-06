# #!/bin/bash  

# while getopts u:t:p:v:d: flag
# do
#   case "${flag}" in
#     u) url=${OPTARG};;
#     t) token=${OPTARG};;
#     p) project=${OPTARG};;
#     v) project_version=${OPTARG};;
#     d) influxdb_url=${OPTARG};;
#     *) echo "Invalid option"; exit 1;;
#   esac
# done

# # Get the current date in unix epoc timestamp format
# current_date=$(date +%s)

# # Fetch the list of projects and extract the UUID of the project with the specified name using jq  
# project_uuid=$(curl -s -H "X-Api-Key: $token" "$url/project" | jq -r --arg project "$project" --arg project_version "$project_version" '.[] | select(.name == $project and .version == $project_version) | .uuid')  
  
# # Check if the project UUID was found  
# if [ -z "$project_uuid" ]; then  
#   echo "Project '$project' with version '$project_version' not found."  
#   exit 1  
# fi  

# # Fetch vulnerabilities  
# vulnerabilities=$(curl -s -H "X-Api-Key: $token" "$url/vulnerability/project/$project_uuid")  
  
# # Clean the response and extract unique vulnerabilities  
# unique_vulns=$(echo "$vulnerabilities" | tr -d '\000-\037' | sed 's/\\u0000//g' | jq -r --arg date "$current_date" '.[] | .vulnId as $vulnId | .epssScore as $epssScore | .components[] | .project.name as $projectName | .project_version as $project_version | "\($date),\($projectName),\($project_version),\($vulnId),\(.name),\(.version),\($epssScore // 0.0000)"' | sort)  
  
# # Extract unique vulnId values  
# unique_vulnIds=$(echo "$vulnerabilities" | jq -r '.[].vulnId' | sort)
  
# # Fetch CISA data  
# cisa_data=$(curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json")  
  
# # Determine if each vulnId is in the CISA data  
# cisa_result=$(echo "$unique_vulnIds" | while read -r cveID; do  
#   if echo "$cisa_data" | jq -e ".vulnerabilities[] | select(.cveID == \"$cveID\")" > /dev/null; then  
#     echo "Exploited"  
#   else  
#     echo "Not Exploited"  
#   fi  
# done)  
  
# # Fetch CVSS scores  
# cvss_result=$(echo "$unique_vulnIds" | while read -r cve_id; do  
#   response=$(curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=${cve_id}")  
#   cleaned_response=$(echo "$response" | tr -d '\000-\037' | sed 's/\\u0000//g')  
#   base_score=$(echo "$cleaned_response" | jq -r '  
#     if .vulnerabilities[0].cve.metrics.cvssMetricV31 then  
#       .vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData.baseScore  
#     elif .vulnerabilities[0].cve.metrics.cvssMetricV30 then  
#       .vulnerabilities[0].cve.metrics.cvssMetricV30[0].cvssData.baseScore  
#     else  
#       "null"  
#     end')  
#   echo "$base_score"  
#   sleep 6  
# done)  

# # Combine all data into final CSV format  
# paste -d ',' <(echo "$unique_vulns") <(echo "$cvss_result") <(echo "$cisa_result") | {  
#   echo "timestamp,project,projectVersion,vulnId,packageName,packageVersion,epssScore,cvssScore,cisaScore"  
#   cat  
# } > $project-$current_date.csv  

# database="vulnerabilities"
# # Create the database (if not exists)  
# curl -i -XPOST "$influxdb_url/query" --data-urlencode "q=CREATE DATABASE $database"  
  
# # Read CSV file  
# while IFS=',' read -r timestamp project projectVersion vulnId packageName packageVersion epssScore cvssScore cisaScore; do   
#     # Skip the header row  
#     if [ "$timestamp" == "timestamp" ]; then  
#         continue  
#     fi
#     # Ensure string fields are properly quoted  
#     packageVersion="\"$packageVersion\""  
#     cisaScore="\"$cisaScore\""  
  
#     # Ensure the timestamp is in nanoseconds  
#     timestamp="${timestamp}000000000"  
  
#     # Construct the line protocol  
#     line_protocol="$project,project=$project,projectVersion=$project_version,vulnId=$vulnId,packageName=$packageName packageVersion=$packageVersion,epssScore=$epssScore,cvssScore=$cvssScore,cisaScore=$cisaScore $timestamp" 
#     # Write data to InfluxDB  
#     curl -i -XPOST "$influxdb_url/write?db=$database" --data-binary "$line_protocol"  
  
# done < "$project-$current_date.csv" 


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


#!/bin/bash  

while getopts u:t:p:v:d: flag
do
  case "${flag}" in
    u) url=${OPTARG};;
    t) token=${OPTARG};;
    p) project=${OPTARG};;
    v) project_version=${OPTARG};;
    d) influxdb_url=${OPTARG};;
    *) echo "Invalid option"; exit 1;;
  esac
done

# Get the current date in unix epoc timestamp format
current_date=$(date +%s)

# Fetch the list of projects and extract the UUID of the project with the specified name using jq  
project_uuid=$(curl -s -H "X-Api-Key: $token" "$url/project" | jq -r --arg project "$project" --arg project_version "$project_version" '.[] | select(.name == $project and .version == $project_version) | .uuid')  
  
# Check if the project UUID was found  
if [ -z "$project_uuid" ]; then  
  echo "Project '$project' with version '$project_version' not found."  
  exit 1  
fi  

# Fetch vulnerabilities  
vulnerabilities=$(curl -s -H "X-Api-Key: $token" "$url/vulnerability/project/$project_uuid")  
  
# Clean the response and extract unique vulnerabilities  
unique_vulns=$(echo "$vulnerabilities" | tr -d '\000-\037' | sed 's/\\u0000//g' | jq -r --arg date "$current_date" '.[] | .vulnId as $vulnId | .epssScore as $epssScore | .components[] | .project.name as $projectName | .project.version as $project_version | "\($date),\($projectName),\($project_version),\($vulnId),\(.name),\(.version),\($epssScore // 0.0000)"' | sort)  
# Extract unique vulnId values  
unique_vulnIds=$(echo "$vulnerabilities" | jq -r '.[].vulnId' | sort)
# Fetch CISA data  
cisa_data=$(curl -s "https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json")  
  
# Determine if each vulnId is in the CISA data  
cisa_result=$(echo "$unique_vulnIds" | while read -r cveID; do  
  if echo "$cisa_data" | jq -e ".vulnerabilities[] | select(.cveID == \"$cveID\")" > /dev/null; then  
    echo "Exploited"  
  else  
    echo "Not Exploited"  
  fi  
done)  
  
# Fetch CVSS scores  
cvss_result=$(echo "$unique_vulnIds" | while read -r cve_id; do  
  response=$(curl -s "https://services.nvd.nist.gov/rest/json/cves/2.0?cveId=${cve_id}")  
  cleaned_response=$(echo "$response" | tr -d '\000-\037' | sed 's/\\u0000//g')  
  base_score=$(echo "$cleaned_response" | jq -r '  
    if .vulnerabilities[0].cve.metrics.cvssMetricV31 then  
      .vulnerabilities[0].cve.metrics.cvssMetricV31[0].cvssData.baseScore  
    elif .vulnerabilities[0].cve.metrics.cvssMetricV30 then  
      .vulnerabilities[0].cve.metrics.cvssMetricV30[0].cvssData.baseScore 
    elif .vulnerabilities[0].cve.metrics.cvssMetricV2 then
      .vulnerabilities[0].cve.metrics.cvssMetricV2[0].cvssData.baseScore 
    else  
      "null"  
    end')  
  echo "$base_score"  
  sleep 6  
done)  

# Combine all data into final CSV format  
paste -d ',' <(echo "$unique_vulns") <(echo "$cvss_result") <(echo "$cisa_result") | {  
  echo "timestamp,project,projectVersion,vulnId,packageName,packageVersion,epssScore,cvssScore,cisaScore"  
  cat  
} > $project-$current_date.csv  

database="vulnerabilities"
# Create the database (if not exists)  
curl -i -XPOST "$influxdb_url/query" --data-urlencode "q=CREATE DATABASE $database"  
curl -i -XPOST "$influxdb_url/query" --data-urlencode "db=$database" --data-urlencode "q=DROP MEASUREMENT $project"
# Read CSV file  
while IFS=',' read -r timestamp project projectVersion vulnId packageName packageVersion epssScore cvssScore cisaScore; do   
    # Skip the header row  
    if [ "$timestamp" == "timestamp" ]; then  
        continue  
    fi
    # Ensure string fields are properly quoted  
    packageVersion="\"$packageVersion\""  
    cisaScore="\"$cisaScore\""
    cvssScore="\"$cvssScore\"" 
  
    # Ensure the timestamp is in nanoseconds  
    timestamp="${timestamp}000000000"  
  
    # Construct the line protocol  
    line_protocol="$project,project=$project,projectVersion=$project_version,vulnId=$vulnId,packageName=$packageName packageVersion=$packageVersion,epssScore=$epssScore,cvssScore=$cvssScore,cisaScore=$cisaScore $timestamp" 
    # Write data to InfluxDB 

    curl -i -XPOST "$influxdb_url/write?db=$database" --data-binary "$line_protocol"  
  
done < "$project-$current_date.csv" 


