# Hesk container

Container image for Hesk Free, built from the official Hesk download and a maintained PHP Apache runtime.

`VERSION` is the single source of truth for the Hesk version. CI reads it for both the Docker build argument and the image tag.

The image contains the Hesk application files. Runtime state is kept in `/data`:

- `/data/hesk_settings.inc.php`
- `/data/attachments`
- `/data/cache`

The container symlinks those paths into `/var/www/html` at runtime, so the Hesk installer and uploaded files survive pod restarts without putting the entire app tree on a PVC.

## Image

CI publishes:

```text
ghcr.io/slim-it/hesk-container:<version>
ghcr.io/slim-it/hesk-container:latest
ghcr.io/slim-it/hesk-container:sha-<git-sha>
```

## Build locally

```sh
docker build --build-arg HESK_VERSION="$(cat VERSION)" -t ghcr.io/slim-it/hesk-container:"$(cat VERSION)" .
```

## Run locally

```sh
docker run --rm -p 8080:80 -v hesk-data:/data ghcr.io/slim-it/hesk-container:"$(cat VERSION)"
```

Then open `http://localhost:8080/install/` and complete Hesk's installer.

## Download behavior

The build script checks `https://www.hesk.com/download-legacy.php` for the version in `VERSION` and downloads the stable archive URL from there. It intentionally does not use the current-release form download, so this image may lag Hesk's newest release until that release appears in the archive.

Do not commit Hesk archives, generated settings, database credentials, or installed runtime data to this repository.
