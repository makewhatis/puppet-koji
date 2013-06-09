
class koji::web(
  $auth           = undef,
  $realm          = undef,
  $clientca_crt   = undef,
  $serverca_crt   = undef,
  $kojiweb_pem    = undef,
) inherits koji::params {
  # Require the Apache and mod_ssl packages.
  # For some reason, when I do this, I can't notify => Service['httpd'].
  # Puppet complains about cyclical deps.
  #Class['httpd'] -> Class['koji::hub']

  package { 'koji-web': ensure => installed }

  file { '/etc/httpd/conf.d/kojiweb.conf':
    content       => template('koji/web/kojiweb.conf.erb'),
    notify        => Service['httpd'],
    require       => Package['koji-web'],
  }


  case $auth {
    kerberos: {
      if( $realm == 'NONE' ) {
        fail('If you use Kerberos authentication, you must specify a $realm.')
      }
      class {'koji::web::kerberos': }
    }
    ssl: { 
      file { '/etc/kojiweb/clientca.crt':
        ensure        => present,
        source        => $clientca_crt,
        require       => Package['koji-web'],
      }

      file {'/etc/kojiweb/serverca.crt':
        ensure        => present,
        source        => $serverca_crt,
        require       => Package['koji-web'],
      }

      file {'/etc/kojiweb/client.crt':
        ensure        => present,
        source        => $kojiweb_pem,
        require       => Package['koji-web'],
      }
    }
    default: { fail('Unrecognized auth type for DB.') }
  }
}

class koji::web::kerberos {
  # Koji-web's keytab.
  file { '/etc/kojiweb/web.keytab':
    ensure => present,
    owner => 'root', group => 'apache',
    mode => '640',
    notify => Service['httpd'],
    require => Package['koji-web'],
  }
  # mod_auth_kerb's keytab.
  file { '/etc/httpd/http.keytab':
    ensure => present,
    owner => 'root', group => 'apache',
    mode => '640',
    notify => Service['httpd'],
  }
}
