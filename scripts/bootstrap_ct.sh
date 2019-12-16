#! /bin/bash

export DEBIAN_FRONTEND=noninteractive

apt_update() {
  echo "[$(date +%H:%M:%S)]: Running apt-get clean..."
  apt-get clean
  echo "[$(date +%H:%M:%S)]: Running apt-get update..."
  apt-get -qq update
  apt-get -qq install -y
}

install_basics() {
    echo "[$(date +%H:%M:%S)]: Installing base software packages..."
    apt-get install -y unzip whois jq build-essential unzip python3 python3-pip
}

install_covenant(){
  echo "[$(date +%H:%M:%S)]: Installing Covenant C2..."

  #Install dotnet from https://docs.microsoft.com/en-ca/dotnet/core/install/linux-package-manager-ubuntu-1904
  echo "[$(date +%H:%M:%S)]: Install DotNet 2.2 SDK..."
  cd /tmp
  wget -nv https://download.visualstudio.microsoft.com/download/pr/022d9abf-35f0-4fd5-8d1c-86056df76e89/477f1ebb70f314054129a9f51e9ec8ec/dotnet-sdk-2.2.207-linux-x64.tar.gz -O dotnet-sdk-2.2.207-linux-x64.tar.gz
  mkdir -p /opt/dotnet && tar zxf dotnet-sdk-2.2.207-linux-x64.tar.gz -C /opt/dotnet

  echo "export DOTNET_ROOT=/opt/dotnet" >>/home/vagrant/.bashrc
  echo "PATH=$PATH:/opt/dotnet" >> /home/vagrant/.bashrc

  export DOTNET_ROOT=/opt/dotnet
  export PATH=$PATH:/opt/dotnet



  #Install Covenant
  echo "[$(date +%H:%M:%S)]: Install Coveant from github..."

  cd /opt
  git clone --recurse-submodules https://github.com/cobbr/Covenant
  cd Covenant/Covenant

  echo "[$(date +%H:%M:%S)]: Building Covenant using DotNet..."
  dotnet build -v q

  echo "[$(date +%H:%M:%S)]: Starting Covenant C2..."
  dotnet run&

  echo "[$(date +%H:%M:%S)]: Covenant complete. Note: You will have to log in to create an initial user"

}

postinstall_tasks() {
  # Include Splunk and Bro in the PATH
  echo export PATH="$PATH:/opt/splunk/bin:/opt/bro/bin" >> ~/.bashrc
}
goto_root(){
  #goto_root
  echo "[$(date +%H:%M:%S)]: Going root..."
  sudo su -
}

install_caldera(){
  echo "-----------------------------------------------"
  echo "[$(date +%H:%M:%S)]: Installing MITRE Caldera"
  echo "-----------------------------------------------"
  echo "[$(date +%H:%M:%S)]: This will take a few minutes..."

  echo "[$(date +%H:%M:%S)]: Cloning repository..."
  sudo su -
  cd /opt
  git clone https://github.com/mitre/caldera.git --recursive --branch master
  cd caldera
  echo "[$(date +%H:%M:%S)]: Installing python dependencies..."

  pip3 install -r requirements.txt
  echo "[$(date +%H:%M:%S)]: Starting MITRE caldera"
  python3 server.py&
}

check_services(){
  # If the curl operation fails, we'll just leave the variable equal to 0;  1 means everything is good
  CALDERA_CHECK=$(curl -ks -m 2 http://192.168.38.10:8888/login | grep -c 'access' || echo "")
  if ["$CALDERA_CHECK" -lt 1]; then
    (echo >&2 "Warning: Caldera may not be functioning correctly")
  fi

}

main() {
  #fix_eth1_static_ip
  goto_root
  apt_update
  install_basics
  install_covenant
  install_caldera
  check_services
}

main
exit 0
