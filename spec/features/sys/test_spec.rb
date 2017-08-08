require 'spec_helper'

describe "sys_test", type: :feature, dbscope: :example do
  subject(:index_path) { sys_test_path }

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_sys_user }

    it "#index" do
      visit sys_test_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end
  end
end
