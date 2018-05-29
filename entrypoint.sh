#!/bin/bash

#====================================
# Emulator setup
#====================================
adb devices

if [ -z "$SKIN_NAME" ]; then
  SKIN_NAME="pixel"
fi

#Replace the avd config.ini with the device config.
cat /usr/local/android-sdk-linux/devices/${SKIN_NAME}.avd/config.ini > /root/.android/avd/emulatorAPI${API_LEVEL}.avd/config.ini
cat /usr/local/android-sdk-linux/devices/${SKIN_NAME}.ini > /root/.android/avd/emulatorAPI${API_LEVEL}.ini

cat <<EOT >> /root/.android/avd/emulatorAPI${API_LEVEL}.avd/config.ini
image.sysdir.1=system-images/android-${API_LEVEL}/google_apis/x86/
EOT

cat <<EOT >> /root/.android/avd/emulatorAPI${API_LEVEL}.ini
target=android-${API_LEVEL}
path=/root/.android/avd/emulatorAPI${API_LEVEL}.avd
EOT

/usr/local/android-sdk-linux/emulator/emulator -avd emulatorAPI${API_LEVEL} -noaudio -no-window -gpu off -verbose -qemu &

while [ "`adb shell getprop sys.boot_completed | tr -d '\r' `" != "1" ] ; do sleep 1; done

#====================================
# Appium Setup
#====================================
if [ -z "$PLATFORM_NAME" ]; then
  PLATFORM_NAME="Android"
fi

if [ -z "$APPIUM_HOST" ]; then
  APPIUM_HOST=$(hostname -i)
fi

if [ -z "$APPIUM_PORT" ]; then
  APPIUM_PORT=4723
fi

if [ -z "$SELENIUM_HOST" ]; then
  SELENIUM_HOST="192.168.0.31"
fi

if [ -z "$SELENIUM_PORT" ]; then
  SELENIUM_PORT=4444
fi

if [ -z "$BROWSER_NAME" ]; then
  BROWSER_NAME=$SKIN_NAME
fi

if [ -z "$NODE_TIMEOUT" ]; then
  NODE_TIMEOUT=300
fi

#Final node configuration json string
nodeconfig=$(cat <<_EOF
{
  "capabilities": [
    {
     "platform": "$PLATFORM_NAME",
     "platformName": "$PLATFORM_NAME",
     "browserName": "$BROWSER_NAME",
     "maxInstances": 1,
     "deviceName": "$SKIN_NAME"
    }
  ],
  "configuration": {
    "cleanUpCycle": 2000,
    "timeout": $NODE_TIMEOUT,
    "proxy": "org.openqa.grid.selenium.proxy.DefaultRemoteProxy",
    "url": "http://$APPIUM_HOST:$APPIUM_PORT/wd/hub",
    "host": "$APPIUM_HOST",
    "port": $APPIUM_PORT,
    "maxSession": 6,
    "register": true,
    "registerCycle": 5000,
    "hubHost": "$SELENIUM_HOST",
    "hubPort": $SELENIUM_PORT
  }
}
_EOF
)
echo "$nodeconfig" > nodeconfig.json

appium --nodeconfig nodeconfig.json


