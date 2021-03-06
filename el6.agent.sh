#!/bin/bash

#change to internal hostname of the server provisioned in AWS with the master.sh script

PE_MASTER='internal-master-hostname.com'

if [ ! -d /etc/yum.repos.d ]; then
  mkdir -p /etc/yum.repos.d
fi

curl -sk https://${PE_MASTER}:8140/packages/current/el-6-x86_64.repo > /etc/yum.repos.d/el-6-x86_64.repo

yum -y install pe-agent

if [ ! -d /etc/puppetlabs/puppet ]; then
  mkdir -p /etc/puppetlabs/puppet
fi

declare -x PUPPET='/opt/puppet/bin/puppet'

$PUPPET config set server ${PE_MASTER} --section agent
$PUPPET config set environment production --section agent
$PUPPET config set certname $(curl -s http://169.254.169.254/latest/meta-data/instance-id) --section agent

$PUPPET resource service pe-puppet ensure=running enable=true

