filebucket { 'main':
  server => $servername,
  path   => false,
}

File { backup => 'main' }

Package { allow_virtual => false }

node default {
  include pe_mcollective
  include ntp
}
