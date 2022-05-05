require 'openssl'
require File.expand_path(File.dirname(__FILE__) + "/base")

class Requester::Usdms < Requester::Base
  def login(username, password, key)
    password = encrypt_password(key, password)
    response = remote_rws_call('post', "#{@path}/login",
      :body => {:username => username, :password => password})
    parse_response(response)
  end

  def retrieve_user(username)
    response = remote_rws_call('post', "#{@path}/retrieve_user",
      :body => {:username => username})
    parse_response(response)
  end

  def change_password(username, old_password, password, key)
    old_password = encrypt_password(key, old_password)
    password = encrypt_password(key, password)
    response = remote_rws_call('post', "#{@path}/change_password",
      :body => {:username => username, :old_password => old_password, :password => password})
    parse_change_password_response(response)
  end

  protected
  def encrypt_password(key, password)
    cipher = OpenSSL::Cipher.new('AES-256-CBC').encrypt
    cipher.key = key
    s = cipher.update(password) + cipher.final
    s.unpack('H*')[0].upcase
  end

  def parse_response(response)
    result = JSON.parse(response.body)
    raise Rigi::MustChangePassword.new('alert.must_change_password') if result['code'] == 'MustChangePassword'
    raise Rigi::InvalidAccount.new('alert.invalid_login') if result['code'] != 'OK'
    return result
  end

  def parse_change_password_response(response)
    result = JSON.parse(response.body)
    raise Rigi::InvalidPassword.new('alert.invalid_login') if result['code'] == 'InvalidPassword'
    raise Rigi::InvalidPasswordFormat.new('password_page.invalid_password_format') if result['code'] == 'InvalidPasswordFormat'
    raise Rigi::InvalidResetPassword.new('password_page.change_password_fail') if result['code'] != 'OK'
    return result
  end
end
