# Install an LDAP-specific Certificate Authority root certificate.
define ldap::ssl_ca(
  $ensure = 'present',
) {

  include ldap::params

  $ldap_slapd_ca = "${ldap::params::cacertdir}/ldap-slapd-ca.pem"
  file { 'ldap_slapd_ca' :
    ensure  => $ensure,
    path    => $ldap_slapd_ca,
    mode    => '0644',
    owner   => $ldap::params::owner,
    group   => $ldap::params::group,
    source  => $name,
  }

  # Symlink CA certificate to a path based on the cert hash, Debian-style.
  if $::osfamily == 'Debian' {
    $cmd    = "openssl x509 -noout -hash -in ${ssl_ldap_slapd_ca}"
    $target = "${ldap::params::cacertdir}/`${cmd}`.0"
    exec { 'CA certificate hash':
      command => "ln -s ${ssl_ldap_slapd_ca} ${target}",
      unless  => "test -f ${target}",
      require => File['ldap_slapd_ca'],
    }
  }
}
