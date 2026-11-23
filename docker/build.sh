#!/usr/bin/env bash
# Dockerized builds for Khushi Dua. Run from anywhere in the repo.
#
#   docker/build.sh android [--apk] [--debug-signing]
#       Builds the mobile app's release bundle into dist/android/app-release.aab
#       for manual upload to Play Console. Needs the release keystore:
#         KEY_PROPERTIES  path to key.properties  (default: khushidua/android/key.properties)
#         KEYSTORE        path to the .jks file   (default: storeFile from key.properties,
#                                                  resolved relative to khushidua/android/app)
#       --bump           increment the build number in khushidua/pubspec.yaml first
#                        (1.6.0+28 -> 1.6.0+29); Play rejects a reused build number
#       --version=X.Y.Z+N  set khushidua/pubspec.yaml to exactly this version first
#       --apk            also build dist/android/app-release.apk
#       --debug-signing  allow a debug-signed build when no keystore is set (NOT uploadable)
#
#   docker/build.sh web
#       Builds the admin web app into dist/web/ (same output CI deploys to Firebase).
#
#   docker/build.sh web-serve [PORT]
#       Builds the admin web app and serves it at http://localhost:PORT (default 8080).
#
# FLUTTER_VERSION overrides the Flutter release (default matches CI: 3.47.2).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKERFILE="$ROOT/docker/Dockerfile"
export DOCKER_BUILDKIT=1

build_args=()
[[ -n "${FLUTTER_VERSION:-}" ]] && build_args+=(--build-arg "FLUTTER_VERSION=$FLUTTER_VERSION")

usage() { sed -n '2,/^[^#]/{/^#/p}' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

cmd="${1:-}"; shift || true
case "$cmd" in
  android)
    apk=0; debug=0; bump=0; set_version=""
    for arg in "$@"; do
      case "$arg" in
        --apk) apk=1 ;;
        --debug-signing) debug=1 ;;
        --bump) bump=1 ;;
        --version=*) set_version="${arg#--version=}" ;;
        *) echo "Unknown option: $arg" >&2; exit 2 ;;
      esac
    done

    pubspec="$ROOT/khushidua/pubspec.yaml"
    current="$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | tr -d '\r')"
    [[ "$current" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]] \
      || { echo "Unexpected version in pubspec.yaml: '$current' (want X.Y.Z+N)" >&2; exit 1; }
    name="${BASH_REMATCH[1]}"; code="${BASH_REMATCH[2]}"

    if [[ -n "$set_version" ]]; then
      [[ "$set_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+$ ]] \
        || { echo "--version must look like 1.6.1+29, got '$set_version'" >&2; exit 2; }
      new="$set_version"
    elif [[ $bump -eq 1 ]]; then
      new="$name+$((code + 1))"
    else
      new="$current"
    fi
    if [[ "$new" != "$current" ]]; then
      sed -i "s/^version:.*/version: $new/" "$pubspec"
      echo ">> Version: $current -> $new (remember to commit pubspec.yaml)"
    else
      echo ">> Version: $current (unchanged; use --bump if this build number is already on Play)"
    fi

    key_props="${KEY_PROPERTIES:-$ROOT/khushidua/android/key.properties}"
    secrets=()
    if [[ -f "$key_props" ]]; then
      keystore="${KEYSTORE:-}"
      if [[ -z "$keystore" ]]; then
        store_file="$(sed -n 's/^storeFile=//p' "$key_props" | tr -d '\r')"
        [[ "$store_file" = /* ]] && keystore="$store_file" \
          || keystore="$ROOT/khushidua/android/app/$store_file"
      fi
      [[ -f "$keystore" ]] || { echo "Keystore not found: $keystore (set KEYSTORE=...)" >&2; exit 1; }
      secrets=(--secret "id=key_properties,src=$key_props" --secret "id=keystore,src=$keystore")
      echo ">> key.properties: $key_props"
      echo ">> keystore:       $keystore"
    elif [[ $debug -eq 0 ]]; then
      echo "No key.properties at $key_props." >&2
      echo "Set KEY_PROPERTIES=/path/to/key.properties, or pass --debug-signing for a test build." >&2
      exit 1
    fi

    rm -rf "$ROOT/dist/android"
    docker build -f "$DOCKERFILE" --target android-artifact \
      --build-arg "BUILD_APK=$apk" --build-arg "ALLOW_DEBUG_SIGNING=$debug" \
      "${build_args[@]}" "${secrets[@]}" \
      --output "type=local,dest=$ROOT/dist/android" "$ROOT"
    echo; echo ">> Output in dist/android/:"; ls -lh "$ROOT/dist/android"
    ;;

  web)
    rm -rf "$ROOT/dist/web"
    docker build -f "$DOCKERFILE" --target web-artifact "${build_args[@]}" \
      --output "type=local,dest=$ROOT/dist/web" "$ROOT"
    echo; echo ">> Output in dist/web/"
    ;;

  web-serve)
    port="${1:-8080}"
    docker build -f "$DOCKERFILE" --target web "${build_args[@]}" -t khushidua-admin-web "$ROOT"
    echo ">> Serving on http://localhost:$port (Ctrl+C to stop)"
    docker run --rm -p "$port:80" khushidua-admin-web
    ;;

  ""|-h|--help|help) usage ;;
  *) echo "Unknown command: $cmd" >&2; usage; exit 2 ;;
esac
