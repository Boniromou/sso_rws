class DomainLicenseesController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'domain_management' }
      format.js { false }
    end
  }

  def index
    authorize :domain, :index_domain_licensee?
    @domain_licensees = Licensee.includes(:domain, :casinos).active_domain_licensee.as_json(:include => ['domain', 'casinos'])
    @list_domain = Domain.all.map {|domain| [domain[:name], domain[:id]]}
    @list_licensee = Licensee.inactive_domain_licensee.map {|licensee| ["#{licensee['name']}[#{licensee['id']}]", licensee['id']]}
  end

  def get_casinos
    casinos = Casino.where(licensee_id: params[:licensee_id]).select(%w(id name)).as_json
    render :json => ApplicationController.helpers.casino_id_names_format(casinos)
  end

  def create
    authorize :domain, :create_domain_licensee?
    info = {domain_id: params[:domain_id], licensee_id: params[:licensee_id]}
    begin
      auditing(audit_action: "create") do
        Licensee.create_domain_licensee(info)
        flash[:success] = I18n.t("domain_licensee.create_mapping_successfully")
      end
      DomainLicenseeChangeLog.insert_create_domain_licensee(current_system_user, info)
    rescue Rigi::CreateDomainLicenseeFail => e
      Rails.logger.error e.error_message
      flash[:alert] = e.error_message
    end
    redirect_to domain_licensees_path
  end

  def remove
    authorize :domain, :delete_domain_licensee?
    info = {domain_id: params[:domain_id], licensee_id: params[:licensee_id]}
    begin
      auditing(audit_action: "delete") do
        Licensee.remove_domain_licensee(info)
        flash[:success] = I18n.t("domain_licensee.delete_mapping_successfully")
      end
      DomainLicenseeChangeLog.insert_delete_domain_licensee(current_system_user, info)
    rescue Rigi::DeleteDomainLicenseeFail => e
      Rails.logger.error e.error_message
      flash[:alert] = e.error_message
    end
    redirect_to domain_licensees_path
  end
end