require 'roo'
require 'yaml'
require 'fileutils'

if ARGV.length != 3
        puts "Usage: ruby script/generate_i18n_files.rb <translation_file_name> <sheet_name> <output_folder>"
        puts "Example: ruby script/generate_i18n_files.rb tranlsation_files/Keno_Admin_Portal_Translation_V0.8.xlsx admin_portal config/locales"
    Process.exit
end

tranlsation_file_name = ARGV[0]
sheet_name = ARGV[1]
output_folder = ARGV[2]

languages = {:en => 'English'}
#             :zh_CN => 'Simplified Chinese',
#             :zh_TW => 'Traditional Chinese'}

columns = {:locale_key => 'locale_key', :locale_category => 'locale_category'}.merge(languages)

languages.each_key do |lang|
  instance_variable_set("@#{lang}_file", {})
end

s = Roo::Excelx.new(tranlsation_file_name)

s.default_sheet = sheet_name

s.each(columns) do |row|
  languages.each_key do |lang|
     file = instance_variable_get("@#{lang}_file")
     file[row[:locale_category]] ||= {}
     file[row[:locale_category]][row[:locale_key]] = row[lang.to_sym].to_s
  end
end
  
languages.each_key do |lang|
  unless File.directory?(output_folder)
    FileUtils.mkdir_p(output_folder)
  end

  File.open("#{output_folder}/#{lang}.yml",'w') do |f|
    f.write({lang.to_s => instance_variable_get("@#{lang}_file")}.to_yaml)
  end
end 
