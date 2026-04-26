# Prerequisites Setup — Windows (ROS2 + Docker)

This guide walks you through setting up your Windows machine before running the ROS2 publisher–subscriber Docker project.

---

## Overview

You will need the following installed and configured:

1. WSL2 (Windows Subsystem for Linux)
2. Docker Desktop for Windows (with WSL2 backend)
3. A WSL2 Linux distro (Ubuntu 22.04 recommended)

---

## 1 — Enable WSL2

Open **PowerShell as Administrator** and run:

```powershell
wsl --install
```

This installs WSL2 and Ubuntu by default. After it finishes, **restart your machine**.

If WSL was already installed but on version 1, upgrade it:

```powershell
wsl --set-default-version 2
```

Verify WSL2 is active after reboot:

```powershell
wsl --list --verbose
```

You should see your distro listed with `VERSION 2`:

```
  NAME            STATE           VERSION
* Ubuntu          Running         2
```

> **Tip:** If you see version 1, convert the distro with:
> `wsl --set-version Ubuntu 2`

---

## 2 — Install Docker Desktop

1. Download Docker Desktop from [https://www.docker.com/products/docker-desktop/](https://www.docker.com/products/docker-desktop/)
2. Run the installer and make sure **"Use WSL2 instead of Hyper-V"** is checked during setup
3. After installation, **restart your machine**
4. Launch Docker Desktop and wait for it to finish starting (the whale icon in the system tray turns steady)

### Enable WSL2 Integration in Docker Desktop

Open Docker Desktop → **Settings → Resources → WSL Integration**

- Toggle **"Enable integration with my default WSL distro"** ON
- Also enable integration for your Ubuntu distro if listed separately

Click **Apply & Restart**.

### Verify Docker is Working

Open PowerShell or Windows Terminal:

```powershell
docker --version
docker compose version
```

Expected output (versions may differ):

```
Docker version 26.x.x, build ...
Docker Compose version v2.x.x
```

Run a quick smoke test:

```powershell
docker run hello-world
```

You should see a `Hello from Docker!` success message.

---

## 3 — Install Windows Terminal (Recommended)

Windows Terminal gives you tabs, better font rendering, and easy access to both PowerShell and WSL shells in one window.

Install it from the **Microsoft Store** by searching for **Windows Terminal**, or run:

```powershell
winget install --id Microsoft.WindowsTerminal -e
```

---

## 4 — Install Git for Windows (Optional but Recommended)

If you plan to clone or version-control the project:

```powershell
winget install --id Git.Git -e
```

Verify:

```powershell
git --version
```

---

## 5 — Verify Your Setup Checklist

Run these checks in PowerShell before starting the project:

```powershell
# WSL2 is installed and running
wsl --list --verbose

# Docker is installed
docker --version

# Docker Compose V2 is available
docker compose version

# Docker daemon is reachable
docker info
```

All four should return output without errors. If `docker info` hangs or errors, make sure Docker Desktop is running in the system tray.

---

## Common Issues

| Problem | Cause | Fix |
|---|---|---|
| `wsl` command not found | WSL not installed | Run `wsl --install` in an admin PowerShell |
| Docker Desktop won't start | Virtualization disabled in BIOS | Enable virtualization in BIOS/UEFI settings |
| `docker` command not found in WSL | Docker WSL integration off | Enable it in Docker Desktop → Settings → WSL Integration |
| Docker stuck on "Starting..." | WSL2 kernel outdated | Run `wsl --update` in PowerShell, then restart Docker Desktop |
| `docker compose` not recognized | Using old Compose V1 | Docker Desktop ships with Compose V2 — use `docker compose` (no hyphen) |

---

## You're Ready

Once all checks pass, head over to [README.md](./README.md) to build and run the ROS2 publisher–subscriber containers.
