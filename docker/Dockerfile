# syntax=docker/dockerfile:1.7
#
# Builds both Khushi Dua projects. Run through docker/build.sh rather than
# calling this directly; the script wires up the signing secrets and outputs.
#
#   android-artifact  khushidua (mobile)      -> app-release.aab (+ optional .apk)
#   web-artifact      khushiduaadmin (web)    -> build/web
#   web               khushiduaadmin (web)    -> nginx image serving build/web
#
# Build context is the repo root (see /.dockerignore).

ARG FLUTTER_VERSION=3.47.2

# ---------------------------------------------------------------------------
# Flutter SDK (shared by both apps)
# ---------------------------------------------------------------------------
FROM ubuntu:24.04 AS flutter-sdk
ARG FLUTTER_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/root/.pub-cache \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    CI=true
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl git unzip xz-utils zip \
 && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" \
      https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
 && git config --global --add safe.directory "${FLUTTER_HOME}" \
 && flutter config --no-analytics --no-cli-animations \
 && dart --disable-analytics \
 && flutter --version

# ---------------------------------------------------------------------------
# Admin web app
# ---------------------------------------------------------------------------
FROM flutter-sdk AS web-build

RUN flutter config --enable-web --no-enable-android --no-enable-linux-desktop \
 && flutter precache --web --no-android --no-ios --no-linux

WORKDIR /src/khushiduaadmin
COPY khushiduaadmin/pubspec.yaml khushiduaadmin/pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache flutter pub get

COPY khushiduaadmin/ ./
RUN --mount=type=cache,target=/root/.pub-cache \
    flutter pub get && flutter build web --release

# `docker build --output` target: just the static files.
FROM scratch AS web-artifact
COPY --from=web-build /src/khushiduaadmin/build/web /

# Local preview server, mirroring firebase.json (SPA rewrite, no-cache).
FROM nginx:1.27-alpine AS web
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=web-build /src/khushiduaadmin/build/web /usr/share/nginx/html
EXPOSE 80

# ---------------------------------------------------------------------------
# Android SDK
# ---------------------------------------------------------------------------
FROM flutter-sdk AS android-sdk

# Keep these in step with khushidua/android/{build.gradle.kts,app/build.gradle.kts}.
ARG ANDROID_CMDLINE_TOOLS=13114758
ARG ANDROID_PLATFORM=36
ARG ANDROID_BUILD_TOOLS=36.0.0
ARG ANDROID_NDK=29.0.14206865

ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    GRADLE_USER_HOME=/root/.gradle
ENV PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# AGP 8.11 needs JDK 17+.
RUN apt-get update \
 && apt-get install -y --no-install-recommends openjdk-17-jdk-headless \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p "${ANDROID_HOME}/cmdline-tools" \
 && curl -fsSL -o /tmp/cmdline-tools.zip \
      "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
 && unzip -q /tmp/cmdline-tools.zip -d "${ANDROID_HOME}/cmdline-tools" \
 && mv "${ANDROID_HOME}/cmdline-tools/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest" \
 && rm /tmp/cmdline-tools.zip \
 && yes | sdkmanager --licenses > /dev/null \
 && sdkmanager --install \
      "platform-tools" \
      "platforms;android-${ANDROID_PLATFORM}" \
      "build-tools;${ANDROID_BUILD_TOOLS}" \
      "ndk;${ANDROID_NDK}" > /dev/null

RUN flutter config --enable-android --no-enable-web --no-enable-linux-desktop \
      --android-sdk "${ANDROID_HOME}" \
 && flutter precache --android --no-web --no-ios --no-linux \
 && yes | flutter doctor --android-licenses > /dev/null

# ---------------------------------------------------------------------------
# Mobile app (Android bundle)
# ---------------------------------------------------------------------------
FROM android-sdk AS android-build

# Set to 1 to also produce a release APK next to the bundle.
ARG BUILD_APK=0
# Set to 1 to allow the debug-key fallback in app/build.gradle.kts (not uploadable to Play).
ARG ALLOW_DEBUG_SIGNING=0

WORKDIR /src/khushidua
COPY khushidua/pubspec.yaml khushidua/pubspec.lock ./
RUN --mount=type=cache,target=/root/.pub-cache flutter pub get

COPY khushidua/ ./

# key.properties and the keystore arrive as BuildKit secrets, so they are never
# written into an image layer. storeFile is rewritten to the mounted secret.
RUN --mount=type=cache,target=/root/.pub-cache \
    --mount=type=cache,target=/root/.gradle \
    --mount=type=secret,id=key_properties,required=false \
    --mount=type=secret,id=keystore,required=false \
    set -eu; \
    if [ -s /run/secrets/key_properties ] && [ -s /run/secrets/keystore ]; then \
      sed 's#^storeFile=.*#storeFile=/run/secrets/keystore#' \
        /run/secrets/key_properties > android/key.properties; \
      echo ">> Signing with the release keystore"; \
    elif [ "${ALLOW_DEBUG_SIGNING}" = "1" ]; then \
      echo ">> WARNING: no keystore supplied, signing with the DEBUG key"; \
    else \
      echo "ERROR: release keystore not supplied (see docker/build.sh --help)" >&2; \
      exit 1; \
    fi; \
    trap 'rm -f android/key.properties' EXIT; \
    flutter pub get; \
    flutter build appbundle --release; \
    mkdir -p /out; \
    cp build/app/outputs/bundle/release/app-release.aab /out/; \
    if [ "${BUILD_APK}" = "1" ]; then \
      flutter build apk --release; \
      cp build/app/outputs/flutter-apk/app-release.apk /out/; \
    fi; \
    cd /out && sha256sum * > SHA256SUMS

FROM scratch AS android-artifact
COPY --from=android-build /out/ /
