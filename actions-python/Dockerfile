FROM tensorflow/tensorflow:latest-py3
# For GPU support use: tensorflow/tensorflow:latest-gpu-py3

# Install required packages for the server and face detection
RUN pip install --no-cache-dir \
    flask \
    gevent \
    numpy \
    pandas \
    scikit-learn \
    pillow \
    requests \
    matplotlib \
    seaborn \
    opencv-python \
    tensorflow-hub

# Copy the action server implementation
COPY actionproxy.py /actionproxy.py
RUN chmod 755 /actionproxy.py

# Set up working directory for actions
RUN mkdir -p /action
WORKDIR /action

# Copy function code
COPY face_detection_action.py /action/exec

# Set execution permissions
RUN chmod 755 /action/exec

# Expose the required port
EXPOSE 8080

# Start the action server
CMD ["python", "/actionproxy.py"]