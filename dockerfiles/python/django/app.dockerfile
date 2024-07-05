# Use build argument to set Python version, default is 3.11.9-slim
ARG PYTHON_VERSION=3.11.9-slim

# Base image with configurable Python version
FROM python:${PYTHON_VERSION}

# Prevent Python from writing pyc files
ENV PYTHONDONTWRITEBYTECODE 1
# Ensure Python outputs everything that's printed inside it
ENV PYTHONUNBUFFERED 1
# Ignore pipenv warnings about being root
ENV PIP_ROOT_USER_ACTION ignore

# Install supervisor and nginx using apt
RUN apt update && apt -y install supervisor --no-install-recommends \
    && apt update && apt -y install nginx --no-install-recommends

# Copy nginx configuration
COPY ./the_dockman/config/nginx/app.conf /etc/nginx/sites-enabled/app.conf

# Copy supervisor configuration
COPY ./the_dockman/config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create necessary directories for supervisor
RUN mkdir -p /var/log/supervisord /var/run/supervisord

# Set working directory for subsequent commands
WORKDIR /var/www/app

# Copy Pipfile.lock to the working directory
COPY Pipfile.lock /var/www/app/

# Install pipenv
RUN python3 -m pip install pipenv

# Install Python dependencies using pipenv
RUN pipenv install --ignore-pipfile

# Copy the entire application code to the working directory
COPY . .

# Expose port 8000
EXPOSE 8000

# Command to start supervisor with the specified configuration file
CMD supervisord -n -c /etc/supervisor/conf.d/supervisord.conf
