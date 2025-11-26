# Backend Configuration Guide

This guide explains how to configure the Flutter app to connect to your backend server in different environments.

## Configuration File

All backend URL configuration is centralized in:
```
lib/config/app_config.dart
```

## Environment Options

The app supports four backend environments:

### 1. Local Network (Default)
**Use when:** Testing on physical device or emulator on same WiFi network

```dart
static BackendEnvironment current = BackendEnvironment.local;
```

**Configuration:**
1. Find your computer's local IP address:
   ```powershell
   # Windows
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.20)
   ```

2. Update the local URL in `app_config.dart`:
   ```dart
   case BackendEnvironment.local:
     return 'http://YOUR_LOCAL_IP:3000'; // Replace with your IP
   ```

3. Ensure backend server is running:
   ```bash
   cd backend
   npm run dev
   ```

**Requirements:**
- Backend and mobile device on same WiFi network
- Firewall allows port 3000
- Cannot use `localhost` or `127.0.0.1` (won't work on physical devices)

---

### 2. Ngrok Tunnel
**Use when:** Testing from external network or sharing with team

```dart
static BackendEnvironment current = BackendEnvironment.ngrok;
```

**Setup:**

1. Install ngrok globally:
   ```bash
   npm install -g ngrok
   ```

2. Start your backend server:
   ```bash
   cd backend
   npm run dev
   ```

3. In a new terminal, start ngrok:
   ```bash
   ngrok http 3000
   ```

4. Copy the HTTPS forwarding URL (e.g., `https://abc123.ngrok-free.app`)

5. Update `app_config.dart`:
   ```dart
   case BackendEnvironment.ngrok:
     return 'https://abc123.ngrok-free.app'; // Your ngrok URL
   ```

6. Change environment:
   ```dart
   static BackendEnvironment current = BackendEnvironment.ngrok;
   ```

**Advantages:**
- Works from any network (no WiFi requirement)
- Shareable URL for team testing
- HTTPS support (required for some APIs)

**Limitations:**
- Free tier has connection limits
- URL changes each time you restart ngrok (unless using paid plan)
- Adds latency

---

### 3. Production
**Use when:** Connecting to deployed production backend

```dart
static BackendEnvironment current = BackendEnvironment.production;
```

**Configuration:**

1. Deploy backend to a cloud platform:
   - **Vercel:** `vercel deploy`
   - **Railway:** Connect GitHub repo
   - **Heroku:** `heroku deploy`
   - **AWS/Azure:** Follow platform docs

2. Get your production URL (e.g., `https://pharmacy-api.vercel.app`)

3. Update `app_config.dart`:
   ```dart
   case BackendEnvironment.production:
     return 'https://pharmacy-api.vercel.app'; // Your production URL
   ```

4. Change environment:
   ```dart
   static BackendEnvironment current = BackendEnvironment.production;
   ```

**Best Practices:**
- Use environment variables for production URLs
- Enable HTTPS (most platforms provide this automatically)
- Set up proper authentication and rate limiting
- Monitor API usage and errors

---

### 4. Custom
**Use when:** Temporarily testing different backend URLs

```dart
static BackendEnvironment current = BackendEnvironment.custom;
```

**Configuration:**

```dart
case BackendEnvironment.custom:
  return 'http://10.0.2.2:3000'; // Example: Android emulator localhost
  // Other examples:
  // return 'http://192.168.1.100:3000'; // Different local IP
  // return 'https://staging-api.example.com'; // Staging server
```

**Common Use Cases:**

- **Android Emulator:** Use `http://10.0.2.2:3000` (special IP that maps to host's localhost)
- **iOS Simulator:** Use `http://localhost:3000` (simulator shares host's network)
- **Staging Environment:** Use your staging server URL
- **Team Member's Backend:** Use their local IP or ngrok URL

---

## Configuration Examples

### Development on Physical Device
```dart
class AppConfig {
  static BackendEnvironment current = BackendEnvironment.local;

  static String get backendBaseUrl {
    switch (current) {
      case BackendEnvironment.local:
        return 'http://192.168.1.20:3000'; // ← Your computer's IP
      // ... other cases
    }
  }
}
```

### Testing with Ngrok
```dart
class AppConfig {
  static BackendEnvironment current = BackendEnvironment.ngrok;

  static String get backendBaseUrl {
    switch (current) {
      case BackendEnvironment.ngrok:
        return 'https://abc123.ngrok-free.app'; // ← Your ngrok URL
      // ... other cases
    }
  }
}
```

### Production Release
```dart
class AppConfig {
  static BackendEnvironment current = BackendEnvironment.production;

  static String get backendBaseUrl {
    switch (current) {
      case BackendEnvironment.production:
        return 'https://pharmacy-api.vercel.app'; // ← Your production URL
      // ... other cases
    }
  }
}
```

---

## Advanced Configuration

### Dynamic Environment Selection

For advanced users, you can allow environment switching at runtime:

```dart
// Add to AppConfig
static void setEnvironment(BackendEnvironment env) {
  current = env;
  // Optionally save to SharedPreferences for persistence
}

static Future<void> loadEnvironment() async {
  final prefs = await SharedPreferences.getInstance();
  final envString = prefs.getString('backend_environment') ?? 'local';
  current = BackendEnvironment.values.firstWhere(
    (e) => e.name == envString,
    orElse: () => BackendEnvironment.local,
  );
}
```

Then add a settings screen to switch environments without rebuilding.

### Timeout Configuration

Adjust network timeout for slow connections:

```dart
static const Duration defaultTimeout = Duration(seconds: 10);

// In your HTTP calls:
final response = await http.get(
  Uri.parse('$backendBaseUrl/api/products'),
).timeout(AppConfig.defaultTimeout);
```

Increase to `Duration(seconds: 30)` if you have slow network or large responses.

### Retry Configuration

Adjust retry behavior in `products_screen.dart`:

```dart
static const int maxRetries = 3; // Number of retry attempts
static const List<int> retryDelays = [2, 4, 6]; // Delays in seconds
```

For slower networks, increase delays:
```dart
static const List<int> retryDelays = [5, 10, 15]; // More patient retries
```

---

## Troubleshooting

### Cannot Connect to Backend

1. **Verify backend is running:**
   ```bash
   cd backend
   npm run dev
   # Should show "Ready in XXXms"
   ```

2. **Test backend health:**
   ```bash
   curl http://YOUR_IP:3000/api/health
   # Or in PowerShell:
   Invoke-RestMethod http://YOUR_IP:3000/api/health
   ```

3. **Check Flutter configuration:**
   - Open `lib/config/app_config.dart`
   - Verify `current` matches your desired environment
   - Verify URL in that environment case is correct
   - Rebuild app after changes: `flutter run`

4. **Network issues:**
   - Ensure device and computer on same WiFi
   - Check firewall isn't blocking port 3000
   - Try ngrok tunnel instead of local network

### "Connection Refused" Error

**Causes:**
- Wrong IP address in configuration
- Backend not running
- Firewall blocking connection

**Fix:**
```powershell
# 1. Get your actual IP
ipconfig

# 2. Test backend responds on that IP
Invoke-RestMethod http://YOUR_IP:3000/api/health

# 3. Update app_config.dart with the working IP
# 4. Rebuild and run Flutter app
flutter run
```

### "Request Timed Out" Error

**Causes:**
- Slow network connection
- Backend processing too slowly
- Database query taking too long

**Fix:**
- Increase timeout in `app_config.dart`
- Check backend logs for slow queries
- Test with smaller data sets
- Consider adding pagination

### App Shows Old Backend URL

**Cause:** Flutter uses cached build, didn't pick up config changes

**Fix:**
```bash
# Full rebuild
flutter clean
flutter pub get
flutter run
```

---

## Testing Checklist

Before testing on a device, verify:

- [ ] Backend server is running (`npm run dev`)
- [ ] Health check succeeds in browser/curl
- [ ] `app_config.dart` has correct environment selected
- [ ] URL in that environment matches your setup
- [ ] Device is on same network (if using local environment)
- [ ] Firewall allows incoming connections on port 3000
- [ ] App has been rebuilt after config changes (`flutter run`)

---

## Quick Reference

| Environment | When to Use | Configuration Required |
|-------------|-------------|------------------------|
| **Local** | Same WiFi testing | Update local IP address |
| **Ngrok** | External access | Run ngrok, copy URL |
| **Production** | Live app | Deploy backend, set URL |
| **Custom** | Special cases | Set custom URL |

**Change Environment:**
1. Open `lib/config/app_config.dart`
2. Find `static BackendEnvironment current = ...`
3. Change to desired environment
4. Update URL for that environment if needed
5. Rebuild app: `flutter run`

**Find Local IP:**
```powershell
# Windows
ipconfig
# Look for "IPv4 Address" under active adapter
```

**Test Backend:**
```powershell
Invoke-RestMethod http://YOUR_IP:3000/api/health
```

**Start Backend:**
```bash
cd backend
npm run dev
```

---

## Additional Resources

- [Backend README](../backend/README.md) - Server setup and API documentation
- [Troubleshooting Guide](../backend/docs/TROUBLESHOOTING.md) - Common issues and fixes
- [Flutter Networking](https://docs.flutter.dev/development/data-and-backend/networking) - Official Flutter docs
- [Ngrok Documentation](https://ngrok.com/docs) - Tunnel setup and usage
