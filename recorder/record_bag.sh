#!/bin/bash
set -e

source /opt/ros/humble/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

echo "[recorder] Waiting for nodes to be available..."
sleep 5

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BAG_PATH="/bags/session_${TIMESTAMP}"

echo "[recorder] Starting rosbag recording to ${BAG_PATH}"
ros2 bag record -a -o "${BAG_PATH}"