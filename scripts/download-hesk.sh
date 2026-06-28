#!/usr/bin/env sh
set -eu

if [ "$#" -lt 2 ]; then
  echo "Usage: download-hesk VERSION OUTPUT_ZIP" >&2
  exit 2
fi

expected_version="$1"
out="$2"
legacy_url="https://www.hesk.com/download-legacy.php"
current_url="https://www.hesk.com/download.php"
page="$(mktemp)"
jar="$(mktemp)"
trap 'rm -f "$page" "$jar"' EXIT

is_zip() {
  [ "$(head -c 4 "$1" | od -An -tx1 | tr -d ' \n')" = "504b0304" ]
}

curl -fsSL "$legacy_url" -o "$page"
archive_url="$(sed -nE 's#.*href="([^"]+)"[^>]*>Download Hesk version <b>'"$expected_version"'</b>.*#\1#p' "$page" | head -n1)"

if [ -n "$archive_url" ]; then
  echo "Downloading Hesk $expected_version from legacy archive: $archive_url"
  curl -fsSLo "$out" "$archive_url"
  if ! is_zip "$out"; then
    echo "Legacy archive for Hesk $expected_version did not return a zip" >&2
    exit 1
  fi
  exit 0
fi

echo "Hesk $expected_version is not listed in the legacy archive; trying current download page"

curl -fsSL -c "$jar" "$current_url" -o "$page"
if ! grep -q "Download Hesk ($expected_version)" "$page"; then
  echo "Current download page does not advertise expected Hesk version $expected_version" >&2
  exit 1
fi

challenge="$(sed -nE 's/.*>([0-9]+)[[:space:]]*\+[[:space:]]*([0-9]+)[[:space:]]*=.*/\1 \2/p' "$page" | head -n1)"
if [ -z "$challenge" ]; then
  echo "Could not parse Hesk download challenge" >&2
  exit 1
fi

set -- $challenge
answer=$(( $1 + $2 ))

curl -fsSLo "$out" \
  -b "$jar" \
  -c "$jar" \
  -e "$current_url" \
  -X POST \
  -d "code3=$answer" \
  -d "telephone=" \
  "$current_url"

if ! is_zip "$out"; then
  echo "Current Hesk download did not return a zip archive" >&2
  exit 1
fi
