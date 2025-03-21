FROM python:3.8-slim

# Install system dependencies for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    && rm -rf /var/lib/apt/lists/*

# Install required packages for the server
RUN pip install --no-cache-dir \
    flask \
    gevent \
    numpy \
    opencv-python-headless \
    pillow \
    requests \
    tensorflow-hub \
    tensorflow-cpu==2.9.0

# Copy the action server implementation
COPY actionproxy.py /actionproxy.py

# Set up working directory for actions
RUN mkdir -p /action
WORKDIR /action

# Expose the required port
EXPOSE 8080

# Start the action server
CMD ["python", "/actionproxy.py"]