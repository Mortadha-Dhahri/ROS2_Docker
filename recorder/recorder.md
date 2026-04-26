# Rosbag Auto-Recorder — Automatic Topic Monitoring

This guide adds a third Docker container to the existing publisher–subscriber setup. It automatically discovers and records **all active ROS2 topics** into a rosbag file without needing to specify topic names manually.

---

## How It Works

A dedicated `recorder` container runs `ros2 bag record -a`, which subscribes to every topic it discovers on the DDS network and writes them to a `.db3` bag file. Because it shares the same `ros2_network` and CycloneDDS unicast config as the other two containers, it participates in discovery automatically.

---

## Updated Project Structure

```
ros2_docker_pubsub/
├── docker-compose.yml        ← updated
├── cyclone_dds.xml           ← updated (add recorder peer)
├── publisher/
│   ├── Dockerfile
│   └── publisher_node.py
├── subscriber/
│   ├── Dockerfile
│   └── subscriber_node.py
└── recorder/
    ├── Dockerfile
    └── record.sh
```

---

## Step 1 — Update `cyclone_dds.xml`

Add the `recorder` service as a peer so DDS discovery includes it:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<CycloneDDS xmlns="https://cdds.io/config"
            xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="https://cdds.io/config https://raw.githubusercontent.com/eclipse-cyclonedds/cyclonedds/master/etc/cyclonedds.xsd">
  <Domain id="any">
    <Discovery>
      <ParticipantIndex>auto</ParticipantIndex>
      <MaxAutoParticipantIndex>30</MaxAutoParticipantIndex>
      <Peers>
        <Peer address="publisher"/>
        <Peer address="subscriber"/>
        <Peer address="recorder"/>
      </Peers>
    </Discovery>
  </Domain>
</CycloneDDS>
```

---

## Step 2 — Create the Recorder Files

### `recorder/record.sh`

This script waits briefly for the other nodes to come up, then starts recording all topics:

```bash
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
```

- The `sleep 5` gives the publisher and subscriber time to initialize before recording starts.
- Each session gets a timestamped folder name so bags don't overwrite each other.
- `-a` records every topic currently active on the network.

### `recorder/Dockerfile`

```dockerfile
FROM ros:humble

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-ros2bag \
    ros-humble-rosbag2-storage-default-plugins \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY record.sh .
RUN chmod +x record.sh

CMD ["./record.sh"]
```

---

## Step 3 — Update `docker-compose.yml`

Add the `recorder` service and a shared named volume for bag output:

```yaml
version: '3.8'

services:
  publisher:
    build: ./publisher
    container_name: ros2_publisher
    environment:
      - ROS_DOMAIN_ID=0
      - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
      - CYCLONEDDS_URI=/config/cyclone_dds.xml
    volumes:
      - ./cyclone_dds.xml:/config/cyclone_dds.xml:ro
    networks:
      - ros2_network

  subscriber:
    build: ./subscriber
    container_name: ros2_subscriber
    environment:
      - ROS_DOMAIN_ID=0
      - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
      - CYCLONEDDS_URI=/config/cyclone_dds.xml
    volumes:
      - ./cyclone_dds.xml:/config/cyclone_dds.xml:ro
    networks:
      - ros2_network
    depends_on:
      - publisher

  recorder:
    build: ./recorder
    container_name: ros2_recorder
    environment:
      - ROS_DOMAIN_ID=0
      - RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
      - CYCLONEDDS_URI=/config/cyclone_dds.xml
    volumes:
      - ./cyclone_dds.xml:/config/cyclone_dds.xml:ro
      - ./bags:/bags                          # bag files land here on your Windows host
    networks:
      - ros2_network
    depends_on:
      - publisher

networks:
  ros2_network:
    driver: bridge
```

The `./bags` folder will be created automatically by Docker on first run, and bag files will appear there on your Windows host under the project root.

---

## Step 4 — Build and Run

```powershell
docker compose build
docker compose up
```

After ~5 seconds you should see:

```
ros2_recorder  | [recorder] Waiting for nodes to be available...
ros2_recorder  | [recorder] Starting rosbag recording to /bags/session_20240426_123045
ros2_recorder  | [INFO] [rosbag2_recorder]: Listening for topics...
ros2_recorder  | [INFO] [rosbag2_recorder]: Subscribed to topic '/chatter'
```

---

## Step 5 — Access the Bag Files

Bags are written to a `bags/` folder in your project root on the Windows host:

```
ros2_docker_pubsub/
└── bags/
    └── session_20240426_123045/
        ├── session_20240426_123045_0.db3
        └── metadata.yaml
```

Open them in PowerShell via the recorder container:

```powershell
docker exec -it ros2_recorder bash
```

Then inside the container:

```bash
source /opt/ros/humble/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# List bag contents
ros2 bag info /bags/session_20240426_123045

# Play the bag back
ros2 bag play /bags/session_20240426_123045
```

---

## Step 6 — Stop Recording Gracefully

Press `Ctrl+C` in the terminal running `docker compose up`, or in a separate window:

```powershell
docker compose down
```

CycloneDDS flushes the bag on shutdown, so the `.db3` file will be complete and readable.

---

## Customising What Gets Recorded

The default `-a` flag records everything. You can restrict recording to specific topics by editing `record.sh`:

```bash
# Record only specific topics
ros2 bag record -o "${BAG_PATH}" /chatter /another_topic

# Record all topics except some (requires rosbag2 Humble+)
ros2 bag record -a --exclude "/topic_to_skip" -o "${BAG_PATH}"

# Split bag files every 100 MB to avoid huge single files
ros2 bag record -a --max-bag-size 104857600 -o "${BAG_PATH}"

# Split bag files every 60 seconds
ros2 bag record -a --max-bag-duration 60 -o "${BAG_PATH}"
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Recorder logs no topics found | DDS discovery too slow | Increase `sleep` in `record.sh` from 5 to 10 seconds |
| `recorder` peer not in `cyclone_dds.xml` | Forgot to add it | Add `<Peer address="recorder"/>` to the xml file |
| `bags/` folder is empty | Container crashed before writing | Check `docker logs ros2_recorder` for errors |
| Bag file is unreadable / corrupt | Container killed mid-write | Always stop with `docker compose down`, not by force-killing |
| `ros2 bag` command not found | Packages not installed | Confirm `ros-humble-ros2bag` and `ros-humble-rosbag2-storage-default-plugins` are in the Dockerfile |
| Permission denied on `bags/` | Windows volume mount issue | Run PowerShell as Administrator, or move the project to your WSL2 home directory |

---

## Notes

- **Storage format:** By default ROS2 Humble uses SQLite3 (`.db3`). If you need better write performance for high-frequency topics, install `ros-humble-rosbag2-storage-mcap` and add `--storage mcap` to the record command.
- **Disk space:** Recording all topics with `-a` can fill disk quickly on high-bandwidth setups. Use `--max-bag-size` or `--max-bag-duration` to split files and monitor the `bags/` folder size.
- **Playback:** When playing back, make sure the subscriber (or any listener) is running and on the same `ROS_DOMAIN_ID`.