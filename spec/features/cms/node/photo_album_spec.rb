require 'spec_helper'

describe "cms_node_photo_album", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node_photo_album, cur_site: site }
  let(:index_path) { node_photo_albums_path site, node }

  context "basic crud" do
    before { login_cms_user }

    it do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq node_nodes_path site, node
    end
  end
end
