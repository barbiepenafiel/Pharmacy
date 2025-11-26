#!/bin/bash
# Script to find your computer's IP address
# Run this and copy the IPv4 Address shown for your WiFi connection

echo ""
echo "========================================"
echo "Finding Your Computer's IP Address"
echo "========================================"
echo ""
echo "Network configuration:"
echo ""

ifconfig

echo ""
echo "========================================"
echo "INSTRUCTIONS:"
echo "1. Look for 'inet' address under en0 or en1"
echo "2. Copy this IP address (e.g., 192.168.1.100)"
echo "3. Go to lib/services/auth_service.dart"
echo "4. Replace 192.168.1.5 with YOUR IP"
echo "5. Restart the app"
echo "========================================"
echo ""
