require 'spec_helper'

describe "gws_portal", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_portal_path site }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end
  end
end
