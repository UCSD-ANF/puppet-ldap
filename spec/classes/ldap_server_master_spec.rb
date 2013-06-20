  
require 'spec_helper'

describe 'ldap::server::master' do

  oses = {

    'Debian' => {
      :operatingsystem        => 'Debian',
      :osfamily               => 'Debian',
      :operatingsystemrelease => '7.0',
      :lsbdistid              => 'Debian',
      :lsbdistrelease         => '7.0',
      :architecture           => 'x86_64',

			:package      => 'slapd',
			:prefix       => '/etc/ldap',
			:cfg          => '/etc/ldap/slapd.conf',
			:service      => 'slapd',
			:server_owner => 'openldap',
			:server_group => 'openldap',
    },

    'Redhat' => {
      :operatingsystem        => 'Redhat',
      :osfamily               => 'Redhat',
      :operatingsystemrelease => '5.0',
      :lsbdistid              => 'Redhat',
      :lsbdistrelease         => '5.0',
      :architecture           => 'x86_64',

			:package   => 'openldap-servers',
			:prefix    => '/etc/openldap',
			:cfg       => '/etc/openldap/slapd.conf',
			:service   => 'slapd',
			:server_owner => 'openldap',
			:server_group => 'openldap',
    }

  }
  
  oses.keys.each do |os|
 
		let(:facts) { { 
      :operatingsystem => oses[os][:operatingsystem],
    } }
		
		describe "Running on #{os}" do

      let(:params) { { 
        :suffix => 'dc=example,dc=com',
        :rootpw => 'asdqw',
      } }
    
			it { should contain_class('ldap::server::config').with({
        :type          => 'master',
        :sync_attrs    => nil,
        :sync_base     => nil,
        :sync_bindpw   => nil,
        :sync_filter   => nil,
        :sync_interval => nil,
        :sync_provider => nil,
        :sync_rid      => nil,
        :sync_scope    => nil,
        :sync_type     => nil,
        :sync_updatedn => nil,
      } ) }
		end
	end
	
	describe "Running on unsupported OS" do
		let(:facts) { { :operatingsystem => 'solaris' } }
		let(:params) { { 
			:suffix => 'dc=example,dc=com',
			:rootpw => 'asdqw',
		} }
		it { expect { should raise_error(Puppet::Error, /^unsupported.*/) } }
	end
	describe "Running on unsupported Arch" do
		let(:facts) { {
      :operatingsystem => 'RedHat',
      :architecture    => 'foo86',
    } }
		let(:params) { { 
			:suffix => 'dc=example,dc=com',
			:rootpw => 'asdqw',
		} }
		it { expect { should raise_error(Puppet::Error, /^unsupported.*/) } }
	end
end
