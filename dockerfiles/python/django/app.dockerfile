# Use build argument to set Python version, default is 3.11.9-slim
ARG PYTHON_VERSION=3.11.9-slim

# Base image with configurable Python version
FROM python:${PYTHON_VERSION}

# Prevent Python from writing pyc files to save disk space
ENV PYTHONDONTWRITEBYTECODE 1
# Ensure Python outputs everything that's printed inside it without buffering
ENV PYTHONUNBUFFERED 1
# Ignore pipenv warnings about being root user
ENV PIP_ROOT_USER_ACTION ignore

# Update package lists and install supervisor and nginx without recommended packages to keep the image slim
RUN apt update && apt -y install supervisor --no-install-recommends \
    && apt update && apt -y install nginx --no-install-recommends

# Copy nginx configuration file to the appropriate directory
COPY ./the_dockman/config/nginx/app.conf /etc/nginx/sites-enabled/app.conf

# Copy supervisor configuration file to the appropriate directory
COPY ./the_dockman/config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create necessary directories for supervisor logs and runtime files
RUN mkdir -p /var/log/supervisord /var/run/supervisord

# Set the working directory for subsequent commands
WORKDIR /var/www/app

# Copy Pipfile and Pipfile.lock to the working directory
COPY Pipfile .
COPY Pipfile.lock .

# Install pipenv using Python's package manager
RUN python3 -m pip install pipenv

# Install Python dependencies defined in Pipfile.lock using pipenv
RUN pipenv install --ignore-pipfile

# Copy the entire application code to the working directory
COPY . .

# Expose port 8000 for the application
EXPOSE 8000

# Command to start supervisor with the specified configuration file, running in the foreground
CMD supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
