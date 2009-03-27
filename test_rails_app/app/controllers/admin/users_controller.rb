class Admin::UsersController < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
    a.actions << :destroy
    
    # If you're in a hurry you don't have to send this to the form builder
    # object
    a.inputs[:state] = :us_state
  end
  
  protected
  
  # Run before a user is created
  def before_create(user)
    user.reset_password
  end
  
  # If 'reset_password' is checked, reset the password
  def before_update(user)
    if params[:reset_password]
      user.reset_password
    end
  end
end
