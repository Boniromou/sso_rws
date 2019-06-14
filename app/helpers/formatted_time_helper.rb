module FormattedTimeHelper
  def user_timezone
    current_system_user.timezone
  end

  def format_time(time)
    begin
      unless time.blank?
        time.to_time.getlocal(user_timezone).strftime("%Y-%m-%d %H:%M:%S")
      end
    rescue Exception
      Time.parse("#{time} #{user_timezone}").strftime("%Y-%m-%d %H:%M:%S")
    end
  end

  def format_date(time)
    time.to_time.getlocal(user_timezone).strftime("%Y-%m-%d")
  end

  def parse_date(date_str, is_end = false)
    return if date_str.blank?
    time = Time.parse("#{date_str} 00:00:00 #{user_timezone}", "%Y-%m-%d %H:%M:%S %Z")
    time = time + 1.days if is_end
    time.utc
  end

  def format_time_range(start_day_str, end_day_str, search_day_range)
    remark = false
    return nil, nil, remark if start_day_str.blank? && end_day_str.blank?
    start_time = parse_date(start_day_str)
    end_time = parse_date(end_day_str, true)
    if start_time.nil? || end_time.nil?
      remark = true
      start_time = end_time - search_day_range.days unless start_time
      end_time = start_time + search_day_range.days unless end_time
    end

    return nil, nil, remark if end_time - start_time > search_day_range.days
    return start_time, end_time, remark
  end
end
