class Facility::Agents::Nodes::ServiceController < ApplicationController
  include Cms::NodeFilter::View

  def index
    @items = Facility::Node::Page.site(@cur_site).and_public.
      where(@cur_node.condition_hash).
      order_by(@cur_node.sort_hash)
  end
end
