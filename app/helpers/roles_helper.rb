module RolesHelper
  def gen_permission_dom(role)
    available_permissions = role.permissions.select([:name, :target]).group_by { |permission| permission.target }
    permissions_by_target = Permission.select([:name, :target]).group_by { |permission| permission.target }
    content_tag :div do
      permissions_by_target.each do |target, permissions|
        concat content_tag(:h1, target.titleize)
        permissions.each do |permission|
          lbl = content_tag(:p) do
            concat permission.name.titleize
            if available_permissions[target].present?
              available_permissions[target].each do |p_v|
                if p_v.name == permission.name
                  concat '<i class="glyphicon glyphicon-ok"></i>'
                  break
                end
              end 
            end
          end
          concat lbl
        end
      end
    end
  end
end
