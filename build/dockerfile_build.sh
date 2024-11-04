#!/bin/bash

# Define the build command
build_command=docker build -t ghcr.io/dheeman2912/spring-petclinic:1.1 .

# Run the Maven build and handle errors
echo "Building Docker image using Maven..."
if $build_command; then
    echo "Docker image build completed successfully."
else
    echo "Error: Docker image build failed"
    exit 1
fi
