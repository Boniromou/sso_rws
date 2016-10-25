class SystemUsersController < ApplicationController
  layout proc {|controller| controller.request.xhr? ? false: "user_management" }
  respond_to :html, :js

  def new
    authorize :system_users, :new?
    @domains = policy_scope(Domain) 
    @errors = params[:errors] if params[:errors].present?
  end

  def create
    authorize :system_users, :create?

    begin
      username = params[:system_user][:username].strip.downcase if params[:system_user][:username].present?
      domain = params[:system_user][:domain].downcase if params[:system_user][:domain].present?
      auditing do
        SystemUser.create_by_username_and_domain!(username, domain)       
        flash[:success] = I18n.t("success.create_user", :username => (username + '@' + domain)) 
      end 
      SystemUserChangeLog.create_system_user(:current_user => current_system_user, :username => username, :domain => domain)
    rescue Rigi::InvalidUsername, Rigi::InvalidDomain => e
      Rails.logger.error "SystemUser[username=#{params[:system_user][:username]} , domain=#{params[:system_user][:domain]}] illegal format"
      @errors = e.error_message 
    rescue Rigi::RegisteredAccount, Rigi::AccountNotInLdap, Rigi::AccountNoCasino => e
      Rails.logger.error "SystemUser[username=#{params[:system_user][:username]} , domain=#{params[:system_user][:domain]}] create failed: #{e.error_message}"
      flash[:alert] = e.error_message
    end  
    redirect_to new_system_user_path({:errors => @errors}) 
  end

  def index
    @system_users = policy_scope(SystemUser.includes(:casinos))
    authorize :system_users, :index?
  end

  def export
    authorize :system_users, :index?
    respond_to do |format|
      format.xls do
        current_time = Time.now.strftime("%Y-%m-%d %H-%M-%S")
        send_data get_export_user_role_info, :type => :xls, :filename => I18n.t("user.export_file_name", :current_time => current_time)
      end
    end
  end

  def show
    @system_user = SystemUser.find_by_id(params[:id])
    authorize @system_user, :show?
  end

  def edit_roles
    @system_user = SystemUser.find_by_id(params[:id])
    authorize @system_user, :edit_roles?
    apps = App.all
    roles = policy_scope(Role)

    @roles_by_apps = apps.map do |app|
      ros = roles.find_all { |role| role.app_id == app.id }
      {:app => app, :roles => ros }
    end

    @current_role_ids = @system_user.role_assignments.select(:role_id).map { |role_asm| role_asm.role_id }
    @current_app_ids = @system_user.app_system_users.select(:app_id).map { |app_asm| app_asm.app_id }
  end

  def update_roles
    @system_user = SystemUser.find_by_id(params[:id])
    authorize @system_user, :update_roles?
    unless @system_user.active_casino_ids.any?
      flash[:alert] = I18n.t("alert.account_no_casino")
      redirect_to system_user_path(@system_user)
      return
    end

    roles = Role.find(role_ids_param)

    roles.each do |role|
      authorize role, :allow_to_assign?
    end

    prev_role_ids = @system_user.roles.pluck(:id)

    auditing(:audit_action => "edit_role") do
      @system_user.update_roles(role_ids_param)
      flash[:success] = I18n.t("success.edit_role", :user_name => @system_user.username)
    end

    bulk_create_change_log(@system_user, "edit_role", prev_role_ids, role_ids_param)
    redirect_to system_user_path(@system_user)
  end

  private
  def role_ids_param
    role_ids = App.all.map do |app|
      v = params[app.name.to_sym]
      v ? v.to_i : nil
    end
    
    role_ids.compact.uniq
  end

  def bulk_create_change_log(system_user, action, from_role_ids, to_role_ids)
    prev_roles = Role.find(from_role_ids).group_by {|role| role.app_id}
    next_roles = Role.find(to_role_ids).group_by {|role| role.app_id}
    apps = App.all

    apps.each do |app|
      prev_role = prev_roles[app.id] ? prev_roles[app.id].first : nil
      next_role = next_roles[app.id] ? next_roles[app.id].first : nil

      # skip when the original and current are identical
      next if prev_role && next_role && (prev_role.id == next_role.id)
      next if prev_role.nil? && next_role.nil?

      prev_role_name = prev_role ? prev_role.name : nil
      next_role_name = next_role ? next_role.name : nil

      create_change_log(system_user, action, app.name, prev_role_name, next_role_name)
    end
  end

  def create_change_log(system_user, action, app_name, from, to)
    system_user.active_casino_ids.each do |target_casino_id|
      cl = SystemUserChangeLog.new
      cl.target_username = system_user.username
      cl.target_domain = system_user.domain.name
      cl.action = action
      cl.action_by[:username] = current_system_user.username
      cl.action_by[:casino_ids] = current_system_user.active_casino_ids
      cl.action_by[:casino_id_names] = current_system_user.active_casino_id_names
      cl.change_detail[:app_name] = app_name
      cl.change_detail[:from] = from
      cl.change_detail[:to] = to
      cl.save!

      cl.target_casinos.create(:target_casino_id => target_casino_id, :target_casino_name => Casino.find(target_casino_id).name)
    end
  end

  def get_export_user_role_info
    apps = App.get_all_apps
    role_types = RoleType.get_all_role_types
    system_users = policy_scope(SystemUser.get_export_system_users)
    casinos = CasinosSystemUser.get_users_active_casinos
    
    excel = Spreadsheet::Workbook.new
    sheet1 = excel.create_worksheet
    sheet1.row(0).concat ["#{I18n.t("user.export_role_type_tip")}"]
    title = [I18n.t("user.user_name"), I18n.t("user.status"), I18n.t("user.casino_groups"), I18n.t("general.updated_at")].concat(apps.values)
    sheet1.row(1).concat title
    
    format_row = Spreadsheet::Format.new :horizontal_align => :center, :border => :thin
    columns_count = title.size
    
    system_users.each_with_index do |su, index|
      row_columns = []
      row_columns << "#{su['username']}@#{su['domain_name']}"
      row_columns << I18n.t(ApplicationController.helpers.system_user_status_format(su["status"]))
      row_columns << ApplicationController.helpers.casino_id_names_format(casinos[su["id"]])
      row_columns << ApplicationController.helpers.format_time(su.updated_at)
      roles = su.roles.map {|role| {role.app_id => "#{role.name.titleize}#{role_types[role.role_type_id]}"}}.inject(:merge) || {}
      apps.keys.each do |app_id|
        row_columns << (roles[app_id] || '-')
      end

      sheet1.row(index + 2).concat row_columns
      columns_count.times do |col|
        sheet1.row(index + 2).set_format(col, format_row)
      end
    end

    set_title_format(sheet1)
    blob = StringIO.new('')
    excel.write blob
    blob.string
  end

  def set_title_format(sheet1)
    format_title = Spreadsheet::Format.new :weight => :bold, :horizontal_align => :center, :border => :thin
    col_widths = [30, 10, 50, 20]
    sheet1.column_count.times do |col|
      sheet1.row(1).set_format(col, format_title)
      sheet1.column(col).width = col > 3 ? 22 : col_widths[col]
    end
  end
end
