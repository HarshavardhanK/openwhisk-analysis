FROM openwhisk/python3action:latest

# Switch to root to install packages
USER root

# Install ML dependencies
RUN pip install --no-cache-dir \
    numpy \
    pillow \
    requests

# Copy function code
COPY action.py /action/exec

# Set execution permissions
RUN chmod 755 /action/exec

# Switch back to non-root user
USER 1001