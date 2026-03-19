# MeetMind — TestFlight Prep Checklist

## Pre-Submission
- [ ] Set DEVELOPMENT_TEAM in project settings
- [ ] Configure code signing (automatic)
- [ ] Add App Store Connect app record
- [ ] Set version 1.0.0 build 1
- [ ] Verify Info.plist privacy descriptions
- [ ] Test on physical iPhone (recording quality, background mode)
- [ ] Test network failure scenarios
- [ ] Test with real Groq API key
- [ ] Verify 3-hour recording limit works
- [ ] Test offline queue + reconnect

## App Store Connect Setup
- [ ] Create app record in App Store Connect
- [ ] Upload screenshots (6.7" iPhone)
- [ ] Write App Store description (see docs/app-store-listing.md)
- [ ] Set privacy nutrition labels (microphone, local storage)
- [ ] Add privacy policy URL

## TestFlight Distribution
- [ ] Archive for distribution
- [ ] Upload to App Store Connect via Xcode
- [ ] Add internal testers
- [ ] Write test notes for testers
- [ ] Monitor crash reports in Xcode Organizer
