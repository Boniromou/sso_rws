class LoginHistory < ActiveRecord::Base
  belongs_to :system_user
	belongs_to :domain
	belongs_to :app
  attr_accessible :system_user_id, :domain_id, :app_id, :detail, :sign_in_at
  serialize :detail, JSON
  validates_presence_of :system_user_id, :domain_id, :app_id, :sign_in_at

  scope :since, -> time { where("login_histories.sign_in_at >= ?", time) if time.present? }
  scope :until, -> time { where("login_histories.sign_in_at < ?", time) if time.present? }
  scope :by_system_user_id, -> system_user_id { where(system_user_id: system_user_id) if system_user_id.present? }
  scope :by_domain_id, -> domain_id { where(domain_id: domain_id) if domain_id.present? }
  scope :by_app_id, -> app_id { where(app_id: app_id) if app_id.present? }

  def self.search_query(*args)
    args.extract_options!
    system_user_id, domain_id, app_id, start_time, end_time = args
    self.includes(:system_user, :domain, :app).by_system_user_id(system_user_id).by_domain_id(domain_id).by_app_id(app_id).since(start_time).until(end_time)
  end

  def self.insert(params)
  	params[:sign_in_at] = Time.now.utc
  	create!(params)
	end

  def self.clean_login_history
    last_time = Time.now - (REMAIN_LOGIN_HISTORY_DAYS - 1).days
    Rails.logger.info "Begin to clean login histories: clean sign_in_at before #{last_time}"
    self.where("sign_in_at < ?", last_time.beginning_of_day.utc).delete_all
    Rails.logger.info "End to clean login histories"
  end
end
