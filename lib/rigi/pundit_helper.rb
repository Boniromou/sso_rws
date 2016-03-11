module Rigi
  module PunditHelper
    module Policy
      def self.included(base)
        base.send :extend, ClassMethods
      end

      module ClassMethods
        def target_name
          @@target_name
        end

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
      end

      def found_permission?(system_user_uid, target, actions)
        permissions = extract_permission(system_user_uid)

        permit_actions =
          if permissions && permissions.has_key?(target.to_sym)
            permissions[target.to_sym]
          else
            []
          end

        #Rails.logger.debug 'found_permission???????????????'
        #Rails.logger.debug permit_actions
        #Rails.logger.debug target
        #Rails.logger.debug actions

        actions = format_array(actions)
        actions.map!{ |action| action.to_s }

        intersect = permit_actions & actions
        !intersect.empty?
      end

      def fetch_permission_from_cache(uid)
        Rails.cache.fetch "#{APP_NAME}:permissions:#{uid}"
      end

      def extract_permission(uid)
        raw = fetch_permission_from_cache(uid)
        # Rails.logger.warn "----- Permission cache not found ------" unless raw_permissions
        raw ? raw[:permissions][:permissions] : nil
      end

      def format_array(item)
        case item
        when nil
          []
        when Array
          item
        else
          [item]
        end
      end

      def get_user
        send(:system_user)
      end

      def get_record
        send(:record)
      end

      def get_record_casino_ids
        record = get_record
        return [] if record.blank? || record.is_a?(Symbol) || record.id == nil
        return [record.id] if record.is_a? Casino
        return [record.casino_id] if record.respond_to?(:casino_id)
        return [record.casino.id] if record.response_to?(:casino)

        ids = []
        if record.response_to?(:casinos)
          record.casinos.each { |casino| ids << casino.id }
        end
        ids
      end

      def same_scope?(target_casino_ids=nil)
        user_casino_ids = format_array(system_user.active_casino_ids)
        target_casino_ids = format_array(target_casino_ids || get_record_casino_ids)

        Rails.logger.debug "user's casinos => #{user_casino_ids}, target's casinos => #{target_casino_ids}"

        user_casino_ids.each do |user_casino_id|
          target_casino_ids.each do |target_casino_id|
            return true if user_casino_id.to_s == target_casino_id.to_s
          end
        end

        false
      end
    end
  end
end