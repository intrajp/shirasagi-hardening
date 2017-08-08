class Gws::Schedule::ListPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  menu_view "gws/crud/menu"

  def index
    @items = Gws::Schedule::Plan.site(@cur_site).
      member(@cur_user).
      search(params[:s]).
      order_by(start_at: -1).
      page(params[:page]).per(50)
  end
end
