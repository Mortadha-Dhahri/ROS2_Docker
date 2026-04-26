FROM ros:humble-ros-core

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-ros2bag \
    ros-humble-rosbag2-storage-default-plugins \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY record.sh .
RUN chmod +x record.sh

CMD ["./record.sh"]