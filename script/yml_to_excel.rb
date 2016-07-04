require 'yaml'
require 'axlsx'

def read_yml(file_name)
  YAML.load_file(file_name)
end

def json_to_excel(json_datas, file_name)
  p = Axlsx::Package.new
  p.workbook.add_worksheet(name: Sheet_name) do |sheet|
    datas = json_datas.values.first
    datas.each do |locale_category, value|
      value.each do |locale_key, translation|
        sheet.add_row [locale_key, locale_category, translation]
      end
    end
  end
  p.serialize(file_name)
end

if ARGV.length < 1
  puts "Usage: ruby script/yml_to_excel.rb <yml_file_name> <excel_file_name> <sheet_name>"
  puts "Example: ruby script/yml_to_excel.rb config/locales/en.yml translation_files/userManagement_Translation_v1.0.xlsx Locale"
  Process.exit
end

Yml_file_name = ARGV[0]
Output_file_name = ARGV[1]
Sheet_name = ARGV[2]

json_datas = read_yml(Yml_file_name)
file_name = Output_file_name
json_to_excel(json_datas, file_name)