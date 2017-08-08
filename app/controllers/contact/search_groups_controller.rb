class Contact::SearchGroupsController < ApplicationController
  include Cms::ApiFilter

  model Cms::Group

  def index
    @items = @model.site(@cur_site).
      search(params[:s]).
      page(params[:page]).per(50)
  end
end
