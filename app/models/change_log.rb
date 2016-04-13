class ChangeLog < ActiveRecord::Base
  attr_accessible :id, :change_detail, :target_username, :target_domain, :type, :action, :action_by, :description

  serialize :change_detail, JSON
  serialize :action_by, JSON

  has_many :target_casinos

  scope :since, -> time { where("created_at > ?", time.to_start_date) if time.present? }
  scope :until, -> time { where("created_at < ?", time.to_end_date) if time.present? }
  scope :match_target_username, -> target_username { where("target_username LIKE ?", "%#{target_username}%") if target_username.present? }

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
end
