FROM ros:humble-ros-base

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-ros2bag \
    ros-humble-rosbag2-storage-default-plugins \
    ros-humble-rosbag2-storage-mcap \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY record_bag.sh .
COPY convert_to_mcap.sh .
RUN chmod +x record_bag.sh convert_to_mcap.sh

CMD ["./record_bag.sh"]
