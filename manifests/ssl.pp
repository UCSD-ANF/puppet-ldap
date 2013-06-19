# == Defined Type: ldap::ssl
#
# Puppet defined type to manage SSL configuration for
# **OpenLdap**.
#
#
# === Parameters
#
#  [ensure]
#    *Optional* (defaults to 'present')
#
#  [ssl_cert]
#    *Required*
#    
#  [ssl_ca]
#    *Optional* (defaults to undef)
#   If provided, with ssl_key, assume we are configuring a server's SSL.
#    
#  [ssl_key]
#    *Optional* (defaults to undef)
#   If provided, with ssl_ca, assume we are configuring a server's SSL.
#
define ldap::ssl (
  $ensure='present',
  $ssl_ca=undef,
  $ssl_cert,
  $ssl_key=undef,
) {

  include ldap::params

  $msg_prefix   = 'SSL enabled. You must specify'
  $msg1         = '(filename).  puppet:///files/ldap is the default location, '
  $msg2         = 'but you may also provide a different Puppet-friendly path.'
  $msg_suffix   = "${msg1}${msg2}"

  # SSL cert required always. Fail early.
  if !$ssl_cert { fail("${msg_prefix} ssl_cert ${msg_suffix}") }

  # Fail if we have a CA but no key, or vice versa.
  if !$ssl_ca and $ssl_key { fail("${msg_prefix} ssl_ca ${msg_suffix}") }
  if $ssl_ca and !$ssl_key { fail("${msg_prefix} ssl_key ${msg_suffix}") }

  # Normalize a couple parameters into this class's namespace.
  $ssl_prefix   = $ldap::params::ssl_prefix
  $cacertdir    = $ldap::params::cacertdir

  # Conditionally set CA certificate, key and file ownership.
  if $ssl_ca and $ssl_key {
    File {
      mode    => 0640,
      owner   => $ldap::params::server_owner,
      group   => $ldap::params::server_group,
    }
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
    }
  } else {
    File {
      ensure  => $ensure,
      mode    => 0644,
      owner   => $ldap::params::owner,
      group   => $ldap::params::group,
    }
  }

  # Set SSL certificate.
  # Allow users to define their own puppet resource or simple filename.
  if ( $ssl_cert =~ /^puppet\:/ ) {
    $ssl_cert_src = $ssl_cert
    $ssl_cert_dst = inline_template(
      "<%= ssl_prefix %>/<%= File.basename(ssl_cert) %>")
  } else {
    $ssl_cert_src = "puppet:///files/ldap/${ssl_cert}"
    $ssl_cert_dst = "${cacertdir}/${ssl_cert}"
  }

  file { "ssl_cert_${name}":
    ensure  => $ensure,
    source  => $ssl_cert_src,
    path    => $ssl_cert_dst,
  }

  # Symlink certificate to a filename based on the cert hash.
  $target = "${cacertdir}/$(openssl x509 -noout -hash -in ${ssl_cert_dst}).0"
  exec { "Server certificate hash":
    command => "ln -s ${ssl_cert_dst} ${target}",
    unless  => "test -f ${target}",
    require => File["ssl_cert_${name}"]
  }
}
