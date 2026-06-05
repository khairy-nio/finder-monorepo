#!/bin/bash
echo "Starting background xattr daemon to protect against iCloud..."
while true; do
    xattr -cr build/ios 2>/dev/null || true
    xattr -cr ios/Pods 2>/dev/null || true
    sleep 0.2
done &
DAEMON_PID=$!

echo "Running Flutter..."
flutter run --release -d 00008120-000451542610201E

echo "Stopping daemon..."
kill $DAEMON_PID
