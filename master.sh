#!/bin/bash

#edit this lines:
#username for the console:
PUPPET_PE_CONSOLEADMIN='admin@puppetlabs.com'
#password for the console:
PUPPET_PE_CONSOLEPWD='password'

PUPPET_PE_VERSION="3.3.2"



RESULTS_FILE='/tmp/puppet_bootstrap_output'
S3_BASE='https://s3.amazonaws.com/pe-builds/released/'

function check_exit_status() {
  if [ ! -f $RESULTS_FILE ]; then
    echo '1' > $RESULTS_FILE
  fi
}

trap check_exit_status INT TERM EXIT

function write_masteranswers() {
  cat > /opt/masteranswers.txt << ANSWERS
q_all_in_one_install=y
q_backup_and_purge_old_configuration=n
q_backup_and_purge_old_database_directory=n
q_database_host=localhost
q_database_install=y
q_install=y
q_pe_database=y
q_puppet_cloud_install=y
q_puppet_enterpriseconsole_auth_password=$PUPPET_PE_CONSOLEPWD
q_puppet_enterpriseconsole_auth_user_email=$PUPPET_PE_CONSOLEADMIN
q_puppet_enterpriseconsole_httpd_port=443
q_puppet_enterpriseconsole_install=y
q_puppet_enterpriseconsole_master_hostname=$INTERNAL_HOSTNAME
q_puppet_enterpriseconsole_smtp_host=localhost
q_puppet_enterpriseconsole_smtp_password=
q_puppet_enterpriseconsole_smtp_port=25
q_puppet_enterpriseconsole_smtp_use_tls=n
q_puppet_enterpriseconsole_smtp_user_auth=n
q_puppet_enterpriseconsole_smtp_username=
q_puppet_symlinks_install=y
q_puppetagent_certname=$INTERNAL_HOSTNAME
q_puppetagent_install=y
q_puppetagent_server=$INTERNAL_HOSTNAME
q_puppetdb_hostname=$INTERNAL_HOSTNAME
q_puppetdb_install=y
q_puppetdb_port=8081
q_puppetmaster_certname=$INTERNAL_HOSTNAME
q_puppetmaster_dnsaltnames=$INTERNAL_HOSTNAME,puppet,$PUBLIC_HOSTNAME
q_puppetmaster_enterpriseconsole_hostname=localhost
q_puppetmaster_enterpriseconsole_port=443
q_puppetmaster_install=y
q_run_updtvpkg=n
q_vendor_packages_install=y
ANSWERS
}

function write_sitepp() {
  cat > /etc/puppetlabs/puppet/manifests/site.pp << SITEPP 
filebucket { 'main':
  server => \$servername,
  path   => false,
}

File { backup => 'main' }

Package { allow_virtual => false }

node default {
  include pe_mcollective
  include ntp
}
SITEPP
}

function install_puppetmaster() {
  if [ ! -d /opt/puppet-enterprise ]; then
    mkdir -p /opt/puppet-enterprise
  fi
  if [ ! -f /opt/puppet-enterprise/puppet-enterprise-installer ]; then
    case ${breed} in
      "redhat")
        ntpdate -u 0.north-america.pool.ntp.org 
        curl -s -o /opt/pe-installer.tar.gz "https://s3.amazonaws.com/pe-builds/released/$PUPPET_PE_VERSION/puppet-enterprise-$PUPPET_PE_VERSION-el-6-x86_64.tar.gz" ;;
      "debian")
        curl -s -o /opt/pe-installer.tar.gz "https://s3.amazonaws.com/pe-builds/released/$PUPPET_PE_VERSION/puppet-enterprise-$PUPPET_PE_VERSION-debian-7-amd64.tar.gz" ;;
    esac
    #Drop installer in predictable location
    tar --extract --file=/opt/pe-installer.tar.gz --strip-components=1 --directory=/opt/puppet-enterprise
  fi
  write_masteranswers
  /opt/puppet-enterprise/puppet-enterprise-installer -a /opt/masteranswers.txt
}

function download_modules() {
  /opt/puppet/bin/puppet module upgrade puppetlabs-stdlib
  if [ -n $1 ]; then
    MODULE_LIST=`echo "$1" | sed 's/,/ /g'`
    for i in $MODULE_LIST; do /opt/puppet/bin/puppet module install --force $i ; done;
  fi
}

function clone_modules() {
  if [ -n "$1" ]; then
    #get git, regardless of platform
    apt-get install -y git-core 2>/dev/null || yum install -y git 2>/dev/null
    pushd /etc/puppetlabs/puppet/modules
    MODULE_LIST=`echo "$1" | sed 's/,/ /g'`
    for i in $MODULE_LIST; do
      MODULE=`echo "$i" | sed 's/#/ /'`
      if [ ! -d `echo $MODULE | cut -d' ' -f2` ]; then
        git clone $MODULE ;
      fi
    done;
    popd
  fi
}

function classify_master () {
  declare -a class_array=($PUPPET_PE_CLASSES)
  for class in ${class_array[@]}; do
    /opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production nodeclass:add["${class}",'skip']
    /opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production node:addclass[`hostname -f`,"${class}"]
  done
}

function provision_puppet() {
  if [ -f /etc/redhat-release ]; then
    export breed='redhat'
  elif [ -f /etc/debian_version ]; then
    export breed='debian'
  else
    echo "This OS is not supported by Puppet Cloud Provisioner"
    exit 1
  fi
  
  # For more on metadata, see https://developers.google.com/compute/docs/metadata
  MD="http://169.254.169.254/latest/meta-data/"
  PUBLIC_HOSTNAME=$(curl -fs $MD/public-hostname)
  INTERNAL_HOSTNAME=$(curl -fs $MD/hostname)

  install_puppetmaster
  download_modules "puppetlabs-ntp,puppetlabs-apache"
  clone_modules    "$PUPPET_REPOS"
  classify_master
  write_sitepp
  yum install -y git 2>/dev/null
  cd /etc/puppetlabs/puppet/modules/; git clone https://github.com/mrzarquon/ec2facts.git
 
  echo "*" > /etc/puppetlabs/puppet/autosign.conf

  /opt/puppet/bin/puppet agent --onetime --no-daemonize --color=false --verbose

  echo $? > $RESULTS_FILE
  echo "Puppet installation finished!"
  exit 0
}

provision_puppet