# Google Maps API Setup Guide

## Overview
The Order Tracker now includes live delivery tracking with Google Maps! To enable this feature, you need to set up a Google Maps API key.

## What You'll See
- **Interactive map** showing delivery location and driver position
- **Real-time updates** as the driver moves toward your location
- **Distance display** showing how far away the driver is
- **ETA calculation** estimating arrival time
- **Route visualization** with a line connecting driver to delivery address

## Setup Steps

### 1. Get a Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Maps SDK for Android**:
   - Click "Enable APIs and Services"
   - Search for "Maps SDK for Android"
   - Click "Enable"
4. Create an API key:
   - Go to "Credentials" in the left menu
   - Click "Create Credentials" → "API Key"
   - Copy your API key

### 2. Configure the App

1. Open: `android/app/src/main/AndroidManifest.xml`
2. Find this line:
   ```xml
   android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual API key
4. Save the file

### 3. Test the Feature

1. Run `flutter clean` to clear cache
2. Run your app on a physical device (maps don't work well in emulators)
3. Place a test order
4. Navigate to Order Tracker
5. Once the order status is "Shipped", you'll see the map!

## How It Works

### Map Visibility
- The map appears **only when order status is "Shipped"** (step 3 of 4)
- Before shipping, you'll see the regular timeline
- After delivery, the map disappears

### Driver Simulation
Since this is a demo app without real driver GPS:
- Driver starts at a simulated location near Manila
- Position updates every 3 seconds
- Driver moves 10% closer to delivery location each update
- When driver arrives (within 100m), map animation stops

### Distance & ETA
- **Distance**: Calculated using Haversine formula (accurate)
- **ETA**: Based on average speed of 30 km/h
- Updates every 3 seconds as driver moves

### Map Controls
- **Distance overlay** (top-left): Shows real-time distance and ETA
- **Center button** (bottom-right): Auto-zooms to show both markers
- **Pinch to zoom**: Standard Google Maps gestures work
- **Drag to pan**: Move the map around

### Markers
- 🟢 **Green marker**: Your delivery location
- 🔵 **Blue marker**: Driver's current location
- **Dashed line**: Route between driver and delivery

## Troubleshooting

### Map shows gray screen
- Check that you added the API key correctly
- Ensure Maps SDK for Android is enabled
- Run `flutter clean && flutter pub get`
- Try rebuilding the app

### Map not appearing
- Check order status - map only shows when "Shipped"
- Verify you ran `flutter pub get` after adding dependencies
- Check device internet connection

### API key issues
- Ensure you copied the entire key (no spaces)
- Check that Maps SDK for Android is enabled (not just Maps JavaScript API)
- API keys can take a few minutes to activate after creation

### Performance tips
- Test on a physical device (emulators are slow with maps)
- Avoid running multiple apps with maps simultaneously
- Clear app data if map becomes unresponsive

## Cost Considerations

### Free Tier
Google Maps offers a generous free tier:
- **$200 credit per month**
- Map loads: 0-100,000 free per month
- This demo app usage: Well within free limits

### Restricting Your Key
For security, restrict your API key:
1. Go to Google Cloud Console → Credentials
2. Click your API key
3. Under "Application restrictions":
   - Select "Android apps"
   - Add your app's package name: `com.example.pharmacy_app`
   - Add SHA-1 fingerprint (run: `keytool -list -v -keystore ~/.android/debug.keystore`)

## Next Steps

Once the map is working, you can:
- **Customize markers**: Use custom truck/house icons
- **Add notifications**: Alert user when driver is 5 minutes away
- **Real driver integration**: Connect to actual GPS tracking backend
- **Traffic data**: Show estimated delays from Google Maps Traffic
- **Multiple stops**: Show if driver has other deliveries first

## Support

If you encounter issues:
1. Check `SETUP_PUBLIC_ACCESS.md` for general troubleshooting
2. Verify Firebase configuration is correct
3. Ensure all dependencies installed: `flutter pub get`
4. Check Android logs: `flutter run -v`

---

**Note**: This is a simulated tracking feature. For production use, you'd need:
- Backend server tracking real driver locations
- WebSocket/Firebase for real-time updates
- Driver mobile app with GPS enabled
- Route optimization algorithms
- Delivery zones and geofencing
