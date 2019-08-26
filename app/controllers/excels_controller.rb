class ExcelsController < ApplicationController
  include FormattedTimeHelper
  include ChangeLogsHelper
  include ApplicationHelper
  include SystemUsersControllerHelper

  HEAD_FORMAT = Spreadsheet::Format.new :weight => :bold, :size => 14, :horizontal_align => :left, :vertical_align => :centre
  TIP_FORMAT = Spreadsheet::Format.new :size => 11, :horizontal_align => :left, :vertical_align => :centre
  TITLE_FORMAT = Spreadsheet::Format.new :weight => :bold, :size => 9, :horizontal_align => :centre, :vertical_align => :centre, :pattern_fg_color => :silver  , :pattern => 1
  TEXT_FORMAT = Spreadsheet::Format.new :size => 9, :horizontal_align => :centre, :vertical_align => :centre

  def create_system_user_log
    logs = get_create_user_logs
    page_to_excel("SSO_CreateSystemUserLog") do |sheet|
      sheet.row(0).default_format = HEAD_FORMAT
      sheet.row(1).default_format = TIP_FORMAT
      sheet.row(0).push("Create System User Log")
      sheet.row(1).concat(["Last updated at",  format_time(Time.now)])

      title = %W( System\ User Casinos Action Action\ at Action\ by Casinos )
      title.count.times.each { |i|  sheet.row(3).set_format(i, TITLE_FORMAT) }
      sheet.row(3).concat(title)
      logs.each_with_index do |log, index|
        sheet.row(4 + index).default_format = TEXT_FORMAT
        sheet.row(4 + index).concat([
          (log.target_username || "") + (log.target_domain ? ('@'+log.target_domain) : ""),
          target_casinos_format(log.target_casinos),
          display_text(log.action),
          format_time(log.created_at),
          log.action_by['username'],
          casino_id_names_format(log.action_by['casino_id_names'])
        ])
      end
    end
  end

  def system_user_log
    logs = get_edit_role_logs
    page_to_excel("SSO_SystemUserLog") do |sheet|
      sheet.row(0).default_format = HEAD_FORMAT
      sheet.row(1).default_format = TIP_FORMAT
      sheet.row(0).push("System User Log")
      sheet.row(1).concat(["Last updated at",  format_time(Time.now)])

      title = %W( Action\ by Casinos Action\ at Action System\ User  Casinos System From To )
      title.count.times.each { |i|  sheet.row(3).set_format(i, TITLE_FORMAT) }
      sheet.row(3).concat(title)
      logs.each_with_index do |log, index|
        sheet.row(4 + index).default_format = TEXT_FORMAT
        sheet.row(4 + index).concat([
          log.action_by['username'],
          casino_id_names_format(log.action_by['casino_id_names']),
          format_time(log.created_at),
          display_text(log.action),
          (log.target_username || "") + (log.target_domain ? ('@'+log.target_domain) : ""),
          target_casinos_format(log.target_casinos),
          display_text(log.change_detail['app_name']),
          display_text(log.change_detail['from']),
          display_text(log.change_detail['to'])
        ])
      end
    end
  end

  def login_history
    historires =  get_login_histories
    page_to_excel("SSO_LoginHistory") do |sheet|
      sheet.row(0).default_format = HEAD_FORMAT
      sheet.row(1).default_format = TIP_FORMAT
      sheet.row(0).push("Login History")
      sheet.row(1).concat(["Last updated at",  format_time(Time.now)])

      title = %W(System\ User Casinos System Login\ Time )
      title.count.times.each { |i|  sheet.row(3).set_format(i, TITLE_FORMAT) }
      sheet.row(3).concat(title)
      historires.each_with_index do |history, index|
        sheet.row(4 + index).default_format = TEXT_FORMAT
        sheet.row(4 + index).concat([
          "#{history.system_user.username}@#{history.domain.name}",
          casino_id_names_format(history.detail['casino_id_names']),
          history.app.try(:name).to_s.titleize,
          format_time(history.sign_in_at)
        ])
      end
    end
  end

  private
  def page_to_excel(filename, &block)
    string_io = StringIO.new
    xls = Spreadsheet::Workbook.new
    sheet = xls.create_worksheet(name: filename)
    block.call(sheet)
    xls.write string_io
    send_data string_io.string, :filename => "#{filename}.xls", :type =>  "application/vnd.ms-excel"
  end

  def get_create_user_logs
    start_time = parse_date(params[:export_start_time])
    end_time = parse_date(params[:export_end_time], true)
    policy_scope(SystemUserChangeLog.by_action('create').search_query('', start_time, end_time))
  end

  def get_edit_role_logs
    start_time = parse_date(params[:export_start_time])
    end_time = parse_date(params[:export_end_time], true)
    policy_scope(SystemUserChangeLog.by_action('edit_role').search_query(params[:export_username], start_time, end_time))
  end

  def get_login_histories
    start_time, end_time, remark = format_time_range(params[:export_start_time], params[:export_end_time], SEARCH_RANGE_FOR_LOGIN_HISTORY)
    return [] if start_time.nil? || end_time.nil?
    if params[:export_username].present?
      system_user = SystemUser.find_by_username_with_domain(params[:export_username])
      return [] unless system_user
      system_user_id = system_user.id
      domain_id = system_user.domain_id
    end
    policy_scope(LoginHistory.search_query(system_user_id, domain_id, params[:export_app_id], start_time, end_time))
  end
end
