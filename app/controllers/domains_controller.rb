class DomainsController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'domain_management' }
      format.js { false }
    end
  }

  def index
    authorize :domain, :index_domain_ldap?
    @domains = Domain.includes(:auth_source_detail).all
  end

  def new
    authorize :domain, :create_domain_ldap?
    @domain = Domain.new
    @auth_source_detail = AuthSourceDetail.new
  end

  def edit
    authorize :domain, :update_domain_ldap?
    @domain = Domain.find(params[:id])
    @auth_source_detail = @domain.auth_source_detail
  end

  def create
    authorize :domain, :create_domain_ldap?
    if missing_params?
      flash[:alert] = I18n.t('alert.invalid_params')
      @domain = Domain.new(domain_data)
      auth_source_detail_data.delete('id')
      name = auth_source_detail_data.delete('name')
      @auth_source_detail = AuthSourceDetail.new(:name => name, :data => auth_source_detail_data)
      render 'new'
    else
      begin
        auditing(audit_target:"domain_ldap", audit_action: "create") do
          Domain.insert(domain_data, auth_source_detail_data)
          flash[:success] = I18n.t("domain_ldap.create_domain_ldap_success")
        end
        DomainChangeLog.insert_create_domain_ldap(current_system_user, domain_data[:name].strip.downcase)
        redirect_to domains_path
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        flash[:alert] = e.record.errors.values.first.first
        @domain = Domain.new(domain_data)
        auth_source_detail_data.delete('id')
        name = auth_source_detail_data.delete('name')
        @auth_source_detail = AuthSourceDetail.new(:name => name, :data => auth_source_detail_data)
        render 'new'
      end
    end
  end

  def update
    authorize :domain, :update_domain_ldap?
    domain = Domain.find(domain_data[:id])
    auth_source_detail = domain.auth_source_detail
    if missing_params?
      flash[:alert] = I18n.t('alert.invalid_params')
      @domain = domain
      auth_source_detail_data.delete('id')
      name = auth_source_detail_data.delete('name')
      @auth_source_detail = AuthSourceDetail.new(:name => name, :data => auth_source_detail_data)
      render 'edit'
    else
      begin
        auditing(audit_target:"domain_ldap", audit_action: "edit") do
          domain.edit(auth_source_detail_data)
          flash[:success] = I18n.t("domain_ldap.edit_domain_ldap_success")
        end
        DomainChangeLog.insert_edit_domain_ldap(current_system_user, domain_data[:id], auth_source_detail)
        redirect_to domains_path
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        flash[:alert] = e.record.errors.values.first.first
        @domain = domain
        auth_source_detail_data.delete('id')
        name = auth_source_detail_data.delete('name')
        @auth_source_detail = AuthSourceDetail.new(:name => name, :data => auth_source_detail_data)
        render 'edit'
      end
    end
  end

  private

  def auth_source_detail_data
    params[:domain][:auth_source_detail] || {} if params[:domain]
  end

  def domain_data
    params[:domain][:domain] || {} if params[:domain]
  end

  def missing_params?
    auth_source_detail = params[:domain][:auth_source_detail]
    auth_source_detail[:name].blank? || auth_source_detail[:host].blank? || auth_source_detail[:port].blank? || auth_source_detail[:account].blank? || auth_source_detail[:account_password].blank? || auth_source_detail[:base_dn].blank? || auth_source_detail[:admin_account].blank? || auth_source_detail[:admin_password].blank?
  end
end
