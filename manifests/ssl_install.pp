# Installer for SSL certs/keys if $ssl == true.
define ldap::ssl_install(
  $ensure  = 'present',
  $cacert  = false, # true for server CA certificates
) {

  include ldap::params

  # Normalize a couple parameters into this class's namespace.
  $ssl_dir = $cacert ? {
    true  => $ldap::params::cacertdir,
    false => $ldap::params::ssl_prefix,
  }
  $mode = $cacert ? {
    true  => $name ? {
      /\.key$/ => '0600',
      default  => '0644',
    },
    false => '0640',
  }
  $filename = $cacert ? {
    true  => $name ? {
      /\.key$/ => 'ssl_cakey',
      default  => 'ssl_cacert',
    },
    false => 'ssl_client_cert',
  }

  # Allow users to define their own puppet resource or simple filename.
  if ( $name =~ /^puppet\:/ ) {
    $cert_src = $name
    $cert_dst = inline_template(
      '<%= ssl_dir %>/<%= File.basename(name) %>')
  } else {
    $cert_src = "puppet:///files/ldap/${name}"
    $cert_dst = "${ssl_dir}/${name}"
  }

  file { $filename :
    ensure => $ensure,
    source => $cert_src,
    mode   => $mode,
    path   => $cert_dst,
    owner  => $ldap::params::owner,
    group  => $ldap::params::group,
  }

  if $cacert == false {
    # Symlink client's root certificate to a path based on the cert hash.
    $cmd    = "openssl x509 -noout -hash -in ${cert_dst}"
    $target = "${ldap::params::ssl_dir}/`${cmd}`.0"
    exec { 'Server certificate hash':
      command   => "ln -s ${cert_dst} ${target}",
      unless    => "test -f ${target}",
      subscribe => File[$name],
    }
  }
}
