module ApplicationHelper
  def logged_in?
    session[:user] != nil
  end
end
