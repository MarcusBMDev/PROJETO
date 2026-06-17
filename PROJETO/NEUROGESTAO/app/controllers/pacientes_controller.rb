class PacientesController < ApplicationController
  def index
    pacientes = Paciente.all.order(:nome)
    render json: pacientes.as_json(only: [:id, :nome])
  end
end
