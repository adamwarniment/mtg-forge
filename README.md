# Forge WebRTC Docker Setup

This project runs the Card-Forge/forge Java application in a web browser using Docker and noVNC.

## Quick Start

1. **Clone or download this repository**

2. **Copy the environment template:**
   ```bash
   cp .env.template .env
   ```

3. **Edit `.env` if needed** (optional - defaults work for most cases)

4. **Start the container:**
   ```bash
   docker-compose up -d
   ```

5. **Access Forge in your browser:**
   Open `http://localhost:8080` in your web browser

6. **Stop the container:**
   ```bash
   docker-compose down
   ```

## Data Persistence

All Forge data is saved to the `./data` directory:
- `./data/forge` - Game data, decks, settings
- `./data/cache` - Cache files

These directories are automatically created when you start the container. Your data will persist even if you remove and recreate the container.

## Configuration

Edit the `.env` file to customize:
- `TZ` - Timezone (default: America/New_York)
- `PUID` - User ID for file permissions (default: 1000)
- `PGID` - Group ID for file permissions (default: 1000)

## Building from Source

```bash
docker build -t ghcr.io/adamwarniment/forge-webrtc:latest .
```

## Troubleshooting

**Container won't start:**
- Check logs: `docker-compose logs -f`
- Ensure ports 8080 is not in use

**Can't connect to web interface:**
- Wait 10-15 seconds after starting for services to initialize
- Check that the container is running: `docker ps`

**Forge doesn't appear:**
- Check Forge logs: `docker-compose logs -f forge`
- The X server may need time to start

## Architecture

This setup uses:
- **Ubuntu 22.04** - Base OS
- **Java 17** - Required for Forge
- **Xvfb** - Virtual X server
- **Fluxbox** - Lightweight window manager
- **x11vnc** - VNC server
- **noVNC** - Web-based VNC client
- **Supervisor** - Process manager
