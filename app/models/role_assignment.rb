class RoleAssignment < ActiveRecord::Base
  belongs_to :user, :polymorphic => true
  belongs_to :role

  attr_accessible :role_id
end
