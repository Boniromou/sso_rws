class DomainsController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'domain_management' }
      format.js { false }
    end
  }

  def index
    authorize :domain, :index?
    @domains = Domain.all
  end

  def create
    authorize :domain, :create?
    actions do
      auditing(audit_action: "create") do
        Domain.insert({name: domain_name})
        flash[:success] = I18n.t("success.create_domain", domain_name: domain_name)
      end
    end
    redirect_to domains_path
  end

  private
  def domain_name
    domain = Domain.find_by_id(domain_id)
    domain_name = domain && domain[:name]
    domain_name ||= params['domain']['name']
    domain_name.downcase
  end

  def domain_id
    params['domain']['id'] if params['domain']
  end

  def actions(locale_key = "domain.#{action_name}", &block)
    info = {domain_name: domain_name}
    begin
      yield
    rescue ActiveRecord::RecordInvalid
      locale_key = "alert.invalid_domain"
      flash[:alert] = I18n.t(locale_key, info)
    end
  end

end
