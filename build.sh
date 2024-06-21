#!/bin/bash

# Define the root directory of the script
ROOT_DIR="$(dirname "$0")"

# Remove any existing build artifacts
rm -rf "$ROOT_DIR/build/*"

# Build the Xcode project and create the archive
/usr/bin/xcodebuild -scheme smst -project "$ROOT_DIR/smst.xcodeproj" \
    -configuration Release clean archive -archivePath "$ROOT_DIR/build/SMSTApp.xcarchive" \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

# Copy the .app file to the Payload directory
cp -R "$ROOT_DIR/build/SMSTApp.xcarchive/Products/Applications" "$ROOT_DIR/build/Payload/"

# Sign the app using ldid
(cd "$ROOT_DIR" && ldid -Sentitlements.xml "$ROOT_DIR/build/Payload/smst.app/smst")

# Add UIBackgroundModes key with fetch and remote-notification modes
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "$ROOT_DIR/build/Payload/smst.app/Info.plist"
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string fetch" "$ROOT_DIR/build/Payload/smst.app/Info.plist"
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:1 string remote-notification" "$ROOT_DIR/build/Payload/smst.app/Info.plist"

# Create the .ipa file
cd "$ROOT_DIR/build"
zip -r SMST.ipa Payload
