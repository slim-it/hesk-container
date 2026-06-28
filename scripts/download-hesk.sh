#!/usr/bin/env sh
set -eu

if [ "$#" -lt 2 ]; then
  echo "Usage: download-hesk VERSION OUTPUT_ZIP" >&2
  exit 2
fi

expected_version="$1"
out="$2"
legacy_url="https://www.hesk.com/download-legacy.php"
page="$(mktemp)"
trap 'rm -f "$page"' EXIT

is_zip() {
  [ "$(head -c 4 "$1" | od -An -tx1 | tr -d ' \n')" = "504b0304" ]
}

curl -fsSL "$legacy_url" -o "$page"
archive_url="$(sed -nE 's#.*href="([^"]+)"[^>]*>Download Hesk version <b>'"$expected_version"'</b>.*#\1#p' "$page" | head -n1)"

if [ -z "$archive_url" ]; then
  echo "Hesk $expected_version is not listed in the legacy archive" >&2
  exit 1
fi

echo "Downloading Hesk $expected_version from legacy archive: $archive_url"
curl -fsSLo "$out" "$archive_url"

if ! is_zip "$out"; then
  echo "Legacy archive for Hesk $expected_version did not return a zip" >&2
  exit 1
fi
