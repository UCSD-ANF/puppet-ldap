#
# ldap_ssl_path.rb
#
module Puppet::Parser::Functions
  newfunction(:ldap_ssl_path, :type => :rvalue, :doc => <<-EOS
ldap_ssl_path()

Take string argument and return an array of strings regarding the source
and destination of the argument.

EXAMPLES then

ldap_ssl_path('foo.pem','/etc/openldap')
would return: {'src'=>'puppet:///files/ldap/foo.pem',
               'dst'=>'/etc/openldap/foo.pem'}

ldap_ssl_path('/etc/ssl/foo.pem','/etc/ssl')
would return: {'src'=>'/etc/ssl/foo.pem',
               'dst'=>'/etc/ssl/foo.pem'}

ldap_ssl_path('puppet:///mymod/foo.pem','/etc/ssl')
would return: {'src'=>'puppet:///mymod/foo.pem',
               'dst'=>'/etc/ssl/foo.pem'}
    EOS
  ) do |args|

      myName = 'ldap_ssl_path()'

      unless args.size == 2 then
          raise(Puppet::ParseError, "#{myName}: Wrong number of args " +
                "given (#{args.size} for 2)")
      end

      unless args[0].is_a?(String) then
          raise(Puppet::ParseError, "#{myName}: Requires String to work with"+
                "got #{args[0].class}.")
      end
      unless args[1].is_a?(String) then
          raise(Puppet::ParseError, "#{myName}: Requires String to work with"+
                "got #{args[1].class}.")
      end

      myArg  = args[0]
      myBN   = File.basename(myArg)
      dstDir = args[1]

      # simple filename
      if myArg == myBN then
        src = "puppet:///files/ldap/#{myArg}"
        dst = "#{dstDir}/#{myArg}"
      # filesystem path or URI.
      elsif myArg.start_with?('puppet://') or
        myArg.start_with?('/') then
        src = myArg
        dst = "#{dstDir}/#{myBN}"
      else 
          raise(Puppet::ParseError, "#{myName}: don't understand "+
                "argument, #{myArg}.")
      end
      return { 'src' => src, 'dst' => dst, }
  end
end
