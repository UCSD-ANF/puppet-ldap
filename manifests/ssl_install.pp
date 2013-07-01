# Installer for SSL certs/keys if $ssl == true.
# Clients and servers use this type, so notify should be handled for the
# different services in the calling class.
define ldap::ssl_install(
  $ensure  = 'present',
  $cacert  = true, # true for installing client CA certificates
  $path,
) {

  include ldap::params

  # Protect key files.  The rest should be 644.
  $mode = $name ? {
    /\.key$/ => '0600',
    default  => '0644',
  }
  # Set up a predictable alias for later 'require => File...'  clauses.
  $alias = $cacert ? {
    true  => 'ssl_client_cert',
    false => $name ? {
      /\.key$/ => 'ssl_server_key',
      default  => 'ssl_server_cert',
    },
  }

  file { $alias :
    ensure => $ensure,
    source => $cert_src,
    mode   => $mode,
    path   => $path,
    owner  => $ldap::params::owner,
    group  => $ldap::params::group,
  }

  if $cacert == true {
    # Symlink client's root certificate to a path based on the cert hash.
    $cmd    = "openssl x509 -noout -hash -in ${path}"
    $target = "${ldap::params::cacertdir}/`${cmd}`.0"
    exec { 'Server certificate hash':
      command   => "ln -s ${path} ${target}",
      unless    => "test -f ${target}",
      subscribe => File[$name],
    }
  }
}
