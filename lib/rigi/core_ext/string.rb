module CoreExtension
  module String
    module InstanceMethods
      def to_start_date
        to_time(:local).beginning_of_day.utc.to_s
      end

      def to_end_date
        to_time(:local).end_of_day.utc.to_s
      end

      def strip_all
        self.gsub(/\s/, "")
      end
    end
  end
end
