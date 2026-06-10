# Satisfactory Server on ARM64 using FEX
Thanks to [sa-shiro/Satisfactory-Dedicated-Server-ARM64-Docker](https://github.com/sa-shiro/Satisfactory-Dedicated-Server-ARM64-Docker), they inspired this project. It is also an improved fork of their project.

---

## Getting Started

1. **Make directory**:  
   by doing this: `mkdir satisfactory-server && cd satisfactory-server`

2. **Docker Compose setup**:
   Paste this in the directory's docker-compose.yml:
```
services:
  satisfactory-server:
    build:
      context: https://github.com/ayayrom/Satisfactory-Server-ARM-Docker.git#main
      dockerfile: Dockerfile 
      # change to "Dockerfile.generic" if you are not using Oracle Ampere

    container_name: 'satisfactory-server'
    ports:
      - '7777:7777/udp'
      - '7777:7777/tcp'
      - '8888:8888/tcp'
    restart: 'unless-stopped'
    # change if you don't want satisfactory hogging compute
    ulimits:
      nice:
        soft: -20
        hard: -20
    environment:
      ALWAYS_UPDATE_ON_START: ${ALWAYS_UPDATE_ON_START:-true}
      EXPERIMENTAL_BRANCH: ${EXPERIMENTAL_BRANCH:-false}
      PUID: ${PUID:-1001}
      PGID: ${PGID:-1001}
      CPU_CORE_COUNT: ${CPU_CORE_COUNT:-4}
      SERVER_NICENESS: ${SERVER_NICENESS:-0}
      EXTRA_PARAMS: >
        -log
        -unattended
        -ini:Engine:[HTTPServer.Listeners]:DefaultBindAddress=any
    volumes:
      - './satisfactory-data:/satisfactory'
      - './config:/home/steam/.config/Epic'
      - './fex-data:/home/steam/.fex-emu'
    stdin_open: true
    tty: true
    entrypoint: /home/steam/init-server.sh
```

1. **Port Access and Forwarding**:  
   On your router (or Oracle Cloud Security List), open the ports 7777 TCP/UDP and 8888 TCP (or respective to your other port choosing). They are the default ports for a Satisfactory server.

   DOCKER WILL BYPASS UFW, so you will not need for any firewall rules.

Once you finish step 3, congrats! The server is now ready to be used. You can start the server up by doing `sudo docker compose up -d`

[FEX](https://github.com/FEX-Emu/FEX) hella goated, yall should check it out
