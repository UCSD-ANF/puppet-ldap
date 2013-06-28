  
require 'spec_helper'

describe 'ldap::server::slave' do

  oses = {

    'Debian' => {
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '7.0',
      :lsbdistid              => 'Debian',
      :lsbdistrelease         => '7.0',
      :architecture           => 'amd64',
      :kernel                 => 'Linux',

			:package      => 'slapd',
			:prefix       => '/etc/ldap',
			:cfg          => '/etc/ldap/slapd.conf',
			:service      => 'slapd',
			:server_owner => 'openldap',
			:server_group => 'openldap',
    },

    'RedHat' => {
      :operatingsystem        => 'RedHat',
      :osfamily               => 'RedHat',
      :operatingsystemrelease => '6.0',
      :lsbdistid              => 'RedHat',
      :lsbdistrelease         => '6.0',
      :architecture           => 'x86_64',
      :kernel                 => 'Linux',

			:package      => 'openldap-servers',
			:prefix       => '/etc/openldap',
			:cfg          => '/etc/openldap/slapd.conf',
			:service      => 'slapd',
			:server_owner => 'ldap',
			:server_group => 'ldap',
    }

  }
  
  oses.keys.each do |os|
 
		describe "Running on #{os}" do
      let(:facts) { { 
        :architecture           => oses[os][:architecture],
        :operatingsystem        => oses[os][:operatingsystem],
        :operatingsystemrelease => oses[os][:operatingsystemrelease],
        :osfamily               => oses[os][:osfamily],
        :kernel                 => oses[os][:kernel],
      } }
      let(:params) { { 
        :suffix        => 'dc=example,dc=com',
        :sync_rid      => 1,
        :sync_provider => 'ldap://example.com',
        :sync_updatedn => 'cn=update,dc=example,dc=com',
        :sync_binddn   => 'cn=sync,dc=example,dc=com',
        :sync_bindpw   => 'asdqw',
        :rootpw        => 'asdqw',
      } }
    
			it { should contain_class('ldap::server::config').with({
        :type                => 'slave',
        :syncprov            => nil,
        :syncprov_checkpoint => nil,
        :syncprov_sessionlog => nil,
      } ) }
		end
	end
	
	describe "Running on unsupported OS" do
		let(:facts) { {
      :operatingsystem => 'Solaris',
      :osfamily        => 'Solaris',
      :kernel          => 'SunOS',
      :architecture    => 'sun4v',
    } }
		let(:params) { { 
			:suffix => 'dc=example,dc=com',
			:rootpw => 'asdqw',
		} }
		it { expect { should raise_error(Puppet::Error, /^unsupported.*/) } }
	end
end
