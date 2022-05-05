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
          @app = @apps[sheet_name.delete('#').to_sym]
          data << {app_name: @app[:name], roles: get_roles, permissions: get_permissions, role_permissions: get_role_permissions}
        end
        data
      end

      private
      def get_sheets
        @workbook.sheets.delete_if {|sheet_name| /^#\w+/.match(sheet_name).to_s != sheet_name || !@apps[sheet_name.delete('#').to_sym] }
      end

      def get_roles
        roles = []
        (3..@sheet.last_column).each do |col_index|
          name = @sheet.column(col_index)[1].strip_all
          roles << {
            name: name,
            role_type_id: @sheet.column(col_index)[0].to_s.strip,
            app_id: @app[:id]
          } if name.present?
        end
        roles
      end

      def get_header_names
        role_names = {}
        (3..@sheet.last_column).each do |col_index|
          name = @sheet.column(col_index)[1]
          role_names[name] = name if name.present?
        end
        role_names
      end

      def get_permissions
        permissions = []
        @sheet.each(action: 'action', target: 'target') do |permission|
          action = permission[:action].strip_all
          permissions << {app_id: @app[:id], name: action, target: permission[:target].strip_all, action: action} if action.present? && action != 'action'
        end
        permissions
      end

      def get_role_permissions
        role_columns = get_header_names
        role_permission_data = {grant: [], revoke: []}
        @sheet.each({action: 'action', target: 'target'}.merge(role_columns)) do |row|
          action = row[:action].strip_all
          next if action == 'action'
          role_columns.each_key do |role|
            if row[role] && row[role].split(':')[0] && row[role].split(':')[0].upcase == 'Y'
              role_permission_data[:grant] << {action: action, target: row[:target].strip_all, role: role.strip_all, value: row[role].split(':', 2)[1], app_id: @app[:id]}
            else
              role_permission_data[:revoke] << {action: action, target: row[:target].strip_all, role: role.strip_all, app_id: @app[:id]}
            end
          end
        end
        role_permission_data
      end
    end
  end
end
