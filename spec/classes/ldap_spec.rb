
require 'spec_helper'

describe 'ldap' do

	oses = {
    'Debian' => {
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '7.0',
      :lsbdistid              => 'Debian',
      :lsbdistrelease         => '7.0',
      :architecture           => 'i386',
      :kernel                 => 'Linux',

			:package       => 'ldap-utils',
			:prefix        => '/etc/ldap',
			:cfg           => '/etc/ldap/ldap.conf',
			:cacertdir     => '/etc/ssl/certs',
			:ssl_prefix    => '/etc/ssl/certs',
			:ssl_ca        => 'myCAcert.pem',
    },
    'CentOS' => {
      :operatingsystem        => 'CentOS',
      :osfamily               => '', # simulate Facter <1.6.1
      :operatingsystemrelease => '5.0',
      :lsbdistid              => 'CentOS',
      :lsbdistrelease         => '5.0',
      :architecture           => 'x86_64',
      :kernel                 => 'Linux',

			:package       => 'openldap-clients',
			:prefix        => '/etc/openldap',
			:cfg           => '/etc/openldap/ldap.conf',
			:ssl_prefix    => '/etc/openldap',
			:cacertdir     => '/etc/pki/tls/certs',
			:ssl_ca        => 'myCAcert.pem',
    },
    'RedHat' => {
      :operatingsystem        => 'RedHat',
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '6.0',
      :lsbdistid              => 'RedHat',
      :lsbdistrelease         => '6.0',
      :architecture           => 'x86_64',
      :kernel                 => 'Linux',

			:package       => 'openldap-clients',
			:prefix        => '/etc/openldap',
			:cfg           => '/etc/openldap/ldap.conf',
			:ssl_prefix    => '/etc/openldap',
			:cacertdir     => '/etc/pki/tls/certs',
			:ssl_ca        => 'myCAcert.pem',
    }
  }

	oses.keys.each do |os|
		describe "Running on #{os}" do
      let(:facts) {{
        :operatingsystem        => oses[os][:operatingsystem],
        :osfamily               => oses[os][:osfamily],
        :operatingsystemrelease => oses[os][:operatingsystemrelease],
        :architecture           => oses[os][:architecture],
        :kernel                 => oses[os][:kernel],
      }}
			let(:params) { { 
				:uri  => 'ldap://ldap.example.com',
				:base => 'dc=suffix',
			} }
			it { should include_class('ldap::params') }
			it { should contain_package(oses[os][:package]) }
			it { should contain_file('client_config'
                              ).with_path(oses[os][:cfg]) }

			context 'Motd disabled (default)' do
				it { should_not contain_motd__register('ldap') }
			end
			context 'Motd enabled' do
				let(:params) { {
					:uri  => 'ldap://ldap.example.com',
					:base => 'dc=suffix',
					:enable_motd => true 
				} }
				it { should contain_motd__register('ldap') }
			end

			context 'SSL Enabled with certificate filename' do
				let(:params) { {
					:uri    => 'ldap://ldap.example.com',
					:base   => 'dc=suffix',
					:ssl    => true,
					:ssl_ca => oses[os][:ssl_ca],
				} }
				it { should contain_file(
          "#{oses[os][:cacertdir]}/ldap-slapd-ca.pem") } 
			end

			context 'SSL Enabled without certificate' do
				let(:params) { {
					:uri      => 'ldap://ldap.example.com',
					:base     => 'dc=suffix',
					:ssl      => true,
				} }
				it { expect { should contain_warning('').with_content(/install/) }
				}
			end
		end
	end
end
