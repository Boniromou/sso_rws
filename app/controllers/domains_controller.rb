class DomainsController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'domain_management' }
      format.js { false }
    end
  }

  def index
    authorize :domain, :index_domain_ldap?
    @domains = Domain.includes(:auth_source).all
  end

  def new
    authorize :domain, :create_domain_ldap?
    @domain = Domain.new
    @auth_source = AuthSource.new
  end

  def edit
    authorize :domain, :update_domain_ldap?
    @domain = Domain.find(params[:id])
    @auth_source = @domain.auth_source || AuthSource.new
  end

  def create
    authorize :domain, :create_domain_ldap?
    begin
      auditing(audit_target:"domain_ldap", audit_action: "create") do
        Domain.insert(domain_data, auth_source_data)
        flash[:success] = I18n.t("domain_ldap.create_domain_ldap_success")
      end
      DomainChangeLog.insert_create_domain_ldap(current_system_user, domain_data[:name].strip.downcase)
      redirect_to domains_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      flash[:alert] = e.record.errors.values.first.first
      @domain = Domain.new(domain_data)
      @auth_source = AuthSource.new(auth_source_data)
      render 'new'
    end
  end

  def update
    authorize :domain, :update_domain_ldap?
    domain = Domain.find(domain_data[:id])
    auth_source = domain.auth_source
    begin
      auditing(audit_target:"domain_ldap", audit_action: "edit") do
        domain.edit(auth_source_data)
        flash[:success] = I18n.t("domain_ldap.edit_domain_ldap_success")
      end
      DomainChangeLog.insert_edit_domain_ldap(current_system_user, domain_data[:id], auth_source)
      redirect_to domains_path
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      flash[:alert] = e.record.errors.values.first.first
      @domain = domain
      @auth_source = AuthSource.new(auth_source_data)
      render 'edit'
    end
  end

  private
  def auth_source_data
    params[:domain][:auth_source] || {} if params[:domain]
  end

  def domain_data
    params[:domain][:domain] || {} if params[:domain]
  end
end
