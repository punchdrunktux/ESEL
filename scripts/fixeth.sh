#! /bin/bash

export DEBIAN_FRONTEND=noninteractive

fix_eth(){
  #tell grub to stop renaming the interfaces; use eth0, eth1, etc.
  echo 'GRUB_CMDLINE_LINUX="net.ifnames=0 biosdevname=0"' >>/etc/default/grub
}

fix_eth
exit 0
