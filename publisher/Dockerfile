FROM ros:humble-ros-core

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY publisher_node.py .

CMD ["python3", "publisher_node.py"]