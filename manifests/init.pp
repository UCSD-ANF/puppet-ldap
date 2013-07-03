# == Class: ldap
#
# Puppet module to manage client and server configuration for
# **OpenLdap**.
#
#
# === Parameters
#
#  [uri]
#    Ldap URI as a string. Multiple values can be set
#    separated by spaces ('ldap://ldapmaster ldap://ldapslave')
#    **Required**
#
#  [base]
#    Ldap base dn.
#    **Required**
#
#  [version]
#    Ldap version for the connecting client
#    *Optional* (defaults to 3)
#
#  [timelimit]
#    Time limit in seconds to use when performing searches
#    *Optional* (defaults to 30)
#
#  [bind_timelimit]
#    *Optional* (defaults to 30)
#
#  [idle_timelimit]
#    *Optional* (defaults to 30)
#
#  [binddn]
#    Default bind dn to use when performing ldap operations
#    *Optional* (defaults to false)
#
#  [bindpw]
#    Password for default bind dn
#    *Optional* (defaults to false)
#
#  [ssl]
#    Enable TLS/SSL negotiation with the server
#    *Optional* (defaults to false)
#
#  [ssl_ca]
#   Puppet resource to get your self-signed CA cert from, in .pem format.
#   If not provided, its assumed you've got a CA-signed cert signed by a
#   CA found in your OS's standard certficate bundle.
#   *Optional* (defaults to false)
#
#  [nsswitch]
#    If enabled (nsswitch => true) enables nsswitch to use
#    ldap as a backend for password, group and shadow databases.
#    *Requires*: https://github.com/torian/puppet-nsswitch.git (in alpha)
#    *Optional* (defaults to false)
#
#  [nss_passwd]
#    Search base for the passwd database. *base* will be appended.
#    *Optional* (defaults to false)
#
#  [nss_group]
#    Search base for the group database. *base* will be appended.
#    *Optional* (defaults to false)
#
#  [nss_shadow]
#    Search base for the shadow database. *base* will be appended.
#    *Optional* (defaults to false)
#
#  [pam]
#    If enabled (pam => true) enables pam module, which will
#    be setup to use pam_ldap, to enable authentication.
#    *Requires*: https://github.com/torian/puppet-pam.git (in alpha)
#    *Optional* (defaults to false)
#
#  [pam_att_login]
#    User's login attribute
#    *Optional* (defaults to *'uid'*)
#
#  [pam_att_member]
#    Member attribute to use when testing user's membership
#    *Optional* (defaults to *'member'*)
#
#  [pam_passwd]
#    Password hash algorithm
#    *Optional* (defaults to *'md5'*)
#
#  [pam_filter]
#    Filter to use when retrieving user information
#    *Optional* (defaults to *'objectClass=posixAccount'*)
#
#  [enable_motd]
#    Use motd to report the usage of this module.
#    *Requires*: https://github.com/torian/puppet-motd.git
#    *Optional* (defaults to false)
#
#  [ensure]
#    *Optional* (defaults to 'present')
#
#
# == Tested/Works on:
#   - Debian:    5.0   / 6.0   / 7.x
#   - RHEL       5.x   / 6.x
#   - CentOS     5.x   / 6.x
#   - OpenSuse:  11.x  / 12.x
#   - OVS:       2.1.1 / 2.1.5 / 2.2.0 / 3.0.2
#
#
# === Examples
#
# class { 'ldap':
#   uri  => 'ldap://ldapserver00 ldap://ldapserver01',
#   base => 'dc=suffix',
# }
#
# class { 'ldap':
#   uri  => 'ldap://ldapserver00',
#   base => 'dc=suffix',
#   ssl  => true,
#   ssl_ca => 'ldapserver00.pem'
# }
#
# class { 'ldap':
#   uri        => 'ldap://ldapserver00',
#   base       => 'dc=suffix',
#   ssl        => true,
#   ssl_ca => 'ldapserver00.pem'
#
#   nsswitch   => true,
#   nss_passwd => 'ou=users',
#   nss_shadow => 'ou=users',
#   nss_group  => 'ou=groups',
#
#   pam        => true,
# }
#
#
# === Authors
#
# Emiliano Castagnari ecastag@gmail.com (a.k.a. Torian)
#
#
# === Copyleft
#
# Copyleft (C) 2012 Emiliano Castagnari ecastag@gmail.com (a.k.a. Torian)
#
#
class ldap(
  $uri,
  $base,
  $version        = 3,
  $timelimit      = 30,
  $bind_timelimit = 30,
  $idle_timelimit = 60,
  $binddn         = false,
  $bindpw         = false,
  $ssl            = false,
  $ssl_ca         = false,

  $nsswitch       = false,
  $nss_passwd     = false,
  $nss_group      = false,
  $nss_shadow     = false,

  $pam            = false,
  $pam_att_login  = 'uid',
  $pam_att_member = 'member',
  $pam_passwd     = 'md5',
  $pam_filter     = 'objectClass=posixAccount',

  $enable_motd    = false,
  $ensure         = present,
) {

  include ldap::params

  if($enable_motd) {
    motd::register { 'ldap': }
  }

  package { $ldap::params::package:
    ensure => $ensure,
  }

  File {
    ensure  => $ensure,
    mode    => '0644',
    owner   => $ldap::params::owner,
    group   => $ldap::params::group,
  }

  # Conditionally set up SSL before we call any templates.
  if $ssl {
    # Normalize variable for template.
    $cacertdir = $ldap::params::cacertdir

    # ssl_ca is optional; we may have had a real CA sign our cert,
    # or installed our own CA cert already in cacertdir.
    if $ssl_ca {
      # Install ssl_ca virtually, in case we're a client and server.
      @ldap::ssl_ca {  $ssl_ca :
        ensure  => $ensure,
        require => File['client_config'],
      }
      realize( Ldap::Ssl_ca[$ssl_ca] )
    } else {
      warning('Not installing ssl_ca. Assuming your CA cert is in place.')
    }
  }

  $dirEnsure = $ensure ? {
    present => directory,
    default => absent,
  }
  file { $ldap::params::prefix :
    ensure  => $dirEnsure,
    require => Package[$ldap::params::package],
  }->
  file { 'client_config':
    content => template("ldap/${ldap::params::config}.erb"),
    require => File[$ldap::params::prefix],
    path    => "${ldap::params::prefix}/${ldap::params::config}",
  }

  # require module nsswitch
  if($nsswitch == true) {
    $module_type = $ensure ? {
      'present' => 'ldap',
      default   => 'none'
    }
    class { 'nsswitch':
      uri         => $uri,
      base        => $base,
      module_type => $module_type,
    }
  }

  # require module pam
  if($pam == true) {
    Class ['pam::pamd'] -> Class['ldap']
  }
}
