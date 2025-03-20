#!/bin/bash

# Legend Depot Seed Script
# This script populates the Legend Depot servers with sample projects and entities

# Configuration
STORE_SERVER_URL="http://localhost:6201"
DEPOT_SERVER_URL="http://localhost:6200"
DATA_DIR="$(dirname "$0")/data"

echo "Legend Depot Seed Script"
echo "========================"
echo "Using data from: $DATA_DIR"

# Function to register a project
register_project() {
  local projectId=$1
  local groupId=$2
  local artifactId=$3
  local latestVersion=$4
  
  echo "Registering project: $projectId ($groupId:$artifactId)"
  
  curl -X PUT "$STORE_SERVER_URL/depot-store/projects/$projectId/$groupId/$artifactId?latestVersion=$latestVersion" \
    -H "Content-Type: application/json" \
    -v
    
  echo -e "\n"
}

# Function to register a project version
register_project_version() {
  local groupId=$1
  local artifactId=$2
  local versionId=$3
  
  echo "Registering project version: $groupId:$artifactId:$versionId"
  
  curl -X PUT "$STORE_SERVER_URL/depot-store/projects/versions/$groupId/$artifactId/$versionId" \
    -H "Content-Type: application/json" \
    -d "{\"groupId\":\"$groupId\",\"artifactId\":\"$artifactId\",\"versionId\":\"$versionId\"}" \
    -v
    
  echo -e "\n"
}

# Function to upload entities for a project version
upload_entities() {
  local groupId=$1
  local artifactId=$2
  local versionId=$3
  local entities_file=$4
  
  echo "Uploading entities from $entities_file for $groupId:$artifactId:$versionId"
  
  if [ -f "$entities_file" ]; then
    # First, filter the JSON to match the right groupId, artifactId, and versionId
    TMP_FILE=$(mktemp)
    jq "[.[] | select(.groupId == \"$groupId\" and .artifactId == \"$artifactId\" and .versionId == \"$versionId\")]" \
      "$entities_file" > "$TMP_FILE"
    
    # Then upload the entities
    if [ -s "$TMP_FILE" ] && [ "$(cat $TMP_FILE)" != "[]" ]; then
      echo "Found matching entities to upload"
      curl -X POST "$STORE_SERVER_URL/depot-store/projects/versions/$groupId/$artifactId/$versionId/entities" \
        -H "Content-Type: application/json" \
        -d @"$TMP_FILE" \
        -v
    else
      echo "No matching entities found in $entities_file"
    fi
    
    rm "$TMP_FILE"
  else
    echo "Error: Entities file $entities_file not found"
  fi
  
  echo -e "\n"
}

# Wait for servers to be ready
echo "Waiting for Depot Store Server to be ready..."
until curl -s "$STORE_SERVER_URL/depot-store/api/info" > /dev/null; do
  echo "Depot Store Server not ready. Waiting..."
  sleep 2
done
echo "Depot Store Server is ready!"

# Register projects from projects.json
echo "Registering projects from projects.json..."
if [ -f "$DATA_DIR/projects.json" ]; then
  PROJECTS=$(jq -c '.[]' "$DATA_DIR/projects.json")
  
  for PROJECT in $PROJECTS; do
    projectId=$(echo $PROJECT | jq -r '.projectId')
    groupId=$(echo $PROJECT | jq -r '.groupId')
    artifactId=$(echo $PROJECT | jq -r '.artifactId')
    latestVersion=$(echo $PROJECT | jq -r '.latestVersion // "1.0.0"')
    
    register_project "$projectId" "$groupId" "$artifactId" "$latestVersion"
    
    # Register a version if latestVersion exists
    if [ "$latestVersion" != "null" ]; then
      register_project_version "$groupId" "$artifactId" "$latestVersion"
      
      # Upload entities for this version
      upload_entities "$groupId" "$artifactId" "$latestVersion" "$DATA_DIR/versioned-entities.json"
    fi
    
    # Also register master-SNAPSHOT version for each project
    register_project_version "$groupId" "$artifactId" "master-SNAPSHOT"
    upload_entities "$groupId" "$artifactId" "master-SNAPSHOT" "$DATA_DIR/revision-entities.json"
  done
else
  echo "Error: projects.json not found in $DATA_DIR"
fi

echo "Seed completed!"
