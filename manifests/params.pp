# Parameters for LDAP.
class ldap::params {

  # Fail on unsupported kernels, architectures, OSes.
  if $::kernel != 'Linux' {
    fail("${module_name} unsupported for ${::kernel}.")
  }

  if  $::architecture != 'amd64'
  and $::architecture != 'x86_64'
  and $::architecture !~ /^i?[346]86/ {
    fail("Architecture unsupported (${::architecture})")
  }

  case $::osfamily {
    /(Debian|Suse)/: {
      # NOOP
    } 'RedHat': {
      # OVS release versions are offset from other variants by 4.
      # We'll reject other RedHat versions lower than 5, here, so
      # that we can match [125] and/or [15] for some
      # $::osfamily-related checks later.
      if  $::operatingsystem == 'OVS'
      and $::operatingsystemrelease !~ /^[12]\./ {
          fail("OS version unsupported (${::operatingsystemrelease})")
      } elsif $::operatingsystemrelease !~ /^[56]\./ {
          fail("OS version unsupported (${::operatingsystemrelease})")
      }
    } default: {
      fail("Operating system unsupported (${::operatingsystem})")
    }
  }

  # Set some variables by OS.
  $schema_base = $::operatingsystem ? {
    'OVS'   => [ 'core', 'cosine', 'nis', 'inetorgperson', 'authldap', ],
    default => [ 'core', 'cosine', 'nis', 'inetorgperson', ],
  }

  # Set other variables by OS family.
  # where to install our CA cert, or load OS-provided CA certs.
  $cacertdir = $::osfamily ? {
    'RedHat' => '/etc/pki/tls/certs',
    default  => '/etc/ssl/certs',
  }
  $config = $::osfamily ? {
    default  => 'ldap.conf',
  }
  $db_prefix = $::osfamily ? {
    default  => '/var/lib/ldap',
  }
  $group = $::osfamily ? {
    'RedHat' => $::operatingsystemrelease ? {
      /^[125]\./ => 'root', # /^[15]\./ ?
      default    => 'ldap',
    },
    default  => 'root',
  }
  $index_base = $::osfamily ? {
    default => [
      'index objectclass  eq',
      'index entryCSN     eq',
      'index entryUUID    eq',
      'index uidNumber    eq',
      'index gidNumber    eq',
      'index cn           pres,sub,eq',
      'index sn           pres,sub,eq',
      'index uid          pres,sub,eq',
      'index displayName  pres,sub,eq',
    ]
  }
  $modules_base = $::osfamily ? {
    'RedHat' => $::operatingsystem ? {
      'OVS'   => [ 'back_bdb', ],
      default => [  ],
    },
    default  => [ 'back_bdb', ],
  }
  $module_prefix = $::osfamily ? {
    'Debian' => $::architecture ? {
      'amd64'      => '/usr/lib64/ldap',
      /^i?[346]86/ => '/usr/lib32/ldap',
    },
    'RedHat' => $::architecture ? {
      'x86_64'     => '/usr/lib64/openldap',
      /^i?[346]86/ => '/usr/lib/openldap',
    },
    default => '/usr/lib/openldap',
  }
  $owner = $::osfamily ? {
    'RedHat' => $::operatingsystemrelease ? {
      /^[125]\./ => 'root', # /^[15]\./ ?
      default    => 'nslcd',
    },
    default  => 'root',
  }
  $package = $::osfamily ? {
    'Debian' => [ 'ldap-utils', ],
    'Suse'   => [ 'openldap2-client', ],
    default  => [ 'openldap', 'openldap-clients', ],
  }
  $prefix = $::osfamily ? {
    'Debian' => '/etc/ldap',
    default  => '/etc/openldap',
  }
  $schema_prefix = $::osfamily ? {
    default  => "${prefix}/schema",
  }
  $server_config = $::osfamily ? {
    default  => 'slapd.conf',
  }
  $server_group = $::osfamily ? {
    'Debian' => 'openldap',
    'RedHat' => $::operatingsystemrelease ? {
      /^5\./  => 'root', # /^[15]\./ ?
      default => 'ldap',
    },
    default  => 'root',
  }
  $server_owner = $::osfamily ? {
    'Debian' => 'openldap',
    'RedHat' => $::operatingsystemrelease ? {
      /^5\./  => 'root', # /^[15]\./ ?
      default => 'ldap',
    },
    default  => 'root',
  }
  $server_package = $::osfamily ? {
    'Debian' => [ 'slapd', ],
    'Suse'   => [ 'openldap2', ],
    default  => [ 'openldap-servers', ],
  }
  $server_pattern = $::osfamily ? {
    default  => 'slapd',
  }
  $server_run = $::osfamily ? {
    'Suse'   => '/var/run/slapd',
    default  => '/var/run/openldap',
  }
  $server_script = $::osfamily ? {
    'Suse'   => 'ldap',
    default  => undef,
  }
  $service = $::osfamily ? {
    'RedHat' => $::operatingsystemrelease ? {
      /^5\./  => 'ldap',
      default => 'slapd',
    },
    'Suse'   => 'ldap',
    default  => 'slapd',
  }
  $slapd_var = $::osfamily ? {
    'Debian' => 'SLAPD_SERVICES',
    'RedHat' => 'SLAPD_URLS',
    default  => undef,
  }
  $slapd_defaults = $::osfamily ? {
    'Debian' => '/etc/default/slapd',
    'RedHat' => '/etc/sysconfig/ldap',
    default  => undef,
  }
  # where to install our server's CA-signed cert/key.
  $ssl_prefix = $::osfamily ? {
    default => "${prefix}/certs",
  }

  # SSL error messages used in a couple places.
  $ssl_msg_prefix = 'SSL enabled. You must specify'
  $ssl_msg1       = '(filename). puppet:///files/ldap is the default location, '
  $ssl_msg2       = 'but you may also provide a different Puppet-friendly path.'
  $ssl_msg_suffix = "${ssl_msg1}${ssl_msg2}"
}
