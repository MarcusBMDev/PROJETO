class ListaEsperasController < ApplicationController
  def index
    lista = ListaEspera.all.order(created_at: :desc)
    render json: lista
  end

  def create
    item = ListaEspera.new(lista_espera_params)
    if item.save
      render json: item, status: :created
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    item = ListaEspera.find(params[:id])
    item.destroy
    render json: { mensagem: "Removido da lista de espera com sucesso!" }
  end

  private

  def lista_espera_params
    params.require(:lista_espera).permit(:nome, :telefone, :especialidade, :observacao)
  end
end
