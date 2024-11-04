#!/bin/bash

# Define the build command
build_command=docker build -t ghcr.io/${{ secrets.IMAGE_NAME }}:${{ secrets.IMAGE_VERSION}} .

# Run the Maven build and handle errors
echo "Building Docker image using Maven..."
if eval $build_command; then
    echo "Docker image build completed successfully."
else
    echo "Error: Docker image build failed."
    exit 1
fi
