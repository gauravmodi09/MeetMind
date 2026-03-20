#!/bin/bash
# Force iOS to refresh the app icon
# 1. Delete the app from your iPhone
# 2. In Xcode: Product → Clean Build Folder (Shift+Cmd+K)
# 3. Delete DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData/MeetMind*
# 4. Build and run (Cmd+R)
echo "Steps to refresh app icon:"
echo "1. Delete MeetMind from iPhone (Settings → General → iPhone Storage)"
echo "2. Xcode: Product → Clean Build Folder (Shift+Cmd+K)"
echo "3. Run: rm -rf ~/Library/Developer/Xcode/DerivedData/MeetMind*"
echo "4. Build and run (Cmd+R)"
