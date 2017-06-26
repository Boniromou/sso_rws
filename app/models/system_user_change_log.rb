class SystemUserChangeLog < ChangeLog
  scope :by_action, -> action { where(action: action) if action.present? }

  def self.search_query(*args)
    args.extract_options!
    target_username, start_time, end_time = args
    match_target_username(target_username).since(start_time).until(end_time)
  end

  def self.create_system_user(params) 
    raise 'Invalid current_user params' if params[:current_user].blank?
    current_user = params[:current_user]
    cl = self.new
    cl.target_username = params[:username]
    cl.target_domain = params[:domain]
    cl.action = 'create'
    cl.action_by[:username] = "#{current_user.username}@#{current_user.domain.name}"
    cl.action_by[:casino_ids] = current_user.active_casino_ids
    cl.action_by[:casino_id_names] = current_user.active_casino_id_names

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

end
