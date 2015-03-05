module Authentication
  module Ldap
    extend self
    
    def bind?(username, password)
      user_n = "mo\\#{username}" unless username.start_with?("mo\\")
      options = { :host => "10.10.28.91",
                  :port => 389,
                  :encryption => nil,
                  :auth => {
                    :method => :simple,
                    :username => user_n,
                    :password => password
                    }
                  }
      ldap = Net::LDAP.new options
      ldap.bind
    end
  end
end
