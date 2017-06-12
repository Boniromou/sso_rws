class AuthSourceDetail < ActiveRecord::Base
	serialize :data, JSON
end