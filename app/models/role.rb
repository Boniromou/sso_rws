class Role < ActiveRecord::Base
  has_many :role_assignments, :dependent => :destroy
  has_many :system_users, :through => :role_assignments, :source => :user, :source_type => 'SystemUser'
  has_many :role_permissions
  has_many :permissions, :through => :role_permissions
  belongs_to :app
  belongs_to :role_type

  def has_permission?(target, action)
    result = self.permissions.collect{|x| {:action => x.action, :target => x.target}}.include?({:action => action, :target => target})
    Rails.logger.info "has_permission? on #{target} and #{action}: #{result.present?}"
    result
  end

  def get_permission_value(target, action)
    role_permission = self.role_permissions.select{|role_permission| role_permission.permission.target == target && role_permission.permission.action == action}.first
    role_permission.value if role_permission
  end

  def self.target_permissions(role_id)
    perm_hash ={}
    role = self.find_by_id(role_id)
    role.permissions.each do |perm|
      if perm_hash.has_key?(perm.target.to_sym)
        perm_hash[perm.target.to_sym] << perm.action unless perm_hash[perm.target.to_sym].include? perm.action
      else
        perm_hash[perm.target.to_sym] = [perm.action]
      end
    end
    perm_hash
  end

  def self.get_apps_roles
    rtn = {}
    role_types = RoleType.get_all_role_types
    Role.includes(:permissions).each do |role|
      rtn[role.app_id] = [] if rtn[role.app_id].blank?
      rtn[role.app_id].push({"name" => "#{role.name.titleize}(#{role_types[role.role_type_id]})", "permissions" => role.permissions.map(&:id)})
    end
    rtn
  end

  def self.get_export_role_pessmission
    apps = App.all
    apps_roles = get_apps_roles
    apps_permissions = Permission.get_all_permissions

    format_title = Spreadsheet::Format.new :weight => :bold, :horizontal_align => :center, :vertical_align => :middle, :border => :thin
    format_row = Spreadsheet::Format.new :horizontal_align => :center, :vertical_align => :middle, :border => :thin
    excel = Spreadsheet::Workbook.new
    apps.each do |app|
      title = [I18n.t("general.action"), I18n.t("permission.target")]
      permissions_targets = apps_permissions[app["id"]] || {}
      roles = apps_roles[app["id"]] || []
      roles.each do |role|
        title << role['name'].titleize
      end

      sheet1 = excel.create_worksheet :name => app['name'].titleize
      sheet1.row(0).concat ["#{I18n.t("role.system")}: #{app['name'].titleize}"]
      sheet1.row(1).concat ["**#{I18n.t("user.export_role_type_tip")}"]
      sheet1.row(2).concat title
      columns_count = title.size

      index = 3
      permissions_targets.each do |target, permissions|
        permissions = permissions || []
        sheet1.merge_cells(index, 1, (index + permissions.size - 1), 1) if permissions.size > 1
        permissions.each do |permission|
          row_columns = []
          row_columns << permission['action'].titleize
          row_columns << permission['target'].titleize
          roles.each do |role|
            row_columns << (role['permissions'].include?(permission['id']) ? I18n.t("role.has_permission") : "")
          end

          sheet1.row(index).concat row_columns
          columns_count.times do |col|
            sheet1.row(index).set_format(col, format_row)
          end
          index += 1
        end
      end

      columns_count.times do |col|
        sheet1.row(2).set_format(col, format_title)
        sheet1.column(col).width = 20
      end
    end

    blob = StringIO.new('')
    excel.write blob
    blob.string
  end
end
