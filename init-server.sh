#!/bin/bash

SATISFACTORY_DIR="/satisfactory"
STEAMCMD_DIR="/home/steam/Steam"
export FEX_ROOTFS="/home/steam/.fex-emu/RootFS/Ubuntu_22_04"

# permission check
if [ "$(id -u)" -eq 0 ]; then
  echo "Container started as root. Applying PUID/PGID and dropping privileges..."
  
  PUID=${PUID:-1001}
  PGID=${PGID:-1001}
  
  groupmod -o -g "$PGID" steam
  usermod -o -u "$PUID" steam
  
  mkdir -p "$SATISFACTORY_DIR" /home/steam/.fex-emu
  chown -R steam:steam "$SATISFACTORY_DIR" /home/steam
  
  exec gosu steam "$0" "$@"
fi

# downloading fex and setting it up for usage
setup_fex() {
  echo "Setting up FEX"
  rm -f /tmp/*FEXServer.Socket*

  if [ ! -d "/home/steam/.fex-emu/RootFS/Ubuntu_22_04" ]; then
    echo "RootFS not found, grabbing Ubuntu 22.04 RootFS"
    mkdir -p /home/steam/.fex-emu/RootFS
    rm -f /home/steam/.fex-emu/RootFS/*.sqsh

		# this is to get all the options for rootfs, so we know
		# exactly where Ubuntu 22.04 (SquashFS) is and we can
		# consistently get it
    ROOTFS_URL=$(curl -s https://rootfs.fex-emu.gg/RootFS_links.json | jq -r '.v1["Ubuntu 22.04 (SquashFS)"].URL')

    if [ "$ROOTFS_URL" == "null" ] || [ -z "$ROOTFS_URL" ]; then
      echo "ERROR: Could not locate the URL for Ubuntu 22.04 (SquashFS)"
      exit 1
    fi

    # download rootfs
    echo "Downloading and extracting RootFS from: $ROOTFS_URL"
    curl -L "$ROOTFS_URL" -o /home/steam/.fex-emu/RootFS/Ubuntu_22_04.sqsh

    # extract rootfs
    unsquashfs -f -d /home/steam/.fex-emu/RootFS/Ubuntu_22_04 /home/steam/.fex-emu/RootFS/Ubuntu_22_04.sqsh

    # remove sqsh file
    rm /home/steam/.fex-emu/RootFS/Ubuntu_22_04.sqsh
  else
    echo "FEX RootFS found. Skipping installation"
  fi
}

#steamcmd initialization
setup_steamcmd() {
  echo "Initializing SteamCMD"
  cd "$STEAMCMD_DIR" || exit 1

  FEXBash './steamcmd.sh +quit'

  mkdir -p /home/steam/.steam/sdk64
  ln -sfn "$STEAMCMD_DIR/linux64/steamclient.so" /home/steam/.steam/sdk64/steamclient.so
}

update_game_files() {
  echo "Running SteamCMD update for 1690800 (Satisfactory)"
  cd "$STEAMCMD_DIR" || exit 1

	# env that determines if the experimental branch should be installed
  local beta_flag=""
  if [ "${EXPERIMENTAL_BRANCH:-false}" == "true" ]; then
    echo "Targeting Experimental Branch..."
    beta_flag="-beta experimental"
  fi

  echo "Executing SteamCMD..."

  if FEXBash "./steamcmd.sh +@sSteamCmdForcePlatformBitness 64 +force_install_dir \"$SATISFACTORY_DIR\" +login anonymous +app_update 1690800 $beta_flag validate +quit"; then
    echo "SteamCMD update successful."
  else
    echo "WARNING: SteamCMD encountered an error during the update. The server will still attempt bootup."
  fi
}

manage_game_server() {
  echo "Checking server files"
  local appmanifest="$SATISFACTORY_DIR/steamapps/appmanifest_1690800.acf"

  # Check if a core file or manifest is completely missing
  if [ ! -f "$SATISFACTORY_DIR/FactoryServer.sh" ] || [ ! -f "$appmanifest" ]; then
    echo "Server executable or appmanifest not found! Installing fresh server..."
    update_game_files
    return
  fi

  if [ "$ALWAYS_UPDATE_ON_START" == "true" ]; then
    echo "Querying Steam API for Satisfactory build ID"
    local local_build
    local_build=$(grep -Po '"buildid"\s+"\K[0-9]+' "$appmanifest")
    
    if [ -z "$local_build" ]; then
      echo "WARNING: Could not parse local build ID. Assuming build 0 to force safe update."
      local_build="0"
    fi

    # if experimental, check experimental instead
    local target_branch="public"
    if [ "${EXPERIMENTAL_BRANCH:-false}" == "true" ]; then
        target_branch="experimental"
    fi

    local remote_build
    remote_build=$(curl -s https://api.steamcmd.net/v1/info/1690800 | jq -r ".data[\"1690800\"].depots.branches.$target_branch.buildid")

    if [ -z "$remote_build" ] || [ "$remote_build" == "null" ]; then
      echo "WARNING: Failed to fetch remote Build ID from Steam API. Skipping update check to prevent forced download."
    elif [ "$local_build" != "$remote_build" ]; then
      echo "Updating: Local Build: $local_build | Remote Build: $remote_build"
      update_game_files
    else
      echo "Server is up to date: $local_build"
    fi
  fi
}

start_server() {
  echo "Starting Satisfactory Dedicated Server..."
  cd "$SATISFACTORY_DIR" || exit 1
  
  pkill -9 FEXServer || true

  local allowed_cpus
  allowed_cpus=$(taskset -cp $$ | awk -F': ' '{print $2}')
  echo "Server allowed for $allowed_cpus cores"

  local priority=${SERVER_NICENESS:-0}
  
  # FactoryServer.sh handles the core Unreal Engine startup params
  local sat_cmd="./FactoryServer.sh $EXTRA_PARAMS"

  local exec_string="exec nice -n $priority taskset -c $allowed_cpus FEXBash \"$sat_cmd\""

  echo "Exec args: $exec_string"
  eval "$exec_string"
}

main() {
  setup_fex
  setup_steamcmd
  manage_game_server
  start_server
}

main