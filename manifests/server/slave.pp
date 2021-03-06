# == Class: ldap::server::slave
#
# Puppet module to manage server configuration for
# **OpenLdap**.
#
#
# === Parameters
#
#  [suffix]
#    Ldap tree base
#    **Required**
#
#  [sync_rid]
#    Replica ID (numeric)
#    **Required**
#
#  [sync_provider]
#    Provider URI (ldap[s]://master.ldap)
#    **Required**
#
#  [sync_updatedn]
#    DN permitted to update the replica (should not be the same as rootdn)
#    **Required**
#
#  [sync_binddn]
#    DN that will perform sync (connect to master and fetch data)
#    **Required**
#
#  [sync_bindpw]
#    Credentials fr sync_binddn.
#    **NOTE** This should be in clear text
#    **Required**
#
#  [rootpw]
#    Password for root DN (encrypted as in 'slappasswd -h "{SHA}" -s example')
#    **Required**
#
#  [rootdn]
#    Root DN.
#    *Optional* (defaults to 'cn=admin,${suffix}')
#
#  [schema_inc]
#    Array of additional schemas that will be included.
#    Some schemas are already included (ldap::params::schemas_base)
#    'core', 'cosine', 'nis', 'inetorgperson'
#    *Optional* (defaults to [])
#
#  [modules_inc]
#    Array of modules that you want to load. Depends on the ditro being used.
#    Some modules are already included through ldap::params::modules_base
#    *Optional* (defaults to [])
#
#  [index_inc]
#    Array of indexes to be generated.
#    Some indexes are already generated through ldap::params::index_base
#         'index objectclass  eq',
#         'index entryCSN     eq',
#         'index entryUUID    eq',
#         'index uidNumber    eq',
#         'index gidNumber    eq',
#         'index cn           pres,sub,eq',
#         'index sn           pres,sub,eq',
#         'index uid          pres,sub,eq',
#         'index displayName  pres,sub,eq',
#    *Optional* (defaults to [])
#
#  [log_file]
#    OpenLdap server log file.
#    *Optional* (defaults to /var/log/slapd/slapd.log)
#
#  [log_level]
#    OpenLdap server log level.
#    *Optional* (defaults to 0)
#
#  [bind_anon]
#    Allow anonymous binding
#    *Optional* (defaults to true)
#
#  [ldap]
#
#    Turn off ldap:// (RedHat variants only).
#    *Requires* ldapi or ssl to be true.
#    *Optional* (defaults to defaults to false)
#
#  [ldapi]
#
#    Turn on ldapi:// (RedHat variants only).
#    *Optional* (defaults to defaults to true)
#
#  [ssl]
#    Enable SSL/TLS.
#    *Requires*: ssl_{cert,ca,key} parameter
#    *Optional* (defaults to false)
#
#  [ssl_cert]
#    Public certificate filename (should be located at puppet:///files/ldap)
#    *Requires*: ssl => true
#    *Optional* (defaults to false)
#
#  [ssl_ca]
#    CA certificate filename (should be located at puppet:///files/ldap)
#    *Requires*: ssl => true
#    *Optional* (defaults to false)
#
#  [ssl_key]
#    Private certificate filename (should be located at puppet:///files/ldap)
#    *Requires*: ssl => true
#    *Optional* (defaults to false)
#
#  [sync_type]
#    Content synchronizatin protocol type (refreshOnly / refreshAndPersist)
#    *Optional* (defaults to refreshOnly)
#
#  [sync_interval]
#    Synchronization interval.
#    *Optional* (defaults to 00:00:10:00)
#
#  [sync_base]
#    Base for replication
#    *Optional* (defaults to '')
#
#  [sync_filter]
#    Filter to use when fetching content.
#    *Optional* (defaults to '(ObjectClass=*)')
#
#  [sync_attrs]
#    Attributes to synchronize.
#    *Optional* (defaults to '*')
#
#  [sync_scope]
#    Objects search depth.
#    *Optional* (defaults to 'sub')
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
#   suffix      => 'dc=foo,dc=bar',
#   rootpw      => '{SHA}iEPX+SQWIR3p67lj/0zigSWTKHg=',
#   syncprov    => true,
#   sync_binddn => 'cn=sync,dc=foo,dc=bar',
#   modules_inc => [ 'syncprov' ],
#   schema_inc  => [ 'gosa/samba3', 'gosa/gosystem' ],
#   index_inc   => [
#       'index memberUid            eq',
#       'index mail                 eq',
#       'index givenName            eq,subinitial',
#   ],
# }
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
class ldap::server::slave(
  $suffix,
  $sync_rid,
  $sync_provider,
  $sync_updatedn,
  $sync_binddn,
  $sync_bindpw,
  $rootpw,
  $rootdn         = "cn=admin,${suffix}",
  $schema_inc     = [],
  $modules_inc    = [],
  $index_inc      = [],
  $log_file       = '/var/log/slapd/slapd.log',
  $log_level      = '0',
  $bind_anon      = true,
  $ldap           = true,
  $ldapi          = true,
  $ssl            = false,
  $ssl_ca         = false,
  $ssl_cert       = false,
  $ssl_key        = false,
  $sync_type      = 'refreshOnly',
  $sync_interval  = '00:00:10:00',
  $sync_base      = '',
  $sync_filter    = '(objectClass=*)',
  $sync_attrs     = '*',
  $sync_scope     = 'sub',
  $enable_motd    = false,
  $ensure         = 'present',
) {
  # Call parameterized server config class.
  class { 'ldap::server::config':
    ensure        => $ensure,
    bind_anon     => $bind_anon,
    enable_motd   => $enable_motd,
    index_inc     => $index_inc,
    ldap          => $ldap,
    ldapi         => $ldapi,
    log_file      => $log_file,
    log_level     => $log_level,
    modules_inc   => $modules_inc,
    rootdn        => $rootdn,
    rootpw        => $rootpw,
    schema_inc    => $schema_inc,
    ssl           => $ssl,
    ssl_ca        => $ssl_ca,
    ssl_cert      => $ssl_cert,
    ssl_key       => $ssl_key,
    suffix        => $suffix,
    sync_attrs    => $sync_attrs,
    sync_base     => $sync_base,
    sync_binddn   => $sync_binddn,
    sync_bindpw   => $sync_bindpw,
    sync_filter   => $sync_filter,
    sync_interval => $sync_interval,
    sync_provider => $sync_provider,
    sync_rid      => $sync_rid,
    sync_scope    => $sync_scope,
    sync_type     => $sync_type,
    sync_updatedn => $sync_updatedn,
    type          => 'slave',
  }
}
