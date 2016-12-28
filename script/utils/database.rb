class Database
  def self.connect(env)
    mysql_configs = YAML.load_file(File.expand_path(File.dirname(__FILE__)) + '/../../config/database.yml')
    mysqldb = mysql_configs[env]
    sso_db = Sequel.connect(sprintf('%s://%s:%s@%s:%s/%s',
                           mysqldb['adapter'],
                           mysqldb['username'],
                           mysqldb['password'],
                           mysqldb['host'],
                           mysqldb['port'] || 3306,
                           mysqldb['database']), :encoding => mysqldb['encoding'],
                          :loggers => Logger.new($stdout))
  end

end
