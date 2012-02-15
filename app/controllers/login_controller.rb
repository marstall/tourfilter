  class LoginController < ApplicationController

  def login_header
    render(:layout => false)
  end
  def logged_in_header
    render(:layout => false)
  end
end
