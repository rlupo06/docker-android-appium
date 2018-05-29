FROM ubuntu

RUN apt-get -qqy update && apt-get -qqy install --no-install-recommends \
wget  \
unzip \
curl \
openjdk-8-jdk \
qemu-kvm \
libvirt-bin \
ubuntu-vm-builder \
bridge-utils

#===============
# Set JAVA_HOME
#===============
ENV JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64/jre" \
    PATH=$PATH:$JAVA_HOME/bin

#===============
# Install SDK
#===============
# Download and untar Android SDK tools
RUN mkdir -p /usr/local/android-sdk-linux

RUN wget https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip -O tools.zip
RUN unzip tools.zip -d /usr/local/android-sdk-linux
RUN rm tools.zip

ENV ANDROID_HOME=/usr/local/android-sdk-linux
ENV PATH ${ANDROID_HOME}/tools/bin:${PATH}

#===================
# Install SDK tools
#===================

RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses

# Install android build tools, platform, emulator engines, sdk tools including avdmanager
RUN sdkmanager \
    "build-tools;27.0.3" \
    "platforms;android-27" \
    "emulator" \
    "tools"

ENV PATH ${ANDROID_HOME}/platform-tools:${PATH}

#======================
# Install system Images
#=======================

#Install system image.
RUN yes | $ANDROID_HOME/tools/bin/sdkmanager --licenses
ARG API_LEVEL=27
ENV API_LEVEL=$API_LEVEL

RUN $ANDROID_HOME/tools/bin/sdkmanager "system-images;android-${API_LEVEL};google_apis;x86"

#================================
# Create Android virtual devices
#================================

#Create android virtual device
RUN echo no | avdmanager create avd -n emulatorAPI${API_LEVEL} -k "system-images;android-${API_LEVEL};google_apis;x86"

#copy over skins
RUN mkdir -p /usr/local/android-sdk-linux/skins
COPY skins /usr/local/android-sdk-linux/skins

#copy over device config files
RUN mkdir -p /usr/local/android-sdk-linux/devices
COPY /devices /usr/local/android-sdk-linux/devices

#====================================
# Install latest nodejs, npm, appium
#====================================
ARG APPIUM_VERSION=1.7.2
ENV APPIUM_VERSION=$APPIUM_VERSION

RUN curl -sL https://deb.nodesource.com/setup_7.x | bash - && \
    apt-get -qqy install nodejs && \
    npm install -g appium@${APPIUM_VERSION} && \
    npm cache clean && \
    apt-get remove --purge -y npm && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    apt-get clean

# Add entrypoint
ADD entrypoint.sh /entrypoint.sh
    
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]