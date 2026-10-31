# Stage 1: Build dependencies in an isolated builder environment
FROM python:3.12-slim AS builder

# Set the working directory for dependency installation
WORKDIR /app

# Prevent Python from writing bytecode files and enable unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create a virtual environment for dependency isolation
RUN python -m venv /opt/venv

# Add virtual environment binaries to PATH
ENV PATH="/opt/venv/bin:$PATH"

# Copy service dependencies first to leverage Docker layer caching
COPY services/quiz-api/requirements.txt .

# Install dependencies into the virtual environment without caching wheels
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Final runtime environment
FROM python:3.12-slim

# Set the working directory for the application
WORKDIR /app

# Set Python environment variables and prioritize the virtual environment
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# Create a dedicated non-root user and group with fixed UID/GID for security
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /bin/sh -m appuser

# Copy installed virtual environment from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy application source code into the container
COPY services/quiz-api /app

# Grant application ownership to the non-root user
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Expose port 8000 for the FastAPI service
EXPOSE 8000

# Configure health check hitting the /health endpoint every 30 seconds
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health')"

# Run the FastAPI application using uvicorn on port 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
