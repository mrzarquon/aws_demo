host { 'awsmaster.puppetlabs.demo':
  ensure => present,
  ip     => '54.68.175.82',
}
host { 'awssplunk.puppetlabs.demo':
  ensure => present,
  ip     => '54.69.81.197',
}
