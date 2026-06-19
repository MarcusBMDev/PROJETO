class Api::UsersController < ApplicationController
  def index
    users = LocalUser.where("status LIKE ? OR status LIKE ?", 'active%', 'ativ%').order(:nome)
    render json: users.as_json(only: [:id, :nome, :username, :department])
  end
end
