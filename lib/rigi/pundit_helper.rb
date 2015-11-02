module Rigi
  module PunditHelper
    module Policy
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def policy_target(target_name)
          @@target_name = target_name.to_s
        end

        #
        # i.e.
        #
        # map_policy :index?, :show?, :update?
        # map_policy :add?, :action_name => :create
        # map_policy :show_maintenance_link?, :delegate_policies => [:index?, :create?]
        #
        def map_policy(*args)
          options = args.extract_options!
          action_defs = args
          target = options[:target] || @@target_name

          action_defs.each do |action_def|
            if options.has_key? :delegate_policies
              define_method("#{action_def}") do 
                options[:delegate_policies].each do |policy_def|
                  return true if send(policy_def)
                end

                false
              end
            else
              action_name = options[:action_name] || action_def.to_s.chomp('?')

              define_method("#{action_def}") do
                send("permitted?", target, action_name)
              end
            end
          end
        end

        def permitted?(system_user, target_name, action)
          permitted = found_permission?(system_user.uid, target_name, action)
          system_user.is_admin? || permitted
        end

        def found_permission?(system_user_uid, target, action)
          permissions = extract_permission(system_user_uid)

          permit_actions = 
            if permissions && permissions.has_key?(target.to_sym)
              permissions[target.to_sym]
            else
              []
            end

          permit_actions.include? action.to_s
        end

        def fetch_permission_from_cache(uid)
          Rails.cache.fetch "#{APP_NAME}:permissions:#{uid}"
        end

        def extract_permission(uid)
          raw = fetch_permission_from_cache(uid)
          # Rails.logger.warn "----- Permission cache not found ------" unless raw_permissions
          raw ? raw[:permissions][:permissions] : nil
        end      
      end

      def permitted?(target_name, action)
        sys_usr = send(:system_user)
        self.class.permitted?(sys_usr, target_name, action)
      end
    end

    module Controller
      #
      # convention:
      #   policy scope/target name as controller resource name
      #   policy action name as controller action/api name
      #
      # e.g.
      # 
      # MaintenancesController#index
      # => policy_target = "maintenance"
      # => action_name = "index"
      #
      # include the following line in MaintenancesController:
      #   before_filter :authorize_action, :only => [:index]
      #
      def authorize_action
        policy_def = "#{action_name}?".to_sym
        policy_target = controller_name.singularize.to_sym
        Rails.logger.info "------ authorize action ------> target = #{policy_target}, action = #{policy_def}"
        authorize policy_target, policy_def
      end
    end
  end
end