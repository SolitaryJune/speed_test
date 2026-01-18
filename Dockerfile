# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Disable Python output buffering to ensure logs are printed in real-time
ENV PYTHONUNBUFFERED=1

# Copy the speed test script into the container at /app
COPY speed_test_limited.py .

# Install requests library
RUN pip install --no-cache-dir requests

# Use ENTRYPOINT to ensure arguments are passed to the script
ENTRYPOINT ["python", "speed_test_limited.py"]
