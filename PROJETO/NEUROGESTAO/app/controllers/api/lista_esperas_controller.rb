class Api::ListaEsperasController < ApplicationController
  before_action :validar_acesso_gestao!, except: [:index]
  include SugestaoAgendamento

  def index
    lista = ListaEspera.all.order(created_at: :desc)
    render json: lista
  end

  def create
    item = ListaEspera.new(lista_espera_params)
    if item.save
      AuditoriaService.log(request, 'LISTA_ESPERA_ADD', item, "Especialidade: #{item.especialidade}")
      render json: item, status: :created
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /lista_esperas/:id/sugerir_agenda
  def sugerir_agenda
    item = ListaEspera.find(params[:id])
    especialidades = extrair_especialidades(item.planned_specialties.presence || item.especialidade)
    frequencias = extrair_frequencias(item.planned_specialties.presence || item.especialidade)
    
    agendamentos_existentes = []
    if item.paciente_id.present?
      paciente = Paciente.find_by(id: item.paciente_id)
      agendamentos_existentes = paciente.agendamentos.includes(:profissional).to_a if paciente
    end
    
    sugestoes = buscar_sugestoes_consecutivos(especialidades, item.age, frequencias, agendamentos_existentes)

    render json: {
      item_espera: { id: item.id, nome: item.nome, age: item.age },
      especialidades: especialidades,
      sugestoes: sugestoes
    }
  end

  def update
    item = ListaEspera.find(params[:id])
    if item.update(lista_espera_params)
      render json: item
    else
      render json: { errors: item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    item = ListaEspera.find(params[:id])
    AuditoriaService.log(request, 'LISTA_ESPERA_DEL', item, "Remoção direta")
    item.destroy
    render json: { mensagem: "Removido da lista de espera com sucesso!" }
  end

  private

  def lista_espera_params
    params.require(:lista_espera).permit(:nome, :telefone, :especialidade, :observacao, :birth_date, :planned_specialties, :status, :paciente_id)
  end
end
