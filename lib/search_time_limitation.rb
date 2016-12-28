module SearchTimeLimitation
  extend self
  
  def search_time_range_limitation(start_day_str, end_day_str, search_day_range)
    remark = true
    if start_day_str.blank? && end_day_str.blank?
      start_time = nil
      end_time = nil
    elsif start_day_str.blank?
      end_time = Time.parse(end_day_str).utc + 1.days
      start_time = end_time - search_day_range.days
    elsif end_day_str.blank?
      start_time = Time.parse(start_day_str).utc
      end_time = start_time + search_day_range.days
    else
      remark = false
      start_time = Time.parse(start_day_str).utc
      end_time = Time.parse(end_day_str).utc + 1.days
      if (end_time - start_time) > search_day_range.days
        start_time = nil
        end_time = nil
      end
    end
    return start_time, end_time, remark
  end
end
