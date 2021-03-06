class OauthSessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    account = Account.find_by_provider_and_uid(auth["provider"], auth["uid"])

    if account
      # we have a user associated with this authentication.
      user = account.user
    else
      # there is no user with this authentication.
      # create a new authentication or user.
      user = User.create_with_omniauth(auth)
    end

    session[:user_id] = user.id
    redirect_to "/beta/#/"
  end

  def current_user
    true
  end

  def login

  end

  def destroy
    session.delete(:user_id)
    redirect_to '/'
  end
end
