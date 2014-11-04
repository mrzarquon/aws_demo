#!/bin/bash

#formats remaining space on a rhel 6 vm and mounts it as /opt

make_partition {
  parted -s "$1" unit s mkpart primary "$2" "$3"
}

get_partition {
  echo $(parted /dev/xvda unit s print free | grep 'Free Space' | tail -n 1)
}

format_partition {
  partx -v -a /dev/xvda
  mkfs.ext4 /dev/xvda2
  mount /dev/xvda2 /opt
  echo "/dev/xvda2              /opt                    ext4    defaults        0 2" >> /etc/fstab
}

make_partition /dev/xvda $(parted /dev/xvda unit s print free | grep 'Free Space' | tail -n 1)
format_partition
