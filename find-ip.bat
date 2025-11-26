@echo off
REM Script to find your computer's IP address
REM Run this and copy the IPv4 Address shown for your WiFi connection

echo.
echo ========================================
echo Finding Your Computer's IP Address
echo ========================================
echo.
echo Run the command below and look for your WiFi adapter:
echo.

ipconfig

echo.
echo ========================================
echo INSTRUCTIONS:
echo 1. Look for "Ethernet adapter" or "Wireless LAN adapter"
echo 2. Find the "IPv4 Address" (e.g., 192.168.1.100)
echo 3. Copy this IP address
echo 4. Go to lib/services/auth_service.dart
echo 5. Replace 192.168.1.5 with YOUR IP
echo 6. Restart the app
echo ========================================
echo.

pause
