class DomainLicenseesController < ApplicationController
  layout proc { |controller|
    respond_to do |format|
      format.html { 'domain_management' }
      format.js { false }
    end
  }

  def index
    authorize :domain, :index_domain_licensee?
    @domain_licensees = DomainLicensee.includes(:domain, :licensee => [:casinos])
    @list_domain = Domain.all.map {|domain| [domain[:name], domain[:id]]}
    @list_licensee = Licensee.all.map {|licensee| ["#{licensee['name']}[#{licensee['id']}]", licensee['id']]}
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
        DomainLicensee.create!(info)
        flash[:success] = I18n.t("domain_licensee.create_mapping_successfully")
      end
      DomainLicenseeChangeLog.insert_create_domain_licensee(current_system_user, info)
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
      flash[:alert] = e.record.errors.values.first.first
    rescue ActiveRecord::StatementInvalid
      flash[:alert] = I18n.t("domain_licensee.invalid_params")
    end
    redirect_to domain_licensees_path
  end

  def remove
    authorize :domain, :delete_domain_licensee?
    begin
      domain_licensee = DomainLicensee.find(params[:id])
      auditing(audit_action: "delete") do
        domain_licensee.destroy
        flash[:success] = I18n.t("domain_licensee.delete_mapping_successfully")
      end
      DomainLicenseeChangeLog.insert_delete_domain_licensee(current_system_user, {domain_id: domain_licensee.domain_id, licensee_id: domain_licensee.licensee_id})
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = I18n.t("domain_licensee.delete_mapping_fail")
    end
    redirect_to domain_licensees_path
  end
end