module Rigi
  module Searchable
    def search_time_range_limitation(start_day_str, end_day_str, search_day_range)
      remark = true
      if start_day_str.blank? && end_day_str.blank?
        time_now = Time.now
        end_time = Time.parse("#{time_now.year}-#{time_now.month}-#{time_now.day}" + " 23:59:59").utc
        start_time = end_time - search_day_range * 86400
      elsif start_day_str.blank?
        end_time = Time.parse(end_day_str + " 23:59:59").utc
        start_time = end_time - search_day_range * 86400
      elsif end_day_str.blank?
        start_time = Time.parse(start_day_str).utc
        end_time = start_time + search_day_range * 86400
      else
        remark = false
        start_time = Time.parse(start_day_str).utc
        end_time = Time.parse(end_day_str + " 23:59:59").utc
        if ((end_time - start_time) / 86400).to_i > search_day_range
          start_time = nil
          end_time = nil
        end
      end
      return start_time, end_time, remark
    end
  end
end