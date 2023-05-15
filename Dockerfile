# Use the official Python base image
FROM python:3.9.6-slim

# Set the working directory in the container
WORKDIR /app

# Copy the project files to the working directory
COPY . /app

# Install the project dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose the port that the Flask app will listen on
EXPOSE 5000

# Set the environment variable for Flask app
ENV FLASK_APP=hello

# Create a non-root user
RUN groupadd -r myuser && useradd -r -g myuser myuser

# Switch to the non-root user
USER myuser

# Set the entry point for the container
CMD ["flask", "run", "--host=0.0.0.0"]