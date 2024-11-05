#!/bin/bash  
  
while getopts u:t:p:v: flag
do
  case "${flag}" in
    u) url=${OPTARG};;
    t) token=${OPTARG};;
    p) project=${OPTARG};;
    v) project_version=${OPTARG};;
    *) echo "Invalid option"; exit 1;;
  esac
done

SBOM_FILE="sbom.json"
# Fetch the list of projects  
existing_project=$(curl -s -H "X-Api-Key: $token" "$url/project" | jq -r --arg project "$project" --arg project_version "$project_version" '.[] | select(.name == $project and .version == $project_version)')  

# Check if a project with the same name and version exists  
if [ -n "$existing_project" ]; then  
  echo "Project '$project' with version '$project_version' already exists."  
  project_uuid=$(echo "$existing_project" | jq -r '.uuid')  
  echo "Project UUID: $project_uuid"  
else  
  # Create project payload  
  payload=$(jq -n --arg name "$project" --arg version "$project_version" '{name: $name, version: $version}')  
  # Create project  
  project_creation_response=$(curl -s -X PUT -H "Content-Type: application/json" -H "X-Api-Key: $token" -d "$payload" "$url/project")  
  
  # Check if the project was created successfully  
  if echo "$project_creation_response" | jq -e '.uuid' > /dev/null; then  
    echo "Project '$project' created successfully."  
    project_uuid=$(echo "$project_creation_response" | jq -r '.uuid')  
    echo "Project UUID: $project_uuid"  
  else  
    echo "Failed to create project. Response: $project_creation_response"  
    exit 1  
  fi  
fi  

# Upload SBOM
sbom_upload_response=$(curl -s -X POST -H "Content-Type: multipart/form-data" -H "X-Api-Key: $token" -F "projectName=$project" -F "projectVersion=$project_version" -F "bom=@$SBOM_FILE" "$url/bom")

# Check if the SBOM was uploaded successfully
if echo "$sbom_upload_response" | jq -e '.token' > /dev/null; then
  echo "SBOM uploaded successfully."
  upload_token=$(echo "$sbom_upload_response" | jq -r '.token')
  echo "Upload token: $upload_token"
else
  echo "Failed to upload SBOM. Response: $sbom_upload_response"
  exit 1
fi
