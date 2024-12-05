# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install dependencies and tools
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    docker.io && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    apt-get clean && rm -rf /var/lib/apt/lists/* awscliv2.zip

# Verify installations
RUN aws --version
RUN docker --version

# Copy application files into the container
COPY requirements.txt .
COPY app.py .

# Install the Python dependencies specified in requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Expose port 80 for the Flask app
EXPOSE 80

# Define the command to run the application
CMD ["python", "app.py"]

# Comment for context
# Dockerfile updated to include AWS CLI and Docker for testing in CodeBuild
