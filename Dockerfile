
# Use an official Python runtime as a parent image
FROM python:3.9-slim-buster

# Set the working directory in the container
WORKDIR /app

# Copy the new speed test script into the container at /app
COPY speed_test_limited.py .

# Install any needed packages specified in requirements.txt
# For this simple script, we only need 'requests'
RUN pip install requests

# Use ENTRYPOINT to ensure arguments are passed to the script
ENTRYPOINT ["python", "speed_test_limited.py"]

