class DomainChangeLog < ChangeLog

  def self.insert_create_domain_ldap(current_system_user, domain_name)
    domain = Domain.find_by_name(domain_name)
    auth_source = format_auth_source(domain.auth_source)
    insert(current_system_user, 'create', domain, nil, auth_source)
  end

  def self.insert_edit_domain_ldap(current_system_user, domain_id, auth_source)
    domain = Domain.find(domain_id)
    after = format_auth_source(domain.auth_source)
    before = format_auth_source(auth_source)
    to = after.diff(before)
    return if to.blank?
    from = before.slice(*(to.keys))
    insert(current_system_user, 'edit', domain, from, to)
  end

  private
  def self.insert(current_system_user, action, domain, from, to)
    cl = self.new
    cl.target_domain = domain.name
    cl.action = action
    cl.action_by[:username] = "#{current_system_user.username}@#{current_system_user.domain.name}"
    cl.action_by[:casino_ids] = current_system_user.active_casino_ids
    cl.action_by[:casino_id_names] = current_system_user.active_casino_id_names
    cl.change_detail[:from] = from
    cl.change_detail[:to] = to
    cl.save!
  end

  def self.format_auth_source(auth_source)
    return {} if auth_source.blank?
    auth_source.as_json(only: [:name, :host, :port, :account, :account_password, :base_dn, :admin_account, :admin_password])
  end
end
