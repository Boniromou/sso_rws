class AuditLog < ActiveRecord::Base
  attr_accessible :audit_target, :action_type, :action, :action_status, :action_error, :session_id, :ip, :action_by, :action_at, :description
  validates_presence_of :audit_target, :action, :action_status, :action_by, :action_at#, :action_type
  ACTION_TYPES = %w(create read update delete)
  validate :action_type, :inclusion => { :in => ACTION_TYPES }
  # TODO: consider about putting this in a yml
  ACTION_MENU = {:all => { :all => "general.all" },
                 :system_user => { :all => "general.all",
                                   :lock => "user.lock", 
                                   :unlock => "user.unlock", 
                                   :edit_role => "user.edit_role"}}
  ACTION_TYPE_LIST = {:system_user => { :lock => "update", :unlock => "update", :edit_role => "update" }}
  scope :since, -> start_time { where("action_at > ?", start_time) if start_time.present? }
  scope :until, -> end_time { where("action_at < ?", end_time) if end_time.present? }
  scope :match_action_by, -> actioner { where("action_by LIKE ?", "%#{actioner}%") if actioner.present? }
  scope :by_target, -> target { where("audit_target = ?", target) if target.present? }
  scope :by_action, -> action { where("action = ?", action) if action.present? }
  scope :by_action_type, -> action_type { where("action_type = ?", action_type) if action_type.present? }
  scope :by_action_status, -> action_status { where("action_status = ?", action_status) if action_status.present? }

  def self.search_query(*args)
    audit_target = args[0]
    action = args[1]
    action_type = args[2]
    action_by= args[3]
    start_time = args[4]
    end_time = args[5]
    by_target(audit_target).by_action(action).by_action_type(action_type).match_action_by(action_by).since(start_time).until(end_time)
  end

  def self.system_user_log(action, action_by, session_id, ip, options={}, &block)
    compose_log("system_user", action, action_by, session_id, ip, options, &block)
  end

  private
  def self.compose_log(audit_target, action, action_by, session_id, ip, options={}, &block)
    content = options.merge({:audit_target => audit_target, :action => action, :action_by => action_by, :session_id => session_id, :ip => ip})
    begin
      block.call if block
      logging(content)
    rescue Exception => e
      logging(content.merge({:action_error => e.message, :action_status => "fail"}))
      raise e
    end
  end

  def self.logging(content={})
    audit_target = content[:audit_target]
    action = content[:action]
    action_by = content[:action_by]
    action_type = content[:action_type] || ACTION_TYPE_LIST[audit_target.to_sym][action.to_sym]
    action_error = content[:action_error]
    action_status = content[:action_status] || "success"
    action_at = content[:action_at] || Time.now
    session_id = content[:session_id]
    ip = content[:ip]
    description = content[:description]
    content_to_insert = { :audit_target => audit_target, :action_type => action_type, :action_error => action_error, :action => action, :action_status => action_status, :action_by => action_by, :action_at => action_at, :session_id => session_id, :ip => ip, :description => description }
    self.create!(content_to_insert)
    Rails.logger.info "[AuditLogs] capture an action and created a log with content=#{content_to_insert.inspect}"
  end
end
