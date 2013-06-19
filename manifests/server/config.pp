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
  $log_level,
  $bind_anon,
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

  if($enable_motd) {
    motd::register { "ldap::server::${type}": }
  }

  package { $ldap::params::server_package:
    ensure => $ensure,
  }

  service { $ldap::params::service:
    ensure     => running,
    enable     => true,
    pattern    => $ldap::params::server_pattern,
    require    => [
      Package[$ldap::params::server_package],
      File["${ldap::params::server_path}"],
      ],
  }

  File {
    mode    => '0640',
    owner   => $ldap::params::server_owner,
    group   => $ldap::params::server_group,
  }

  file { 'server_config':
    ensure  => $ensure,
    content => template("ldap/${ldap::params::server_config}.erb"),
    path    => "${ldap::params::prefix}/${ldap::params::server_config}",
    notify  => Service[$ldap::params::service],
    require => Package[$ldap::params::server_package],
  }

  # Conditionally set up SSL.
  if $ssl {
    $msg_prefix = $ldap::params::ssl_msg_prefix
    $msg_suffix = $ldap::params::ssl_msg_suffix

    # Fail early.
    if !$ssl_ca   { fail("${msg_prefix} ssl_ca   ${msg_suffix}") }
    if !$ssl_cert { fail("${msg_prefix} ssl_cert ${msg_suffix}") }
    if !$ssl_key  { fail("${msg_prefix} ssl_key  ${msg_suffix}") }

    # Normalize a couple parameters into this class's namespace.
    $ssl_prefix   = $ldap::params::ssl_prefix
    $cacertdir    = $ldap::params::cacertdir

    # Allow users to define their own puppet resource or simple filename.
    if ( $ssl_ca =~ /^puppet\:/ ) {
      $ssl_ca_src = $ssl_ca
      $ssl_ca_dst = inline_template(
        "<%= ssl_prefix %>/<%= File.basename(ssl_ca) %>")
    } else {
      $ssl_ca_src = "puppet:///files/ldap/${ssl_ca}"
      $ssl_ca_dst = "${cacertdir}/${ssl_ca}"
    }
    file { 'ssl_ca':
      ensure  => $ensure,
      source  => $ssl_ca_src,
      path    => $ssl_ca_dst,
    }
    # Allow users to define their own puppet resource or simple filename.
    if ( $ssl_key =~ /^puppet\:/ ) {
      $ssl_key_src = $ssl_key
      $ssl_key_dst = inline_template(
        "<%= ssl_prefix %>/<%= File.basename(ssl_key) %>")
    } else {
      $ssl_key_src = "puppet:///files/ldap/${ssl_key}"
      $ssl_key_dst = "${cacertdir}/${ssl_key}"
    }
    file { 'ssl_key':
      ensure  => $ensure,
      source  => $ssl_key_src,
      path    => $ssl_key_dst,
      require => File['ssl_ca'],
    }
    # Allow users to define their own puppet resource or simple filename.
    if ( $ssl_cert =~ /^puppet\:/ ) {
      $ssl_cert_src = $ssl_cert
      $ssl_cert_dst = inline_template(
        "<%= ssl_prefix %>/<%= File.basename(ssl_cert) %>")
    } else {
      $ssl_cert_src = "puppet:///files/ldap/${ssl_cert}"
      $ssl_cert_dst = "${cacertdir}/${ssl_cert}"
    }
    file { "ssl_cert":
      ensure  => $ensure,
      source  => $ssl_cert_src,
      path    => $ssl_cert_dst,
      require => File['ssl_key'],
      before  => File['server_config'],
    }

    # Symlink certificate to a filename based on the cert hash.
    $target = "${cacertdir}/$(openssl x509 -noout -hash -in ${ssl_cert_dst}).0"
    exec { "Server certificate hash":
      command => "ln -s ${ssl_cert_dst} ${target}",
      unless  => "test -f ${target}",
      require => File['ssl_cert'],
    }
  }
}
