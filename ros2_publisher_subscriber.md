# ROS2 Publisher–Subscriber with Docker (Two Containers) — Windows

A guide to running a ROS2 talker/listener setup across two separate Docker containers on **Windows (Docker Desktop + WSL2)**.

> **Windows-specific note:** `network_mode: host` is **not supported** on Windows Docker Desktop. Instead, this guide uses a Docker **bridge network** with **CycloneDDS configured for unicast** peer discovery, which avoids the multicast limitations of Windows networking.

---

## Prerequisites

- [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/) with WSL2 backend enabled
- WSL2 installed and set as default (`wsl --set-default-version 2`)
- Docker Compose V2 (bundled with Docker Desktop)
- Basic familiarity with ROS2 concepts (nodes, topics)

---

## Project Structure

```
ros2_docker_pubsub/
├── docker-compose.yml
├── cyclone_dds.xml
├── publisher/
│   ├── Dockerfile
│   └── publisher_node.py
└── subscriber/
    ├── Dockerfile
    └── subscriber_node.py
```

---

## Step 1 — Write the Nodes

### `publisher/publisher_node.py`

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class PublisherNode(Node):
    def __init__(self):
        super().__init__('publisher_node')
        self.publisher_ = self.create_publisher(String, 'chatter', 10)
        self.timer = self.create_timer(1.0, self.publish_message)
        self.count = 0

    def publish_message(self):
        msg = String()
        msg.data = f'Hello ROS2: {self.count}'
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing: "{msg.data}"')
        self.count += 1

def main(args=None):
    rclpy.init(args=args)
    node = PublisherNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

### `subscriber/subscriber_node.py`

```python
import rclpy
from rclpy.node import Node
from std_msgs.msg import String

class SubscriberNode(Node):
    def __init__(self):
        super().__init__('subscriber_node')
        self.subscription = self.create_subscription(
            String, 'chatter', self.listener_callback, 10)

    def listener_callback(self, msg):
        self.get_logger().info(f'Received: "{msg.data}"')

def main(args=None):
    rclpy.init(args=args)
    node = SubscriberNode()
    rclpy.spin(node)
    node.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
```

---

## Step 2 — Configure CycloneDDS for Unicast

On Windows, Docker bridge networks do **not** support multicast, which is what ROS2's default DDS discovery relies on. The fix is to tell CycloneDDS to discover peers by IP address directly (unicast).

Create `cyclone_dds.xml` at the project root:

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
        <!-- Use Docker Compose service names as hostnames -->
        <Peer address="publisher"/>
        <Peer address="subscriber"/>
      </Peers>
    </Discovery>
  </Domain>
</CycloneDDS>
```

This file will be mounted into both containers so each knows where to find the other by service name.

---

## Step 3 — Write the Dockerfiles

Both containers use the official ROS2 Humble image with CycloneDDS installed.

### `publisher/Dockerfile`

```dockerfile
FROM ros:humble

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY publisher_node.py .

CMD ["python3", "publisher_node.py"]
```

### `subscriber/Dockerfile`

```dockerfile
FROM ros:humble

RUN apt-get update && apt-get install -y \
    ros-humble-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY subscriber_node.py .

CMD ["python3", "subscriber_node.py"]
```

---

## Step 4 — Set Up Docker Compose

Create `docker-compose.yml` at the project root:

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

networks:
  ros2_network:
    driver: bridge
```

Key environment variables explained:

| Variable | Purpose |
|---|---|
| `ROS_DOMAIN_ID` | Must match across all containers |
| `RMW_IMPLEMENTATION` | Switches ROS2 to use CycloneDDS instead of the default FastDDS |
| `CYCLONEDDS_URI` | Points CycloneDDS to the unicast config file |

---

## Step 5 — Build and Run

Open **PowerShell** or **Windows Terminal** and run from the project root:

```powershell
# Build both images
docker compose build

# Start both containers
docker compose up
```

You should see output like:

```
ros2_publisher   | [INFO] [publisher_node]: Publishing: "Hello ROS2: 0"
ros2_subscriber  | [INFO] [subscriber_node]: Received: "Hello ROS2: 0"
```

---

## Step 6 — Verify Communication

Open a second PowerShell window:

```powershell
# Check running containers
docker ps

# Follow publisher logs
docker logs -f ros2_publisher

# Follow subscriber logs
docker logs -f ros2_subscriber
```

To inspect the topic from inside a container:

```powershell
docker exec -it ros2_publisher bash
```

Then inside the container shell:

```bash
source /opt/ros/humble/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
ros2 topic list
ros2 topic echo /chatter
```

---

## Stopping the Setup

```powershell
docker compose down
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Subscriber receives nothing | Multicast blocked | Confirm `cyclone_dds.xml` is mounted and `CYCLONEDDS_URI` is set |
| `ros2` command not found | ROS not sourced | Run `source /opt/ros/humble/setup.bash` inside the container |
| DDS peer not found | Service name mismatch | Ensure `<Peer address>` values in `cyclone_dds.xml` match Compose service names exactly |
| `RMW_IMPLEMENTATION` error | CycloneDDS not installed | Confirm the `apt-get install ros-humble-rmw-cyclonedds-cpp` step ran in the Dockerfile |
| Containers can't reach each other | Wrong network | Confirm both services list `ros2_network` under `networks` in Compose |
| Docker Desktop WSL2 errors | WSL2 not default | Run `wsl --set-default-version 2` in PowerShell, then restart Docker Desktop |

---

## Why Not `network_mode: host`?

On Linux, `network_mode: host` lets containers share the host's network interface directly, making DDS multicast discovery trivially work. On Windows, Docker containers run inside a Linux VM (via WSL2), so `network_mode: host` maps to that VM's network — **not** your Windows host — and is effectively unsupported for inter-container communication. The CycloneDDS unicast approach in this guide is the correct and recommended solution for Windows.

---

## Notes

- **ROS distribution:** Replace `humble` with your target distro (`iron`, `jazzy`, etc.) in the Dockerfiles, `apt-get` commands, and `source` paths.
- **Docker Desktop resources:** If containers are slow to start, increase CPU/RAM allocated to Docker Desktop under *Settings → Resources*.
- **Production use:** For more complex setups, build a proper ROS2 package with `colcon` and install it inside the image rather than running bare Python scripts.
