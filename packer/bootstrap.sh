#!/bin/bash
set -ex

function export_image() {
  image_name=$1
  export_name=$2
  shift; shift
  CONTAINER_ID=$(docker run -d "$image_name" "$@")
  docker wait "$CONTAINER_ID"
  docker export -o "$export_name".tar "$CONTAINER_ID"
  docker rm "$CONTAINER_ID"
}

function ensure_sudo() {
  if [ "$(id -u)" -ne 0 ]; then
      echo "You must run this script as root. Attempting to sudo" 1>&2
      exit 1
  fi
}

function install_docker() {
  apt-get update
  apt-get install ca-certificates curl gnupg
  if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
  fi
  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi

  apt-get update
  apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  apt-get -y install stress python3-dev build-essential cmake htop python3-pip git
}

function system_config() {
  # Include the memory and memsw cgroups
  sed -i.bak 's|^kernel.*$|\0 cgroup_enable=memory swapaccount=1|' /boot/grub/menu.lst
  sed -i -r 's|GRUB_CMDLINE_LINUX="(.*)"|GRUB_CMDLINE_LINUX="\1 cgroup_enable=memory swapaccount=1"|' /etc/default/grub
  update-grub
}

function docker_config() {
# Configure Docker to use overlayfs
cat - > /etc/docker/daemon.json <<'EOF'
{
  "storage-driver": "overlay2"
}
EOF
# restart docker (to use overlay)
systemctl restart docker

usermod -G docker -a ubuntu
}

function fetch_images() {
  # Fetch images
  mkdir -p /workshop/images
  pushd /workshop/images
  export_image ubuntu:trusty ubuntu-export /bin/bash -c 'apt-get update && apt-get install -y python stress'
  export_image busybox busybox /bin/true
  cp /vagrant/03_pivot_root/breakout.py ./
  chmod +x breakout.py
  tar cf ubuntu.tar breakout.py
  tar Af ubuntu.tar ubuntu-export.tar
  rm breakout.py ubuntu-export.tar
  popd
}

function init_env() {
  cd /vagrant
  python3 setup.py install
  [[ -f requirements.txt ]] && pip3 install -r requirements.txt
  ln -s /usr/bin/python3 /usr/bin/python
}

function main() {
  ensure_sudo
  # Wait for cloud-init
  sleep 10
  install_docker
#  system_config
  docker_config
  fetch_images
  init_env
  echo "finished"
}

main
