class SftpService

  def sync_user_info
    licensees = Licensee.where('sync_user_strategy IS NOT NULL')
    licensees.each do |lic|
      Rails.logger.info("begin sync user #{lic.id}")
      begin
        strategy = "#{lic.sync_user_strategy.classify}Service".constantize.new(lic)
        strategy.sync_user_info
      rescue StandardError => e
        Rails.logger.error("sync user #{lic.id} error: #{e.message} #{e.backtrace}")
      end
      Rails.logger.info("end sync user #{lic.id}")
    end
  end
end
