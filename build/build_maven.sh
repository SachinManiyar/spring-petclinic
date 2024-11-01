#!/bin/bash

# Redirect all output (stdout and stderr) to build.log
exec &> build.log

echo "Starting Maven build..."
mvn clean package -DskipTests
if [ $? -ne 0 ]; then
   echo "Error: Maven build failed"
   exit 1
fi

# Use the build ID as part of the artifact name
BUILD_ID=${GITHUB_RUN_ID:-local_build}  
ARTIFACT_NAME="app-${BUILD_ID}.jar"

mv target/*.jar "$ARTIFACT_NAME"
if [ $? -ne 0 ]; then
   echo "Error: Failed to copy JAR file to $ARTIFACT_NAME"
   exit 1
fi

echo "Maven build completed successfully and $ARTIFACT_NAME created."
