class SystemUserChangeLog < ActiveRecord::Base
  attr_accessible :id, :change_detail, :target_username, :target_casino_id, :action, :action_by, :description
  serialize :change_detail, JSON
  serialize :action_by, JSON
  scope :since, -> time { where("created_at > ?", time.to_start_date) if time.present? }
  scope :until, -> time { where("created_at < ?", time.to_end_date) if time.present? }
  scope :match_target_username, -> target_username { where("target_username LIKE ?", "%#{target_username}%") if target_username.present? }

  def self.search_query(*args)
    args.extract_options!
    target_username, start_time, end_time = args
    match_target_username(target_username).since(start_time).until(end_time)
  end
end
