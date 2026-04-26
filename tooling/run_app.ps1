# =========================
# ROS2 Multi-Terminal Runner (Named Windows)
# =========================

$projectPath = Get-Location

Write-Host "Launching ROS2 terminals..." -ForegroundColor Cyan

# -------------------------
# 1. Build images
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "$Host.UI.RawUI.WindowTitle='ROS2_Build'; cd '$projectPath'; docker compose build"
)

Start-Sleep -Seconds 3

# -------------------------
# 2. Start containers
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "$Host.UI.RawUI.WindowTitle='ROS2_Up'; cd '$projectPath'; docker compose up"
)

Start-Sleep -Seconds 3

# -------------------------
# 3. Docker PS
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "$Host.UI.RawUI.WindowTitle='ROS2_PS'; docker ps"
)

# -------------------------
# 4. Publisher logs
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "$Host.UI.RawUI.WindowTitle='ROS2_Publisher'; docker logs -f ros2_publisher"
)

# -------------------------
# 5. Subscriber logs
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "$Host.UI.RawUI.WindowTitle='ROS2_Subscriber'; docker logs -f ros2_subscriber"
)

# -------------------------
# 6. ROS2 interactive shell
# -------------------------
$rosCmd = @'
$Host.UI.RawUI.WindowTitle="ROS2_RosShell"
docker exec -it ros2_publisher bash
# Inside container:
# source /opt/ros/humble/setup.bash
# export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# ros2 topic list
# ros2 topic echo /chatter
'@

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    $rosCmd
)