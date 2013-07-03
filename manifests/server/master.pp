# == Class: ldap::server::master
#
# Puppet module to manage server configuration for
# **OpenLdap**.
#
#
# === Parameters
#
#  [suffix]
#
#    **Required**
#
#  [rootpw]
#
#    **Required**
#
#  [rootdn]
#
#    *Optional* (defaults to 'cn=admin,${suffix}')
#
#  [schema_inc]
#
#    *Optional* (defaults to [])
#
#  [modules_inc]
#
#    *Optional* (defaults to [])
#
#  [index_inc]
#
#    *Optional* (defaults to [])
#
#  [log_file]
#
#    *Optional* (defaults to /var/log/slapd/slapd.conf)
#
#  [log_level]
#
#    *Optional* (defaults to 0)
#
#  [bind_anon]
#
#    *Optional* (defaults to true)
#
#  [ldap]
#
#    Turn off ldap:// (RedHat variants only).
#    *Requires* ldapi or ssl to be true.
#    *Optional* (defaults to defaults to true)
#
#  [ldapi]
#
#    Turn on ldapi:// (RedHat variants only).
#    *Optional* (defaults to defaults to true)
#
#  [ssl]
#
#    Turn on ldaps:// (RedHat only) and ldap:// + TLS support.
#    *Requires*: ssl_{cert,ca,key} parameter
#    *Optional* (defaults to false)
#
#  [ssl_cert]
#
#    *Optional* (defaults to false)
#
#  [ssl_ca]
#
#    *Optional* (defaults to false)
#
#  [ssl_key]
#
#    *Optional* (defaults to false)
#
#  [syncprov]
#
#    *Optional* (defaults to false)
#
#  [syncprov_checkpoint]
#
#    *Optional* (defaults to '100 10')
#
#  [syncprov_sessionlog]
#
#    *Optional* (defaults to *'100'*)
#
#  [sync_binddn]
#
#    *Optional* (defaults to *'false'*)
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
# class { 'ldap::server::master':
#  suffix      => 'dc=foo,dc=bar',
#  rootpw      => '{SHA}iEPX+SQWIR3p67lj/0zigSWTKHg=',
#  syncprov    => true,
#  sync_binddn => 'cn=sync,dc=foo,dc=bar',
#  modules_inc => [ 'syncprov' ],
#  schema_inc  => [ 'gosa/samba3', 'gosa/gosystem' ],
#  index_inc   => [
#    'index memberUid            eq',
#    'index mail                 eq',
#    'index givenName            eq,subinitial',
#    ],
#  }
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
class ldap::server::master(
  $suffix,
  $rootpw,
  $rootdn              = "cn=admin,${suffix}",
  $schema_inc          = [],
  $modules_inc         = [],
  $index_inc           = [],
  $log_file            = '/var/log/slapd/slapd.log',
  $log_level           = '0',
  $bind_anon           = true,
  $ldap                = true,
  $ldapi               = true,
  $ssl                 = false,
  $ssl_ca              = false,
  $ssl_cert            = false,
  $ssl_key             = false,
  $syncprov            = false,
  $syncprov_checkpoint = '100 10',
  $syncprov_sessionlog = '100',
  $sync_binddn         = false,
  $enable_motd         = false,
  $ensure              = present,
) {
  # Call parameterized server config class.
  class { 'ldap::server::config' :
    ensure              => $ensure,
    bind_anon           => $bind_anon,
    enable_motd         => $enable_motd,
    index_inc           => $index_inc,
    ldap                => $ldap,
    ldapi               => $ldapi,
    log_file            => $log_file,
    log_level           => $log_level,
    modules_inc         => $modules_inc,
    rootdn              => $rootdn,
    rootpw              => $rootpw,
    schema_inc          => $schema_inc,
    ssl                 => $ssl,
    ssl_ca              => $ssl_ca,
    ssl_cert            => $ssl_cert,
    ssl_key             => $ssl_key,
    suffix              => $suffix,
    sync_binddn         => $sync_binddn,
    syncprov            => $syncprov,
    syncprov_checkpoint => $syncprov_checkpoint,
    syncprov_sessionlog => $syncprov_sessionlog,
    type                => 'master',
  }
}
