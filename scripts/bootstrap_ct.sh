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
    apt-get install -y unzip whois jq build-essential unzip python3 python3-pip dos2unix
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


fix_eth1_static_ip() {

  # There's a fun issue where dhclient keeps messing with eth1 despite the fact
  # that eth1 has a static IP set. We workaround this by setting a static DHCP lease.
  echo -e 'interface "eth1" {
    send host-name = gethostname();
    send dhcp-requested-address 192.168.38.105;
  }' >> /etc/dhcp/dhclient.conf
  service networking restart
  # Fix eth1 if the IP isn't set correctly
  ETH1_IP=$(ifconfig eth1 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
  if [ "$ETH1_IP" != "192.168.38.10" ]; then
    echo "Incorrect IP Address settings detected. Attempting to fix."
    ifdown eth1
    ip addr flush dev eth1
    ifup eth1
    ETH1_IP=$(ifconfig eth1 | grep 'inet addr' | cut -d ':' -f 2 | cut -d ' ' -f 1)
    if [ "$ETH1_IP" == "192.168.38.10" ]; then
      echo "[$(date +%H:%M:%S)]: The static IP has been fixed and set to 192.168.38.10"
    else
      echo "[$(date +%H:%M:%S)]: Failed to fix the broken static IP for eth1. Exiting because this will cause problems with other VMs."
      exit 1
    fi
  fi
}

install_services(){
  #move the service files from staging to the services location
  if [ -f "/opt/ControlTower/covenantc2.service" ]; then
    sudo mv /opt/ControlTower/covenantc2.service /lib/systemd/system/
    sudo chmod 644 /lib/systemd/system/covenantc2.service
    sudo systemctl start covenantc2
    sudo systemctl enable covenantc2
  else
    echo "ERROR: CovenantC2 service file missing."
  fi

}
enable_sshd(){
  sudo cp /opt/ControlTower/sshd_config /etc/ssh/
  sudo systemctl restart sshd

}

main() {
  #fix_eth1_static_ip
  goto_root
  apt_update
  enable_sshd
  install_basics
  install_covenant
  install_caldera
  install_services
}

main
exit 0
