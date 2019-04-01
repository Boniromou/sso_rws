require 'csv'

class CsvUserService
  def initialize(licensee)
    @licensee = licensee
    @config = licensee.sync_user_config
    @data = licensee.sync_user_data || {}
  end

  def sync_user_info
    Net::SFTP.start(@config['host'], @config['user'], :password => @config['password']) do |sftp|
      file_name = get_latest_file(sftp)
      next unless file_name
      Rails.logger.info "download #{@config['path']}/#{file_name}"
      data = sftp.download!("#{@config['path']}/#{file_name}")
      Rails.logger.info "download end"
      process_csv(file_name, CSV.parse(data))
    end
  end

  def process_csv(file_name, data)
    records = get_csv_records(data)
    process_users(records)
    update_licensee(file_name)
  end

  private
  def process_users(records)
    records.each do |domain_id, usernames|
      users = SystemUser.includes(:roles).where(domain_id: domain_id)
      error_data = usernames - users.map(&:username)
      Rails.logger.error "users not exist: #{error_data}" if error_data.size > 0
      SystemUser.transaction do
        users.each do |user|
          update_user(usernames, user)
        end
      end
    end
  end

  def update_user(usernames, user)
    return if user.status == SystemUser::PENDING
    if usernames.include?(user.username)
      return if user.status == SystemUser::ACTIVE
      user.update_attributes!(status: SystemUser::ACTIVE) if user.roles.present?
    else
      if user.status == SystemUser::INACTIVE
        user.update_attributes!(status: SystemUser::ACTIVE) if user.roles.present?
      else
        user.update_attributes!(status: SystemUser::INACTIVE) if user.roles.blank?
      end
    end
  end

  def update_licensee(file_name)
    @data['last_synced_file'] = file_name
    @data['last_synced_at'] = Time.now
    @licensee.sync_user_data = @data
    @licensee.save!
  end

  def get_csv_records(data)
    records = {}
    error_data = []
    domains = Hash[@licensee.domains.map{|d| [d.name, d.id]}]
    data.each do |row|
      row[1] = row[1].strip
      if !domains.keys.include?(row[1])
        error_data << row
        next
      end
      records[domains[row[1]]] ||= []
      records[domains[row[1]]] << row[0].strip
    end
    Rails.logger.error "wrong domain data: #{error_data}" if error_data.size > 0
    Rails.logger.info "get csv records size: #{data.size}"
    records
  end

  def get_latest_file(sftp)
    Rails.logger.info "get latest file, path [#{@config['path']}]"
    file_names = sftp.dir.entries(@config['path']).map {|entry| entry.name}.reject {|name| !name.end_with?(".csv") && !name.include?('systemuser_')}
    file_name = file_names.sort!{|x,y| x <=> y}.last
    raise 'File not exist.' unless file_name
    raise 'File not update.' if file_name <= @data['last_synced_file'].to_s
    file_name
  end
end
