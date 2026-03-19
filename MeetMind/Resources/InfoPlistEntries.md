# Required Info.plist Entries for MeetMind

Add these keys to the Xcode project's Info.plist (or the Info tab in target settings).

## Privacy Permissions

### Microphone Access (Required)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>MeetMind needs microphone access to record your meetings and capture voice todos.</string>
```

### Speech Recognition (Required for voice todos)
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>MeetMind uses speech recognition to create todos from your voice commands.</string>
```

### Face ID / Biometrics (Optional -- for Keychain-protected API key)
```xml
<key>NSFaceIDUsageDescription</key>
<string>MeetMind uses Face ID to protect your API key stored in the Keychain.</string>
```

## Background Modes

### Audio Recording in Background
```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

Enable this in Xcode: Target > Signing & Capabilities > + Background Modes > check "Audio, AirPlay, and Picture in Picture".

## iCloud (for CloudKit sync)

Enable in Xcode: Target > Signing & Capabilities > + iCloud > check "CloudKit".

Container identifier: `iCloud.com.meetmind.app`

## App Transport Security

No changes needed -- all network requests go to HTTPS endpoints (Groq API).
