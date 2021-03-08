module Rigi
  module Excel
    class PermissionUploadHelper
      attr_reader :apps, :workbook, :sheet, :app

      def initialize(file, extname, apps)
        @workbook = Roo::Spreadsheet.open(file, extension: extname)
        @apps = apps.symbolize_keys
      end

      def get_upload_apps
        get_sheets.map{|sheet| sheet.delete('#') }.join(',')
      end

      def get_excel_data
        data = []
        get_sheets.each do |sheet_name|
          @sheet = @workbook.sheet(sheet_name)
          app = @apps[sheet_name.delete('#').to_sym]
          data << {app_name: app[:name], roles: get_roles(app), permissions: get_permissions(app), role_permissions: get_role_permissions(app)}
        end
        data
      end

      private
      def get_sheets
        @workbook.sheets.delete_if {|sheet_name| /^#\w+/.match(sheet_name).to_s != sheet_name || !@apps[sheet_name.delete('#').to_sym] }
      end

      def get_roles(app)
        roles = []
        (3..@sheet.last_column).each do |col_index|
          roles << {
            name: @sheet.column(col_index)[1].strip,
            role_type_id: @sheet.column(col_index)[0],
            app_id: app[:id]
          } if @sheet.column(col_index)[2].present?
        end
        roles
      end

      def get_role_names
        role_names = {}
        (3..@sheet.last_column).each do |col_index|
          role_names[@sheet.column(col_index)[1]] = @sheet.column(col_index)[1] if @sheet.column(col_index)[1].present?
        end
        role_names
      end

      def get_permissions(app)
        permissions = []
        @sheet.each(action: 'action', target: 'target') do |permission|
          permissions << permission.merge({app_id: app[:id], name: permission[:action]}) if permission[:action].present? && permission[:action] != 'action'
        end
        permissions
      end

      def get_role_permissions(app)
        role_columns = get_role_names
        role_permission_data = {grant: [], revoke: []}
        @sheet.each({action: 'action', target: 'target'}.merge(role_columns)) do |row|
          next if row[:action] == 'action'
          role_columns.each_key do |role|
            if row[role] && row[role].split(':')[0] && row[role].split(':')[0].upcase == 'Y'
              role_permission_data[:grant] << {action: row[:action], target: row[:target], role: role.strip, value: row[role].split(':', 2)[1], app_id: app[:id]}
            else
              role_permission_data[:revoke] << {action: row[:action], target: row[:target], role: role.strip, app_id: app[:id]}
            end
          end
        end
        role_permission_data
      end
    end
  end
end
