# MTG Forge - Docker Setup

This Docker setup runs MTG Forge in a VNC workspace accessible via web browser.

## Quick Start

### 1. Build the Docker Image
```bash
docker-compose build
```

### 2. Start the Container
```bash
docker-compose up -d
```

### 3. Access Forge

Wait about 30 seconds for services to initialize, then open your browser:

**Forge Web Interface**: http://localhost:8080

## Configuration

### Mobile vs Desktop Version

The startup script is configured to **prioritize the mobile version** of Forge:
- First looks for: `forge-gui-mobile-dev-*.jar`
- Then looks for: `forge-gui-mobile-*.jar`
- Falls back to desktop version if mobile not found

This allows you to use the mobile interface which may be better suited for web-based interaction.

## Data Persistence

Forge save data is mapped to the host machine:
- `./data/forge` - Forge save data (`~/.local/share/forge`)
- `./data/cache` - Forge cache (`~/.cache/forge`)

## Resource Requirements

- **RAM**: ~2GB
- **CPU**: 1+ cores recommended
- **Disk**: ~500MB for Forge installation + save data

## Monitoring

Check the status of all services:
```bash
docker exec forge-webrtc supervisorctl status
```

View Forge logs:
```bash
docker logs forge-webrtc
# or
docker exec forge-webrtc tail -f /var/log/supervisor/forge.log
```

## Troubleshooting

### Forge not loading
1. Check supervisor status: `docker exec forge-webrtc supervisorctl status`
2. All services should show `RUNNING`
3. Check Forge logs: `docker exec forge-webrtc tail -f /var/log/supervisor/forge.log`

### Port already in use
If port 8080 is already in use, modify `docker-compose.yml`:
```yaml
ports:
  - "8090:8080"  # Change 8090 to any available port
```

### Restart Forge
```bash
docker exec forge-webrtc supervisorctl restart forge
```

## Environment Variables

Create a `.env` file to customize settings:
```env
TZ=America/New_York
PUID=1000
PGID=1000
FORGE_VERSION=2.0.07
```

## Stopping the Container

```bash
docker-compose down
```

To remove all data:
```bash
docker-compose down -v
rm -rf ./data
```
