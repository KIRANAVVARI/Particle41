# Stage 1: Build stage (using a heavier image to install dependencies)
FROM python:3.11-slim as builder

# Install dependencies
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Final minimal runtime stage
FROM python:3.11-slim

# Create a non-root user and group
RUN groupadd -r appuser && useradd -r -g appuser appuser
# Set the user
USER appuser

WORKDIR /home/appuser/app
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY app.py .

# Expose the port the app is listening on
EXPOSE 8080

# Command to run the application
CMD ["python", "app.py"]