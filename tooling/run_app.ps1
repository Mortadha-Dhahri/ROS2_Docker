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
    "`$Host.UI.RawUI.WindowTitle='ROS2_Build'; cd '$projectPath'; docker compose build"
)

Start-Sleep -Seconds 5

# -------------------------
# 2. Start containers
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`$Host.UI.RawUI.WindowTitle='ROS2_Up'; cd '$projectPath'; docker compose up"
)

Start-Sleep -Seconds 8

# -------------------------
# 3. Docker PS
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`$Host.UI.RawUI.WindowTitle='ROS2_PS'; docker ps"
)

# -------------------------
# 4. Publisher logs
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`$Host.UI.RawUI.WindowTitle='ROS2_Publisher'; docker logs -f ros2_publisher"
)

# -------------------------
# 5. Subscriber logs
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`$Host.UI.RawUI.WindowTitle='ROS2_Subscriber'; docker logs -f ros2_subscriber"
)

# -------------------------
# 6. Recorder logs
# -------------------------
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    "`$Host.UI.RawUI.WindowTitle='ROS2_Recorder'; docker logs -f ros2_recorder"
)

# -------------------------
# 7. Bag file watcher
#    Monitors ./bags and prints new files as they appear
# -------------------------
$bagWatchCmd = @"
`$Host.UI.RawUI.WindowTitle='ROS2_BagWatcher'
`$bagsPath = Join-Path '$projectPath' 'bags'
Write-Host 'Watching for bag files in: ' -NoNewline -ForegroundColor Cyan
Write-Host `$bagsPath -ForegroundColor Yellow
while (`$true) {
    if (Test-Path `$bagsPath) {
        `$sessions = Get-ChildItem -Path `$bagsPath -Directory | Sort-Object LastWriteTime -Descending
        if (`$sessions.Count -gt 0) {
            Write-Host \`"\`nActive bag sessions:`" -ForegroundColor Green
            foreach (`$session in `$sessions) {
                `$db3Files = Get-ChildItem -Path `$session.FullName -Filter '*.db3' -ErrorAction SilentlyContinue
                `$sizeMB = if (`$db3Files) { [math]::Round((`$db3Files | Measure-Object -Property Length -Sum).Sum / 1MB, 2) } else { 0 }
                Write-Host \`"  [`$(`$session.Name)]  `$sizeMB MB`" -ForegroundColor White
            }
        } else {
            Write-Host 'No bag sessions found yet. Waiting...' -ForegroundColor DarkGray
        }
    } else {
        Write-Host \`"'bags/' folder not found yet. Waiting for recorder to start...\`" -ForegroundColor DarkGray
    }
    Start-Sleep -Seconds 5
}
"@

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    $bagWatchCmd
)

# -------------------------
# 8. ROS2 interactive shell
# -------------------------
$rosCmd = @"
`$Host.UI.RawUI.WindowTitle='ROS2_Shell'
docker exec -it ros2_publisher bash
# Inside the container, run:
# source /opt/ros/humble/setup.bash
# export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# ros2 topic list
# ros2 topic echo /chatter
# ros2 bag info /bags/<session_folder>
# ros2 bag play /bags/<session_folder>
"@

Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-Command",
    $rosCmd
)

Write-Host ""
Write-Host "All terminals launched:" -ForegroundColor Green
Write-Host "  ROS2_Build      - docker compose build" -ForegroundColor White
Write-Host "  ROS2_Up         - docker compose up (all containers)" -ForegroundColor White
Write-Host "  ROS2_PS         - docker ps snapshot" -ForegroundColor White
Write-Host "  ROS2_Publisher  - publisher container logs" -ForegroundColor White
Write-Host "  ROS2_Subscriber - subscriber container logs" -ForegroundColor White
Write-Host "  ROS2_Recorder   - rosbag recorder container logs" -ForegroundColor White
Write-Host "  ROS2_BagWatcher - live bag file size monitor" -ForegroundColor White
Write-Host "  ROS2_Shell      - interactive shell into publisher container" -ForegroundColor White