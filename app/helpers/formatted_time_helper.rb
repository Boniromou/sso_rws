module FormattedTimeHelper
  def timezone_name
    current_system_user.timezone_name
  end

  def user_timezone
    current_system_user.timezone
  end

  def format_time(time)
    time.in_time_zone(timezone_name).strftime("%Y-%m-%d %H:%M:%S") if time.present?
  rescue Exception
    Time.parse(time).in_time_zone(timezone_name).strftime("%Y-%m-%d %H:%M:%S")
  end

  def format_date(time)
    time.in_time_zone(timezone_name).strftime("%Y-%m-%d")
  end

  def parse_date(date_str, is_end = false)
    return if date_str.blank?
    time = user_timezone.local_to_utc(Time.parse("#{date_str} 00:00:00"))
    time = time + 1.days if is_end
    time
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
