class DomainCasinoChangeLog < ChangeLog
  # params in
  #   info {domain_id, casino_id}
  def self.insert_create_domain_casino(current_system_user, info)
    domain = Domain.find_by_id(info[:domain_id])
    casino = Casino.find_by_id(info[:casino_id])
    insert(current_system_user, 'create', domain, casino)
  end

  def self.insert_inactive_domain_casino(current_system_user, id)
    domain_casino = DomainsCasino.find_by_id(id)
    domain = Domain.find_by_id(domain_casino.domain_id)
    casino = Casino.find_by_id(domain_casino.casino_id)
    insert(current_system_user, 'delete', domain, casino)
  end

  private
  def self.insert(current_system_user, action, domain, casino)
    action_by = {
      username: current_system_user.username,
      casino_ids: current_system_user.active_casino_ids,
      casino_id_names: current_system_user.active_casino_id_names
    }

    info = {
      action: action,
      action_by: action_by,
      target_domain: domain.name,
    }
    cl = create(info)

    info = {
      target_casino_id: casino.id,
      target_casino_name: casino.name
    }
    cl.target_casinos.create(info)
  end
end
