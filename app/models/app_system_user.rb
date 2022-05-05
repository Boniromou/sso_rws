class AppSystemUser < ActiveRecord::Base
  belongs_to :app
  belongs_to :system_user

  attr_accessible :app_id
end
