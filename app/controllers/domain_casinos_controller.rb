class DomainCasinosController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'domain_management' }
      format.js { false }
    end
  }

  def index
    authorize :domain_casino, :index?
    @domain_casinos = DomainsCasino.active_domain_casinos
    @list_domain = Domain.all.map {|domain| [domain[:name], domain[:id]]}
    @list_casino = Casino.all.map {|casino| [casino[:name], casino[:id]]}
  end

  def create
    authorize :domain_casino, :create?
    actions do
      info = {domain_id: domain_id, casino_id: casino_id}

      auditing(audit_action: "create") do
        DomainsCasino.insert(info)
        flash[:success] = I18n.t("success.create_domain_casino", domain_name: domain_name, casino_name: casino_name)
      end

      DomainCasinoChangeLog.insert_create_domain_casino(current_system_user, info)
    end
    redirect_to domain_casinos_path
  end

  def inactive
    actions do
      auditing(audit_action: action_name) do
        DomainsCasino.inactive(domain_casino_id)
        flash[:success] = I18n.t("success.inactive_domain_casino", domain_name: domain_name, casino_name: casino_name)
      end

      DomainCasinoChangeLog.insert_inactive_domain_casino(current_system_user, domain_casino_id)
    end
    redirect_to domain_casinos_path
  end

  private
  def domain_casino_id
    return params["domain_casino_id"] if params["domain_casino_id"]
    return params["id"] if params["id"]
  end

  def domain_id
    return params["domain_id"] if params["domain_id"]
    return params['domain']['id'] if params['domain']
  end

  def domain_name
    return params["domain_name"] if params["domain_name"]
    domain = Domain.find_by_id(domain_id)
    domain_name = domain && domain[:name]
    domain_name ||= params['domain']['name'] if params['domain']
    domain_name.downcase if domain_name
  end

  def casino_id
    return params["casino_id"] if params["casino_id"]
    return params["casino"]["id"] if params["casino"]
  end

  def casino_name
    return params["casino_name"] if params["casino_name"]
    casino = Casino.find_by_id(casino_id)
    casino_name = casino && casino[:name]
    casino_name ||= params['casino']['name'] if params['casino']
  end

  def actions(locale_key = "domain_casino.#{action_name}", &block)
    info = {domain_name: domain_name, casino_name: casino_name}
    begin
      yield
    rescue ActiveRecord::RecordNotUnique
      locale_key = "alert.duplicate_domain_casino"
      flash[:alert] = I18n.t(locale_key, info)
    rescue Rigi::DomainCasinoNotFound
      locale_key = "alert.domain_casino_not_found"
      flash[:alert] = I18n.t(locale_key, info)
    end
  end

end
