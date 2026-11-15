## xc-desktop demo

This is an experimental desktop image adapted from XC’s existing Docker build. It adds an XFCE desktop accessible through a browser using Selkies.

## Install and use

1. Install Podman or Docker with Compose support.
2. Save [compose.yaml](compose.yaml) in a folder. Inside that folder, create an empty `workspace` subfolder and run the command below:

   ```bash
   podman compose up -d
   ```

   For Docker, use `docker compose up -d`.

3. Open https://localhost:8080 in your browser. Log in as `xc` with password `1234`.

## other notes
root commands:

```bash
podman compose exec --user root xc "command"
```
