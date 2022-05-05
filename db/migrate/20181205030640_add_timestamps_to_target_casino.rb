class AddTimestampsToTargetCasino < ActiveRecord::Migration
  def change
    add_timestamps :target_casinos
  end
end
