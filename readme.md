# Satisfactory Server on ARM64 using FEX
Thanks to [sa-shiro/Satisfactory-Dedicated-Server-ARM64-Docker](https://github.com/ayayrom/Satisfactory-Dedicated-Server-ARM64-Docker), they inspired this project. It is also an improved fork of their project.

---

## Getting Started

1. **Download or Clone Repository**:  
   You can download this repository by either the code button above or using  
   `git clone https://github.com/ayayrom/Satisfactory-Server-ARM-Docker.git`
   Next, you'll want to cd into it using this: `cd Satisfactory-Server-ARM-Docker`

2. **Environment Setup**:
   Before building, create your environment configuration file by copying the example by doing `cp .env.example .env` and edit the values as you wish.

3. **Build the Docker Image**:  
   This section will take about ~15 minutes to compile from source. If it goes beyond that, check to make sure the compilation isn't stuck.  
   Run the command **IF YOU ARE USING ORACLE CLOUD'S AMPERE**:
   ```
   sudo docker build -t satisfactory-arm64 -f Dockerfile .
   ```
   Run the command **IF YOU ARE USING SOMETHING ELSE**:
   ```
   sudo docker build -t satisfactory-arm64 -f Dockerfile.generic .
   ```

4. **Run the Docker Image**:
   Before you run the docker image, do this: `sudo chmod +x init-server.sh`
   To run the docker image, run the command:
   ```
   sudo docker compose up -d
   ```
   If you want to follow the logs after it is running, run the command:
   ```
   sudo docker compose logs -f
   ```

5. **Port Access and Forwarding**:  
   On your router (or Oracle Cloud Security List), open the ports 7777 TCP/UDP and 8888 TCP. They are the default ports for a Satisfactory server.

   DOCKER WILL BYPASS UFW, so you will not need for any firewall rules.

Once you finish step 5, congrats! The server is now ready to be used. 

[FEX](https://github.com/FEX-Emu/FEX) hella goated, yall should check it out
