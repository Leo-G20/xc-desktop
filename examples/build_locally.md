
Example for building using Containerfile
 ```yaml
services:
  xc:
    image: xc-desktop:local
    build:
      context: .
      dockerfile: Containerfile
    userns_mode: "keep-id:uid=1000,gid=1000"
    ports:
      - "127.0.0.1:8080:8080"
    shm_size: 2gb
    environment:
      # Set SELKIES_PASSWORD to choose a different desktop password.
      PASSWD: ${SELKIES_PASSWORD:-1234}
      LIBGL_ALWAYS_SOFTWARE: "true"
      SELKIES_USE_CPU: "true"
      SELKIES_ENCODER: h264enc
    volumes:
      - ./workspace:/home/xc

 ```
