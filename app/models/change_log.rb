class ChangeLog < ActiveRecord::Base
  attr_accessible :id, :change_detail, :target_username, :target_domain, :type, :action, :action_by, :description

  serialize :change_detail, JSON
  serialize :action_by, JSON

  has_many :target_casinos

  scope :since, -> time { where("change_logs.created_at >= ?", time) if time.present? }
  scope :until, -> time { where("change_logs.created_at < ?", time) if time.present? }
  scope :match_target_username, -> target_username { where("change_logs.target_username LIKE ?", "%#{target_username}%") if target_username.present? }

  def self.inherited(child)
     child.instance_eval do
       def model_name
          ChangeLog.model_name
       end
     end
     super
  end

  def target_casino_name
    self.target_casinos.first.target_casino_name if self.target_casinos.first
  end

  def target_casino_id
    self.target_casinos.first.target_casino_id if self.target_casinos.first
  end

  def backfill(target_user)
    return if TargetCasino.find_by_change_log_id(id).present?
    target_user.active_casino_ids.each do |casino_id|
      target_casinos.create(:target_casino_id => casino_id, :target_casino_name => Casino.find(casino_id).name)
    end
  end
end
