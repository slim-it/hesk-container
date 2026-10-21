# Hesk container

Container image for Hesk Free, built from the official Hesk download and a maintained PHP-FPM runtime. It runs as `www-data` (UID 33) and serves PHP over FastCGI on port 9000; a web server in front of it serves the static files and passes PHP requests through.

`VERSION` is the single source of truth for the Hesk version. CI reads it for the Docker build argument and appends the build number to it for the image tag.

The build number is part of the tag so that every rebuild publishes a strictly higher one. A base image update, or anything else that changes the image without changing Hesk, otherwise replaces the contents of an existing tag in place — and a consumer pinning that tag has no way to notice there is anything new. The Hesk version inside an image is recorded in its `nl.slim-it.hesk.version` label.

The image keeps the Hesk application files in `/usr/src/hesk`, and the entrypoint copies them into `/var/www/html` at every start. A web server container sharing that directory (an `emptyDir` in Kubernetes) therefore always sees exactly the code the image ships, without the files living on a persistent volume. Runtime state is kept in `/data`, which must be writable by UID 33:

- `/data/hesk_settings.inc.php`
- `/data/attachments`
- `/data/language`

The web root symlinks those paths, so the Hesk installer's settings and uploaded files survive restarts. The web server needs none of them: attachments are downloaded through PHP, and it should refuse `attachments/`, `vendor/`, `inc/`, `language/`, `cache/` and `cron/` outright.

## Image

CI publishes:

```text
ghcr.io/slim-it/hesk-container:<hesk-version>.<build>
ghcr.io/slim-it/hesk-container:latest
ghcr.io/slim-it/hesk-container:sha-<git-sha>
```

## Build locally

```sh
docker build --build-arg HESK_VERSION="$(cat VERSION)" -t ghcr.io/slim-it/hesk-container:"$(cat VERSION)" .
```

## Run locally

The image needs a web server beside it, sharing the web root and the network namespace. With podman:

```sh
podman pod create --name hesk -p 8080:8080
podman volume create hesk-www
podman run -d --pod hesk -v hesk-data:/data -v hesk-www:/var/www/html ghcr.io/slim-it/hesk-container:"$(cat VERSION)"
podman run -d --pod hesk -v hesk-www:/var/www/html:ro -v ./nginx.conf:/etc/nginx/conf.d/default.conf:ro nginxinc/nginx-unprivileged:alpine
```

with an `nginx.conf` that listens on 8080, uses `/var/www/html` as its root, and passes `*.php` to `127.0.0.1:9000`. Then open `http://localhost:8080/install/` and complete Hesk's installer.

## Download behavior

The build script checks `https://www.hesk.com/download-legacy.php` for the version in `VERSION` and downloads the stable archive URL from there. It intentionally does not use the current-release form download, so this image may lag Hesk's newest release until that release appears in the archive.

Do not commit Hesk archives, generated settings, database credentials, or installed runtime data to this repository.
