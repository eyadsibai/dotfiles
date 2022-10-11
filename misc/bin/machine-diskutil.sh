#!/usr/bin/env sh
# @see http://stackoverflow.com/questions/30040708/how-to-mount-local-volumes-in-docker-machine
# @see https://github.com/boot2docker/boot2docker/blob/master/doc/FAQ.md

################################################################################
# Dependency Section                                                           #
#                                                                              #
################################################################################
check_deps() {
  ## Make sure commands are available
  local name
  for name in docker-machine VBoxManage grep ; do
    type $name  > /dev/null 2>&1
    if [ $? -eq 1 ] ; then
      echo "Error: Command \`$name\` not found,"
      echo "make sure it is available from your \`\$PATH\`"
      exit 1
    fi
  done
}


################################################################################
# Helper Functions                                                             #
#                                                                              #
################################################################################
volume_exists() {
  if [ ! -d $volume ] ; then
    echo "Error: The volume \`$volume\` does not exist,"
    echo "make sure to specify the correct volume path"
    exit 1
  fi
}


################################################################################
# Machine Helper Functions                                                     #
#                                                                              #
################################################################################
machine_exists() {
  docker-machine ls | grep "$machine" > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Error: The docker machine \`$machine\` does not exist,"
    echo "make sure to specify the correct docker machine."
    exit 2
  fi
}

machine_stop() {
  docker-machine status $machine | grep -E -i 'stopped' > /dev/null 2>&1
  if [ $? -ne 1 ] ; then
    return
  fi

  echo "Info: Attempting to stop the docker-machine \`$machine\`."
  echo "> docker-machine stop $machine"
  docker-machine stop $machine
  if [ $? -ne 0 ] ; then
    echo "Error: Failed to stop the docker-machine \`$machine\`."
    exit 3
  fi
  echo "[OK]"
}

machine_start() {
  docker-machine status $machine | grep -E -i 'running' > /dev/null 2>&1
  if [ $? -ne 1 ] ; then
    return
  fi

  echo "Info: Attempting to start the docker-machine \`$machine\`."
  echo "> docker-machine start $machine"
  docker-machine start $machine
  if [ $? -ne 0 ] ; then
    echo "Error: Failed to start the docker-machine \`$machine\`."
    exit 4
  fi
  echo "[OK]"
}

machine_mount_volume() {
  echo "Info: Attempting to mount the volume \`$volume\`"
  echo "> docker-machine ssh $machine \"sudo mkdir -p $volume\""
  docker-machine ssh $machine "sudo mkdir -p $volume"

  # create boot point
  if [ $? -ne 0 ] ; then
    echo "Error: Could not create the directory \`$volume\`"
    exit 5
  fi
  echo "[OK]"

  # mount volume
  local args="sudo mount -t vboxsf -o defaults,uid=\`id -u docker\`,gid=\`id -g docker\` $volume $volume"
  echo "> docker-machine ssh $machine \"$args\""
  docker-machine ssh $machine "$args"
  if [ $? -ne 0 ] ; then
    echo "Error: Could not mount the volume \`$volume\`"
    exit 5
  fi
  echo "[OK]"
}

machine_unmount_volume() {
  # if the the shared folder exists remove it
  docker machine ssh "sudo ls -l $volume" > /dev/null 2>&1
  if [ $? -ne 1 ] ; then
    return
  fi

  echo "Info: Attempting to remove the mount point \`$volume\`"
  local args="sudo rm -rf $volume"
  echo "> docker-machine ssh $machine $args"
  docker-machine ssh $machine $args
  if [ $? -ne 0 ] ; then
    echo "Warning: Could not remove the mount point \`$volume\` properly"
  fi

  echo "[OK]"
}

machine_make_volume_bootable() {
  echo "Info: Attempting to make the volume \`$volume\` automountable"

  local dir='/var/lib/boot2docker'
  docker-machine ssh $machine "sudo ls $dir" > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Error: Could not make the \`$volume\` automountable,"
    echo "the expected \`$dir\` does not exist."
    exit 1
  fi

  local file="${dir}/bootlocal.sh"

  # create the file if it does not exist
  docker-machine ssh $machine "sudo ls $file" > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    # create file
    # make executable
    # add she-bang
    docker-machine ssh $machine "sudo touch $file"
    docker-machine ssh $machine "sudo chmod +x $file"
    docker-machine ssh $machine "echo \"#!/usr/bin/env sh\" | sudo tee $file" > /dev/null 2>&1
  fi

  # only append if the entry does not already exist in the file
  docker-machine ssh $machine "sudo cat $file | grep -E -i $volume" > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    # set make mnt dir
    # set mount <shared-folder> <mnt dir>
    docker-machine ssh $machine "echo \"mkdir -p $volume\" | sudo tee -a $file" > /dev/null 2>&1
    docker-machine ssh $machine "echo \"mount -t vboxsf -o defaults,uid=\`id -u docker\`,gid=\`id -g docker\` $volume $volume\" | sudo tee -a $file" > /dev/null 2>&1
  fi
  echo "[OK]"

  echo "Info: \`$file\` configuration is the following:"
  docker-machine ssh $machine "sudo cat $file"

  echo "[OK]"
}

machine_unmake_volume_bootable() {
  echo "Info: Attempting to unmake the volume \`$volume\` automountable"

  local file="/var/lib/boot2docker/bootlocal.sh"
  docker-machine ssh $machine "sudo ls $file" > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "Warning: the expected \`$file\` does not exist,"
    echo "> no startup entries for automount to remove".
    echo "[OK]"
    return
  fi

  local total=$(docker-machine ssh $machine "sudo cat $file | wc -l" | xargs)
  local lines=$(docker-machine ssh $machine "sudo tail -n $(expr $total - 1) $file | grep -E -v $volume" | xargs)

  # add she-bang
  # add lines
  docker-machine ssh $machine "echo \"#!/usr/bin/env sh\" | sudo tee $file" > /dev/null 2>&1
  docker-machine ssh $machine "echo \"$lines\" | sudo tee -a $file" > /dev/null 2>&1
  echo "[OK]"

  docker-machine ssh $machine "sudo cat $file | grep -E -i '(mkdir|mount)" > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "Info: after the changes the configuration for the file \`$file\`,"
    echo "is the following:"
    docker-machine ssh $machine "sudo cat $file"
  else
    docker-machine ssh $machine "sudo rm -f $file"
    echo "Info: after the changes the configuration for the file \`$file\`,"
    echo "had no entries and was removed."
  fi

  echo "[OK]"
}


################################################################################
# Virtualbox Helper Functions                                                  #
#                                                                              #
################################################################################
vbox_volume_exists() {
  VBoxManage showvminfo $machine | grep $volume > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    echo "Error: The shared folder \`$volume\` already exists on the docker machine,"
    echo "please unmount it first."
    exit 1
  fi
}

vbox_volume_add() {
  echo "Info: Attempting to add the volume \`$volume\` as a sharedfolder,"
  echo "to the docker machine \`$machine\`"

  local args="--automount --name $volume --hostpath $volume"
  echo "> VBoxManage sharedfolder add $machine $args"
  VBoxManage sharedfolder add $machine $args
  if [ $? -ne 0 ] ; then
    log "Error: Failed to add the shared folder \`$volume\`."
    exit 1
  fi

  echo "[OK]"
}

vbox_volume_remove() {
  echo "Info: Attempting to remove the volume \`$volume\` as sharedfolder,"
  echo "from the docker machine \`$machine\`"
  VBoxManage showvminfo $machine | grep -E -i $volume > /dev/null 2>&1
  if [ $? -ne 0 ] ; then
    echo "> no shared folder with name \`$volume\` to remove"
    echo "[OK]"
    return
  fi

  local args="--name $volume"
  echo "> VBoxManage sharedfolder remove $machine $args"
  VBoxManage sharedfolder remove $machine $args
  if [ $? -ne 0 ] ; then
    echo "Warning: could not remove the shared folder \`$volume\` properly"
  fi
  echo "[OK]"
}


################################################################################
# Mount Section                                                                #
#                                                                              #
################################################################################
mount_print_help() {
  cat <<EOF
Mount a disk as a shared folder to a docker machine.

Usage: mount [MACHINE] [VOLUME]

Arguments:
  MACHINE  The name of the machine to mount the volume path.
  VOLUME   The path to the volume to mount.
EOF
}

mount_parse_args() {
  # ask for help
  if [ "$1" = '-h' ] || [ "$1" = '--help' ] ; then
    mount_print_help
    exit 0
  fi

  # too few arguments
  if [ $# -lt 2 ] ; then
    mount_print_help
    exit 0
  fi

  machine=$1
  volume=$(echo $2 | sed "s,/$,," | xargs)
}

mount_print_header() {
  cat <<EOF
##########################
# MACHINE DISKUTIL MOUNT #
##########################
EOF
}

mount_run() {
  machine_exists
  volume_exists
  vbox_volume_exists

  machine_stop
  vbox_volume_add
  machine_start
  machine_mount_volume
  machine_make_volume_bootable
}

mount() {
  mount_parse_args $@

  mount_print_header
  mount_run
}


################################################################################
# Unmount Section                                                              #
#                                                                              #
################################################################################
unmount_print_help() {
  cat <<EOF
Unmount a disk that has been mounted as shared folder by this script.

Usage: unmount [MACHINE] [VOLUME]

Arguments:
  MACHINE  The name of the machine to unmount the volume path from.
  VOLUME   The path to the volume to unmount.
EOF
}

unmount_parse_args() {
  if [ "$1" = '-h' ] || [ "$1" = '--help' ] ; then
    unmount_print_help
    exit 0
  fi

  # too few arguments
  if [ $# -lt 2 ] ; then
    unmount_print_help
    exit 0
  fi

  machine=$1
  volume=$(echo $2 | sed "s,/$,," | xargs)
}

unmount_print_header() {
  cat <<EOF
############################
# MACHINE DISKUTIL UNMOUNT #
############################
EOF
}

unmount_run() {
  local restart=0
  machine_exists

  docker-machine status $machine | grep -E -i 'running' > /dev/null 2>&1
  if [ $? -eq 0 ] ; then
    restart=1
    machine_stop
  fi

  vbox_volume_remove
  machine_start

  machine_unmount_volume
  machine_unmake_volume_bootable

  if [ $restart -ne 1 ] ; then
    machine_stop
  fi
}

unmount() {
  unmount_parse_args $@

  unmount_print_header
  unmount_run
}

################################################################################
# MAIN ENTRYPOINT                                                              #
#                                                                              #
#   1. Parse command                                                           #
#   2. Run command                                                             #
#     2.1 Print help command if cmd equals 'help'                              #
#     2.2 Run the command if it's one of [build, tag, login, push]             #
#     2.3 Print command not found if none of the above.                        #
#                                                                              #
################################################################################
main_print_help() {
  cat<<EOF
Docker Machine Disk utitlity for mounting / unmounting shared folders.

Usage:
  machine-diskutil [COMMAND] [ARGS....]
  machine-diskutil -h|--help

Commands:
  mount   Mount a volume as a shared folder on the virtual machine.
  unmount Unmount a shared folder from the virtual machine.
EOF
}

main_parse_command() {
  if [ $# -eq 0 ] ; then
    cmd='help'
    return
  fi

  if [ "$1" = '-h' ] || [ "$1" = '--help' ] ; then
    cmd='help'
    return
  fi

  cmd=$1
}

main_run_command() {
  case $cmd in
    help)
      main_print_help
      return
      ;;
    mount|unmount)
      ;;
    *)
      main_print_cmd_not_found
      exit 1
      ;;
  esac

  check_deps
  shift
  $cmd $@
}

main_parse_command $@
main_run_command $@
