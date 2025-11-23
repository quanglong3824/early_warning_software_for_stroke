# Startup Scripts

## Quick Start

### Start Everything (API + Flutter App)
```bash
./start_app.sh
# or with specific device
./start_app.sh chrome
./start_app.sh macos
```

### Start API Only
```bash
./start_api.sh
```

### Start Flutter Only
```bash
./start_flutter.sh
# or with specific device
./start_flutter.sh chrome
```

## Available Scripts

### `start_app.sh` - Main Startup Script
Starts both Flask API and Flutter app together.

**Usage:**
```bash
./start_app.sh [device]
```

**Examples:**
```bash
./start_app.sh              # Default: web-server
./start_app.sh chrome       # Chrome browser
./start_app.sh macos        # macOS desktop
./start_app.sh edge         # Edge browser
```

**Features:**
- ✅ Starts Flask API on port 5001
- ✅ Waits for API to be ready
- ✅ Starts Flutter app on specified device
- ✅ Logs API output to `api.log`
- ✅ Graceful shutdown with Ctrl+C

### `start_api.sh` - API Only
Starts only the Flask API server.

**Usage:**
```bash
./start_api.sh
```

**Output:**
- Server runs on `http://localhost:5001`
- Logs shown in terminal

### `start_flutter.sh` - Flutter Only
Starts only the Flutter app.

**Usage:**
```bash
./start_flutter.sh [device]
```

**Examples:**
```bash
./start_flutter.sh web-server
./start_flutter.sh chrome
```

## Stopping Services

### Stop Everything
Press `Ctrl+C` in the terminal running `start_app.sh`

### Stop Individual Services
- API: Press `Ctrl+C` in API terminal
- Flutter: Press `q` in Flutter terminal or `Ctrl+C`

## Logs

### API Logs
When using `start_app.sh`, API logs are saved to:
```
api.log
```

View logs:
```bash
tail -f api.log
```

### Flutter Logs
Flutter logs appear in the terminal.

## Troubleshooting

### Port Already in Use
If port 5001 is in use:
```bash
# Find and kill process
lsof -ti:5001 | xargs kill -9

# Or change port in start_api.sh
PORT=5002 python3 app.py
```

### API Not Starting
Check dependencies:
```bash
cd assets/models
pip3 install -r requirements.txt
```

### Flutter Not Starting
Check Flutter setup:
```bash
flutter doctor
flutter pub get
```

## Development Workflow

### Recommended Workflow
1. **Start everything:**
   ```bash
   ./start_app.sh chrome
   ```

2. **Make changes** to code

3. **Hot reload** in Flutter:
   - Press `r` in Flutter terminal
   - Or save file (if hot reload enabled)

4. **Restart if needed:**
   - Press `R` for hot restart
   - Or `Ctrl+C` and run `./start_app.sh` again

### Testing API Changes
If you modify Flask API:
1. Stop services (`Ctrl+C`)
2. Restart: `./start_app.sh`

Or just restart API:
```bash
# Stop API (Ctrl+C)
./start_api.sh
```

## Production Deployment

For production, don't use these scripts. Instead:

### Deploy API
Use proper WSGI server:
```bash
gunicorn -w 4 -b 0.0.0.0:5001 app:app
```

### Deploy Flutter
Build and deploy:
```bash
flutter build web
# Deploy dist/ to hosting
```

## Tips

- Use `start_app.sh` for daily development
- Use separate scripts for debugging specific services
- Check `api.log` if API issues occur
- Use `flutter doctor` if Flutter issues occur
