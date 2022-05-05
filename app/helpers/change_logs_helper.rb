module ChangeLogsHelper
  def target_casinos_format(target_casinos)
    return '' if target_casinos.blank?
    rtn = ""
    target_casinos.each do |target_casino|
      rtn += " [#{target_casino[:target_casino_name]}, #{target_casino[:target_casino_id]}]," 
    end
    rtn = rtn.chomp(',')
  end
end
