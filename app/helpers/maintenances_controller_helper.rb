module MaintenancesControllerHelper
  def duration_day_options
    options = []
    for i in 0..30 do
      options << i
    end
    return options
  end

  def duration_hour_options
    options = [0.5]
    for i in 1..23 do
      options << i
    end
    return options
  end

  def allow_test_account_on
    if @params && @params[:allow_test_account]
      if @params[:allow_test_account].to_i == 1
	return true
      else
	return false
      end
    else
      return true 
    end
  end

  def allow_test_account_off
    if @params && @params[:allow_test_account]
      if @params[:allow_test_account].to_i == 0
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def start_time_default_value
    if @params && @params[:start_time]
      return @params[:start_time]
    else
      return ""
    end
  end

  def end_time_default_value
    if @params && @params[:end_time]
      return @params[:end_time]
    else
      return ""
    end
  end

  def never_end_option
    if @params && @params[:never_end]
      return @params[:never_end]
    else
      return false
    end
  end

  def duration_disabled?
    if @params && @params[:never_end]
      if @params[:never_end]
	return true
      else
	return false
      end
    else
      return false
    end
  end

  def show_duration(seconds)
    if seconds == 0
      return "-"
    else
      return "#{seconds_to_hours(seconds)} hour"
    end
  end
  
  def seconds_to_hours(seconds)
    #[seconds / 3600, seconds / 60 % 60].map { |t| t.to_s.rjust(2,'0') }.join(':')
    (seconds/3600.0).round(2)
  end
  
  def time_format_for(time_to_parse, time_zone_to_display="Beijing")
    #Time.zone = time_zone_to_display
    time_to_parse.in_time_zone(time_zone_to_display).strftime("%Y-%m-%d %H:%M")
  end

  def propagation_timestamp_for_status(propagation)
    case propagation.status
      when "propagating"
        propagation.propagating_at
      when "propagated"
        propagation.propagated_at
      when "broken"
        propagation.broken_at
      when "cancelled"
        propagation.cancelled_at
      else
        nil
    end
  end
  
  def display_allow_test_acc_val(allow_test_acc)
    allow_test_acc ? "maintenance.allow_test_account_value" : "maintenance.disallow_test_account_value"
  end

  def display_status(status)
    case status
      when "scheduled"
        "maintenance_status.scheduled"
      when "activating"
        "maintenance_status.activating"
      when "activated"
        "maintenance_status.activated"
      when "completing"
        "maintenance_status.completing"
      when "completed"
        "maintenance_status.completed"
      when "cancelling"
        "maintenance_status.cancelling"
      when "cancelled"
        "maintenance_status.cancelled"
      when "expired"
        "maintenance_status.expired"
      else
        nil
    end
  end
  
=begin
  def timestamp_for_status(maintenance)
    case maintenance.status
      when "scheduled"
        maintenance.created_at
      when "cancelled"
        maintenance.cancelled_at
      when "completed"
        maintenance.completed_at
      when "expired"
        maintenance.expired_at
      else
        maintenance.created_at
    end
  end
=end
end
