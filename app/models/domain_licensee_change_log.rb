class DomainLicenseeChangeLog < ChangeLog

  def self.insert_create_domain_licensee(current_system_user, info)
    insert(current_system_user, 'create', info)
  end

  def self.insert_delete_domain_licensee(current_system_user, info)
    insert(current_system_user, 'delete', info)
  end

  private
  def self.insert(current_system_user, action, info)
    domain = Domain.find_by_id(info[:domain_id])
    licensee = Licensee.find_by_id(info[:licensee_id])
    active_casino_ids = current_system_user.active_casino_ids
    active_casino_id_names = current_system_user.active_casino_id_names

    transaction do
      licensee.casinos.each do |casino|
        cl = self.new
        cl.target_domain = domain.name
        cl.action = action
        cl.action_by[:username] = "#{current_system_user.username}@#{current_system_user.domain.name}"
        cl.action_by[:casino_ids] = active_casino_ids
        cl.action_by[:casino_id_names] = active_casino_id_names
        cl.change_detail[:licensee_name] = licensee.name
        cl.change_detail[:licensee_id] = licensee.id
        cl.save!
        
        cl.target_casinos.create!(:target_casino_id => casino.id, :target_casino_name => casino.name)
      end
    end
  end
end
