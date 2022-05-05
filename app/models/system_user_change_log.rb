class SystemUserChangeLog < ChangeLog
  scope :by_action, -> action { where(action: action) if action.present? }

  def self.search_query(*args)
    args.extract_options!
    target_username, start_time, end_time = args
    match_target_username(target_username).since(start_time).until(end_time)
  end

  def self.create_system_user(params)
    raise 'Invalid current_user params' if params[:current_user].blank?
    cl = self.new
    cl.target_username = params[:username]
    cl.target_domain = params[:domain]
    cl.action = 'create'
    cl.set_action_by(params[:current_user])

    domain = Domain.find_by_name(params[:domain])
    system_user = SystemUser.where(:username => params[:username], :domain_id => domain.id).first
    raise 'Invalid system_user' if !system_user

    transaction do
      cl.save!
      system_user.active_casino_ids.each do |target_casino_id|
        casino = Casino.find(target_casino_id)
        cl.target_casinos.create!(:change_log_id => cl.id, :target_casino_id => target_casino_id, :target_casino_name => casino.name)
      end
    end
  end

  def self.inactive_system_user(params)
    target_user = params[:target_user]
    raise 'Invalid current_user params' if params[:current_user].blank?
    cl = self.new
    cl.target_username = target_user.username
    cl.target_domain = target_user.domain.name
    cl.action = 'inactive'
    cl.set_action_by(params[:current_user])

    transaction do
      cl.save!
      target_user.active_casino_ids.each do |target_casino_id|
        casino = Casino.find(target_casino_id)
        cl.target_casinos.create!(:change_log_id => cl.id, :target_casino_id => target_casino_id, :target_casino_name => casino.name)
      end
    end
  end
end
