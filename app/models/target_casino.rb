class TargetCasino < ActiveRecord::Base
  attr_accessible :id, :change_log_id, :target_casino_id, :target_casino_name
  belongs_to :change_logs
end
