FROM ros:humble

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY subscriber_node.py .

CMD ["python3", "subscriber_node.py"]