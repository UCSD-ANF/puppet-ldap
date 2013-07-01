
require 'spec_helper'

describe 'ldap::server::config' do

  types = ['master','slave']
  oses = {

    'Debian' => {
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '7.0',
      :lsbdistid              => 'Debian',
      :lsbdistrelease         => '7.0',
      :architecture           => 'i386',
      :kernel                 => 'Linux',

			:package       => 'slapd',
			:prefix        => '/etc/ldap',
			:cfg           => '/etc/ldap/slapd.conf',
			:service       => 'slapd',
			:server_owner  => 'openldap',
			:server_group  => 'openldap',
    },
    'CentOS' => {
      :operatingsystem        => 'CentOS',
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '5.0',
      :lsbdistid              => 'CentOS',
      :lsbdistrelease         => '5.0',
      :architecture           => 'x86_64',
      :kernel                 => 'Linux',

			:package       => 'openldap-servers',
			:prefix        => '/etc/openldap',
			:cfg           => '/etc/openldap/slapd.conf',
			:service       => 'ldap',
			:server_owner  => 'root',
			:server_group  => 'root',
    },
    'RedHat' => {
      :operatingsystem        => 'RedHat',
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '6.0',
      :lsbdistid              => 'RedHat',
      :lsbdistrelease         => '6.0',
      :architecture           => 'x86_64',
      :kernel                 => 'Linux',

			:package       => 'openldap-servers',
			:prefix        => '/etc/openldap',
			:cfg           => '/etc/openldap/slapd.conf',
			:service       => 'slapd',
			:server_owner  => 'ldap',
			:server_group  => 'ldap',
    }
  }

  oses.keys.each { |os|
    types.each { |t|
      describe "Running on #{os} as type #{t}" do
        let(:facts) {{
          :operatingsystem        => oses[os][:operatingsystem],
          :osfamily               => oses[os][:osfamily],
          :operatingsystemrelease => oses[os][:operatingsystemrelease],
          :architecture           => oses[os][:architecture],
          :kernel                 => oses[os][:kernel],
        }}
        let(:params) {{
          :suffix      => 'dc=example,dc=com',
          :rootpw      => 'asdqw',
          :rootdn      => 'cn=admin,dc=example,dc=com',
          :type        => t,
          :enable_motd => false,
          :ensure      => 'present',
          :schema_inc  => [],
          :modules_inc => [],
          :index_inc   => [],
          :log_file    => '/var/log/sladp.log',
          :log_level   => 0,
          :bind_anon   => false,
          :ldap        => true,
          :ldapi       => true,
          :ssl         => false,
          :ssl_cacert  => false,
          :ssl_cert    => false,
          :ssl_key     => false,
          :sync_binddn => false,
        }}

        it { should include_class('ldap::params') }
        it { should contain_service(oses[os][:service]) }
        it { should contain_package(oses[os][:package]) }
        it { should contain_file('server_config'
                                ).with_path(oses[os][:cfg]) }

        context 'Motd disabled (default)' do
          it { should_not contain_motd__register("ldap::server::#{t}") }
        end

        context 'Motd enabled' do
          let(:params) {{
            :suffix      => 'dc=example,dc=com',
            :rootpw      => 'asdqw',
            :rootdn      => 'cn=admin,dc=example,dc=com',
            :type        => t,
            :enable_motd => true,
            :ensure      => 'present',
            :schema_inc  => [],
            :modules_inc => [],
            :index_inc   => [],
            :log_file    => '/var/log/sladp.log',
            :log_level   => 0,
            :bind_anon   => false,
            :ldap        => true,
            :ldapi       => true,
            :ssl         => false,
            :ssl_cacert  => false,
            :ssl_cert    => false,
            :ssl_key     => false,
            :sync_binddn => false,
          }}
          it { should contain_motd__register("ldap::server::#{t}") }
        end
      end
    }
  }

  describe "Running on unsupported OS" do
    let(:facts) {{
      :operatingsystem => 'solaris',
      :kernel          => 'SunOS',
      :architecture    => 'sun4v',
    }}
    let(:params) {{
      :suffix      => 'dc=example,dc=com',
      :rootpw      => 'asdqw',
      :rootdn      => 'cn=admin,dc=example,dc=com',
      :type        => 'slave',
      :enable_motd => false,
      :ensure      => 'present',
      :schema_inc  => [],
      :modules_inc => [],
      :index_inc   => [],
      :log_file    => '/var/log/sladp.log',
      :log_level   => 0,
      :bind_anon   => false,
      :ldap        => true,
      :ldapi       => true,
      :ssl         => false,
      :ssl_cacert  => false,
      :ssl_cert    => false,
      :ssl_key     => false,
      :sync_binddn => false,
    }}
    it {
      expect { should include_class('ldap::params')
      }.to raise_error(Puppet::Error, /supported/)
    }
  end
end
