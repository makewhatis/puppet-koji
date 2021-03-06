
class koji::builder($auth, $hub, $allowed_scms, $realm) {
	package { 'koji-builder':
		ensure => installed,
	}
	service { 'kojid':
		ensure => running,
		enable => true,
		hasstatus => true,
		hasrestart => true,
		require => Package['koji-builder'],
	}
	file { '/etc/kojid/kojid.conf':
		ensure => present,
		content => template('koji/builder/kojid.conf.erb'),
		notify => Service['kojid'],
		require => Package['koji-builder'],
	}
	# Link to Koji-hub's CA, so kojid can properly verify it.
	file { '/etc/kojid/kojihubca.crt':
		ensure => link,
		target => '/etc/pki/tls/certs/cacert-class3.crt',
		require => Package['koji-builder'],
	}
	case $auth {
		kerberos: {
			if( $realm == 'NONE' ) {
				fail('If you use Kerberos authentication, you must specify a $realm.')
			}
			class {'koji::builder::kerberos': }
		}
		ssl: { fail('SSL auth not yet implemented.') }
		default: { fail('Unrecognized auth type for DB.') }
	}
}

class koji::builder::kerberos {
	# Koji-builder's keytab.
	file { '/etc/kojid/kojid.keytab':
		ensure => present,
		owner => 'root', group => 'kojibuilder',
		mode => '640',
		notify => Service['kojid'],
		require => Package['koji-builder'],
	}
}

# Use this class if the builder will access the SCM over SSH
class koji::builder::ssh {
	# Builder runs SCM command as root. Put SSH keys here if using an SCM over SSH.
	file { '/root/.ssh':
		ensure => directory,
		mode => '700',
		owner => 'root', group => 'root',
	}
	# Builder's private key
	file { '/root/.ssh/id_rsa':
		mode => '600',
		owner => 'root', group => 'root',
	}
	# SCM Host's public key
	sshkey { 'cvs.rpmfusion.org':
		ensure => present,
		key => 'AAAAB3NzaC1yc2EAAAABIwAAAQEAxQVhR8gzsWoY6ghHP+jqnMve6YZwsFbVhYYCQ1O5kYR8lwlmIXJZ9u0B0kvdU4SONjQe11OX8xihrwPei5Xcj2kEhTQFkeTsRR5ApbawMcmWyhwTeuUsiTd76CqNj/cEossc0wAqsVhZg397vDxrckxVLSpP2dCuHL4P4LP4clbc+rYKP7nnSL+ngBSQRSm+0UQhZu37KXb5tB3nSTsph6anzlTYIiTM6i29ShunNOGzeFwp7y7ospMmKhWZnfWjKA/O7IXYCYxb9gr/69cv8Q3IsRfMMhxxUnBbWLUQb4w5CZPhXFRtBr3hJcHDAWNISu0b19oQOXvmY6yZKa2pYw==',
		type => 'ssh-rsa',
	}
}
