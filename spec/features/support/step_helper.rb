module StepHelper
  def check_flash_message(msg)
    flash_msg = find("div#flash_message div#message_content")
    expect(flash_msg.text).to eq(msg)
  end
end

RSpec.configure do |config|
  config.include StepHelper, type: :feature
end
