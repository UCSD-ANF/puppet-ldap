# == Class: ldap::server::config
#
# This class is not called directly, but should be wrapped by
# master.pp or slave.pp.  See those files for variable definitions.
#
# Values with no defaults are common to master/slave manifests.
# Values with default undef belong either only to master or slave.
class ldap::server::config(
  $type,
  $enable_motd,
  $ensure,
  $suffix,
  $rootpw,
  $rootdn,
  $schema_inc,
  $modules_inc,
  $index_inc,
  $log_file,
  $log_level,
  $bind_anon,
  $ldap,
  $ldapi,
  $ssl,
  $ssl_ca,
  $ssl_cert,
  $ssl_key,
  $sync_binddn,
  $syncprov            = undef, # Master only
  $syncprov_checkpoint = undef, # Master only
  $syncprov_sessionlog = undef, # Master only
  $sync_attrs          = undef, # Slave only
  $sync_base           = undef, # Slave only
  $sync_bindpw         = undef, # Slave only
  $sync_filter         = undef, # Slave only
  $sync_interval       = undef, # Slave only
  $sync_provider       = undef, # Slave only
  $sync_rid            = undef, # Slave only
  $sync_scope          = undef, # Slave only
  $sync_type           = undef, # Slave only
  $sync_updatedn       = undef, # Slave only
) {

  include ldap::params

  if $type !~ /(master|slave)/ {
    fail("${name} expects type=master or type=slave.")
  }

  # Confirm we're at least running one service port.
  if $ldap == false and $ldapi == false and $ssl == false {
    fail("${name} needs at least one of ldap:// ldapi:// or ldaps:// to be on.")
  }

  if($enable_motd) {
    motd::register { "ldap::server::${type}": }
  }

  package { $ldap::params::server_package :
    ensure   => $ensure,
    provider => $ldap::params::package_provider,
  }

  service { $ldap::params::service :
    ensure     => running,
    enable     => true,
    pattern    => $ldap::params::server_pattern,
    require    => [
      Package[$ldap::params::server_package],
      File['server_config'],
      ],
  }

  File {
    mode    => '0640',
    owner   => $ldap::params::server_owner,
    group   => $ldap::params::server_group,
  }
  $dirEnsure = $ensure ? {
    present => directory,
    default => absent,
  }

  # Conditionally set up SSL before we call any templates.
  if $ssl {
    #Normalize variables for templates.
    $cacertdir  = $ldap::params::cacertdir
    $ssl_prefix = $ldap::params::ssl_prefix
    $msg_prefix = $ldap::params::ssl_msg_prefix
    $msg_suffix = $ldap::params::ssl_msg_suffix

    if !$ssl_cert { fail("${msg_prefix} ssl_cert ${msg_suffix}") }
    if !$ssl_key  { fail("${msg_prefix} ssl_key  ${msg_suffix}") }

    $ssl_slapd_cert = "${ssl_prefix}/slapd-cert.pem"
    $ssl_slapd_key  = "${ssl_prefix}/slapd-key.pem"

    file { $ssl_prefix :
      ensure => $dirEnsure,
      mode   => '0755',
    }->
    file { $ssl_slapd_cert :
      ensure => $ensure,
      mode   => '0644',
      source => $ssl_cert,
    }->
    file { $ssl_slapd_key :
      ensure  => $ensure,
      mode    => '0600',
      source  => $ssl_key,
      require => File['server_config'],
    }

    # ssl_ca is optional; we may have had a real CA sign our cert,
    # or installed our own CA cert already in cacertdir.
    if $ssl_ca {
      # Install CA cert virtually, in case we're a client and server.
      @ldap::ssl_ca { $ssl_ca :
        ensure  => $ensure,
        require => File['server_config'],
      }
      realize( Ldap::Ssl_ca[$ssl_ca] )
    } else {
      warning('Not installing ssl_ca. Assuming your CA cert is in place.')
    }
  }

  # Configure server.
  file { 'server_config':
    ensure  => $ensure,
    content => template("ldap/${ldap::params::server_config}.erb"),
    path    => "${ldap::params::prefix}/${ldap::params::server_config}",
    notify  => Service[$ldap::params::service],
    require => Package[$ldap::params::server_package],
  }

  ## Create default log dir?
  #file { '/var/log/slapd':
  #  ensure  => $dirEnsure,
  #  notify  => Service[$ldap::params::service],
  #  require => Package[$ldap::params::server_package],
  #}

  # Manage OS-specific defaults, if we can.
  if $ldap::params::slapd_defaults {
    # Normalize values to this class for template() calls.
    $slapd_var       = $ldap::params::slapd_var
    $slapd_defaults  = $ldap::params::slapd_defaults
    $slapd_ldap      = $ldap  ? { true  => 'yes', false => 'no', }
    $slapd_ldapi     = $ldapi ? { true  => 'yes', false => 'no', }
    $slapd_ldaps     = $ssl   ? { true  => 'yes', false => 'no', }
    $slapd_url_ldap  = $ldap  ? { true  => 'ldap:///',  false => '', }
    $slapd_url_ldapi = $ldapi ? { true  => 'ldapi:///', false => '', }
    $slapd_url_ldaps = $ssl   ? { true  => 'ldaps:///', false => '', }
    $slapd_url       = join(
      [$slapd_url_ldap,$slapd_url_ldapi,$slapd_url_ldaps,], ' ')

    file { $slapd_defaults :
      ensure  => $ensure,
      content => template('ldap/slapd_defaults.erb'),
      notify  => Service[$ldap::params::service],
      require => Package[$ldap::params::server_package],
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
    }
  }
}
