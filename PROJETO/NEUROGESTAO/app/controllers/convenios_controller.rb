class ConveniosController < ApplicationController
  def index
    convenios = Convenio.all.order(:nome)
    render json: convenios.as_json(only: [:id, :nome])
  end
end
