#!/bin/bash
# Run this after your Apple Developer App ID limit resets (10 per 7 days)
# Then in Xcode:
# 1. Select MeetMind target → General → Embedded Content
# 2. Click + → Add MeetMindWatch Watch App.app
# 3. Set to "Embed Without Signing"
# 4. Build and run
echo "To re-enable Apple Watch app:"
echo "1. Open Xcode → MeetMind target → General → Embedded Content"
echo "2. Click + → Add 'MeetMindWatch Watch App.app'"
echo "3. Set to 'Embed Without Signing'"
echo "4. Build and run (Cmd+R)"
echo ""
echo "Your App ID limit resets every 7 days."
