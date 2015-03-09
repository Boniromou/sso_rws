class AuditLog < ActiveRecord::Base
  attr_accessible :audit_target, :action_type, :action, :action_status, :action_error, :session_id, :ip, :action_by, :action_at, :description
  validates_presence_of :audit_target, :action_type, :action, :action_status, :action_by, :action_at
  ACTION_TYPE_LIST = ["create", "read", "update", "delete"]

  def self.policy_class
    AuditLogPolicy
  end

  def self.maintenance_log(action, action_by, session_id, ip, options={}, &block)
    compose_log("maintenance", action, action_by, session_id, ip, options, &block)
  end

  def self.system_user_log(action, action_by, session_id, ip, options={}, &block)
    compose_log("system_user", action, action_by, session_id, ip, options, &block)
  end

  def self.propagation_log(action, action_by, session_id, ip, options={}, &block)
    compose_log("propagation", action, action_by, session_id, ip, options, &block)
  end

  def self.search(params={})
    
  end

  def self.actions_for audit_target
    case audit_target
      when "system_user"
        ["lock", "unlock", "edit_role"]
      when "maintenance"
        ["create", "cancel", "complete", "extend", "reschedule", "expire"]
      when "propagation"
        ["resume"]
      else
        raise NameError
    end
  end
  
  def self.action_type_for(audit_target, action)
    list = case audit_target
      when "system_user"
        { :lock => "update", :unlock => "update", :edit_role => "update" }
      when "maintenance"
        { :create => "create", :cancel => "update", :complete => "update", :extend => "update", :reschedule => "update", :expire => "update" }
      when "propagation"
        { :resume => "update" }
      else
        raise NameError
    end
    type = list[action.to_sym]
    raise NameError unless type
    return type
  end

  private
  def self.compose_log(audit_target, action, action_by, session_id, ip, options={}, &block)
    content = options.merge({:audit_target => audit_target, :action => action, :action_by => action_by, :session_id => session_id, :ip => ip})
    begin
      block.call if block
      logging(content)
    rescue ActiveRecord::RecordInvalid => e
      # ignore invalid error
      raise e
    rescue Exception => e
      #Rails.logger.error "#{e.message}"
      #Rails.logger.error "#{e.backtrace.inspect}"
      logging(content.merge({:action_error => e.message, :action_status => "fail"}))
      raise e
    end
  end

  def self.logging(content={})
    audit_target = content[:audit_target]
    action = content[:action]
    action_by = content[:action_by]
    action_type = content[:action_type] || action_type_for(audit_target, action)
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
