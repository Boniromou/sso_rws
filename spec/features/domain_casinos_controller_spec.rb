require "feature_spec_helper"

describe DomainCasinosController do
  require Rails.root.join("spec/features/helper/domain_casinos_controller_spec_helper.rb")
  include DomainCasinosControllerSpecHelper

  describe "[20] List Domain Casino mapping" do
    it "[20.1] No permission for list domain casino mapping" do
      login(user_without_domain_casino_list)
      visit home_root_path
      click_link_or_button("Home")
      expect(has_css?("#domain_management_link")).to eq false
    end

    it "[20.2] List domain casino mapping without create and delete permission" do
      login(user_with_domain_casino_list)
      visit domain_casinos_path

      expect(has_css?("select#domain_id")).to eq false
      expect(has_css?("select#casino_id")).to eq false
      expect(has_css?("button#create_domain_casino")).to eq false
      expect(has_css?("#delete")).to eq false
    end

    it "[20.3] list domain casino mapping with create permission" do
      login(user_with_domain_casino_create)
      visit domain_casinos_path

      expect(has_css?("select#domain_id")).to eq true
      expect(has_css?("select#casino_id")).to eq true
      expect(has_css?("button#create_domain_casino")).to eq true
    end
  end

  describe "[21] Create Domain Casino mapping" do
    before :each do
      before_create_domain_casino
    end

    it "[21.1] Create domain casino success" do
      general_create_domain_casino
      check_flash_message(I18n.t('success.create_domain_casino', {domain_name: @domain_name, casino_name: @casino_name}))
      check_domain_casino
    end

    it "[21.2] Create domain casino mapping fail with duplicated record" do
      create(:domains_casino, domain_id: @domain_1003.id, casino_id: @casino_mockup.id)
      general_create_domain_casino
      check_flash_message(I18n.t('alert.duplicate_domain_casino', {domain_name: @domain_name, casino_name: @casino_name}))
    end

    it "[21.3] Create domain casino mapping success audit log" do
      general_create_domain_casino
      filters = {
        audit_target: 'domain_casino_mapping',
        action_type: 'create',
        action: 'create',
        action_status: 'success',
        action_by: user_with_domain_casino_create.username
      }
      expect(AuditLog.where(filters)).not_to eq nil
    end

    it "[21.4] Create domain casino mapping failed audit log" do
      create(:domains_casino, domain_id: @domain_1003.id, casino_id: @casino_mockup.id)
      general_create_domain_casino
      filters = {
        audit_target: 'domain_casino_mapping',
        action_type: 'create',
        action: 'create',
        action_status: 'fail',
        action_by: user_with_domain_casino_create.username
      }
      expect(AuditLog.where(filters)).not_to eq nil
    end
  end

  describe "[22] Delete Domain Casino Mapping" do
    before :each do
      before_inactive_domain_casino
    end

    it "[22.1] Delete Domain Casino Mapping success" do
      delete_domain_casino_success
    end

    it "[22.2] delete domain casino mapping failed with record updated" do
      delete_domain_casino_failed
    end

    it "[22.3] delete domain casino mapping success audit log" do
      delete_domain_casino_success
      filters = {
        audit_target: 'domain_casino_mapping',
        action_type: 'delete',
        action: 'create',
        action_status: 'success',
        action_by: user_with_domain_casino_inactive.username
      }
      expect(AuditLog.where(filters)).not_to eq nil
    end

    it "[22.4] delete domain casino mapping failed audit log" do
      delete_domain_casino_failed
      filters = {
        audit_target: 'domain_casino_mapping',
        action_type: 'delete',
        action: 'create',
        action_status: 'success',
        action_by: user_with_domain_casino_inactive.username
      }
      expect(AuditLog.where(filters)).not_to eq nil
    end
  end

  describe "[23] Domain Casino Mapping change log" do
    it "[23.1] No permission for List Domain casino mapping change log" do
      login(user_with_domain_casino_list)
      visit domain_casinos_path
      expect(has_text?(I18n.t("general.log"))).to eq false
    end

    it "[23.2] List Domain casino mapping change log" do
      login(user_with_domain_casino_change_log)
      visit change_logs_create_domain_casinos_path
      locale_keys = ['domain.name', 'casino.title', 'general.action', 'general.action_at', 'general.action_by']
      locale_keys.each do |lk|
        expect(has_text?(I18n.t(lk))).to eq true
      end
    end

    it "[23.3] Create change log for create domain casino mapping" do
      login(user_with_admin)
      before_create_domain_casino
      general_create_domain_casino

      visit change_logs_create_domain_casinos_path
      infos = {
        domain: @domain_name,
        casino: @casino_name,
        action: 'Create',
        action_by: user_with_admin.username
      }
      expect(check_change_log?(infos)).to eq true
    end

    it "[23.4] Create change log for delete domain casino mapping" do
      login(user_with_admin)
      before_inactive_domain_casino
      delete_domain_casino_success

      visit change_logs_create_domain_casinos_path
      infos = {
        domain: @domain_name,
        casino: @casino_name,
        action: 'Delete',
        action_by: user_with_admin.username
      }
      expect(check_change_log?(infos)).to eq true
    end
  end
end