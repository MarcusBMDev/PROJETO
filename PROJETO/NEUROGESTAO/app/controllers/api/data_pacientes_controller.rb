class Api::DataPacientesController < ActionController::API
 # Responde ao GET /api/data_pacientes.json
  def index
    begin
      page = (params[:page] || 1).to_i
      per_page = (params[:per_page] || 100).to_i
      offset = (page - 1) * per_page

      pacientes_query = Paciente.ativos.order(:nome).includes(:convenio, agendamentos: :profissional)

      if params[:busca].present?
        termo = "%#{params[:busca]}%"
        # Case insensitive regex / ilike query depending on DB. ILIKE is postgres, but let's use standard LIKE if sqlite:
        # Assuming postgres based on "ILIKE" usage typically in Heroku/Rails 7 apps
        # But wait, checking if it works, otherwise standard LIKE or ActiveRecord's .where("nome ILIKE ?") works.
        # Actually ILIKE is safer for Postgres. But we will use lower() to be safe on all relations
        pacientes_query = pacientes_query.where("LOWER(nome) LIKE ?", termo.downcase)
      end

      if params[:profissional_id].present?
        # Filter patients by specific professional without eagerly loading issues via JOIN duplication
        paciente_ids = Agendamento.where(profissional_id: params[:profissional_id]).select(:paciente_id)
        pacientes_query = pacientes_query.where(id: paciente_ids)
      end

      total_registros = pacientes_query.count
      pacientes = pacientes_query.offset(offset).limit(per_page)
      
      json_data = pacientes.map { |p|
        begin
          p.as_json(
            only: [:id, :nome, :age, :birth_date, :convenio_id, :weekly_frequency, :status, :planned_specialties]
          ).merge({
            convenio: p.convenio ? { id: p.convenio.id, nome: p.convenio.nome } : nil,
            agendamentos: p.agendamentos.map { |a| 
              { 
                id: a.id,
                dia_semana: a.dia_semana, 
                horario: a.horario, 
                profissional: a.profissional&.nome,
                profissional_id: a.profissional_id
              } 
            }
          })
        rescue
          { id: p.id, nome: p.nome, erro: "Erro nos dados" }
        end
      }
      
      total_paginas = (total_registros.to_f / per_page).ceil
      total_paginas = 1 if total_paginas < 1

      render json: {
        pacientes: json_data,
        total: total_registros,
        pagina_atual: page,
        total_paginas: total_paginas
      }
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /api/data_pacientes
  def create
    nome_trimmed = paciente_params[:nome].to_s.strip
    # Busca paciente pelo nome (case-insensitive) incluindo os deletados
    paciente_existente = Paciente.unscoped.find_by("LOWER(nome) = ?", nome_trimmed.downcase)

    if paciente_existente
      if paciente_existente.deleted_at.present?
        # Smart Re-activation: Reativa o paciente e atualiza os dados
        paciente_existente.reativar
        AuditoriaService.log(request, 'REATIVAR', paciente_existente, "Paciente reativado via formulário de criação")
      end
      # Upsert: Atualiza os dados do paciente existente e segue para processar salvamento
      paciente_existente.assign_attributes(paciente_params)
      processar_salvamento(paciente_existente)
    else
      paciente = Paciente.new(paciente_params)
      processar_salvamento(paciente)
    end
  end

  # PATCH/PUT /api/data_pacientes/:id
  def update
    paciente = Paciente.find(params[:id])
    paciente.assign_attributes(paciente_params)
    processar_salvamento(paciente)
  end

  # DELETE /api/data_pacientes/:id
  def destroy
    paciente = Paciente.find(params[:id])
    motivo = params[:motivo] || "Motivo não informado"
    setor = request.headers['X-User-Role'] || 'Desconhecido'
    NeurochatService.notificar_remocao_paciente(paciente, motivo, setor)
    Agendamento.where(paciente_id: paciente.id).destroy_all
    if paciente.soft_delete
      AuditoriaService.log(request, 'EXCLUIR', paciente, "Motivo: #{motivo}")
      render json: { message: 'Paciente removido com sucesso' }
    else
      render json: { error: 'Não foi possível excluir o paciente.' }, status: :unprocessable_entity
    end
  end

  # PATCH /api/data_pacientes/:id/reativar
  def reativar
    paciente = Paciente.inativos.find(params[:id])
    if paciente.reativar
      AuditoriaService.log(request, 'REATIVAR', paciente, "Ação manual de reativação")
      render json: { success: true, message: "Paciente reativado", paciente: paciente }
    else
      render json: { success: false, errors: ['Não foi possível reativar o paciente.'] }, status: :unprocessable_entity
    end
  end

  private

  def processar_salvamento(paciente)
    adicionar_a_espera = params[:adicionar_a_espera].to_s == "true"
    especialidade_espera = params[:especialidade_espera] || paciente.planned_specialties

    if paciente.save
      acao_audit = params[:action] == 'create' ? 'CRIAR' : 'EDITAR'
      AuditoriaService.log(request, acao_audit, paciente, "Dados: #{paciente_params.to_h}")
      
      status_res = { success: true, paciente: paciente }
      
      if adicionar_a_espera
        especialidades_array = []
        begin
          especialidades_array = JSON.parse(paciente.planned_specialties || "[]")
        rescue
          especialidades_array = (paciente.planned_specialties || "").split(",")
        end

        espera = ListaEspera.find_or_initialize_by(paciente_id: paciente.id)
        espera.assign_attributes(
          nome: paciente.nome,
          birth_date: paciente.birth_date,
          age: paciente.age,
          especialidade: especialidade_espera.presence || especialidades_array.first || 'Geral',
          planned_specialties: paciente.planned_specialties,
          status: 'aguardando'
        )
        espera.save
        AuditoriaService.log(request, 'LISTA_ESPERA_ADD', paciente, "Adicionado via cadastro de paciente")
        status_res[:lista_espera_id] = espera.id
        status_res[:sugerir_agendamento] = true
      end

      if params[:action] == 'create'
        setor = request.headers['X-User-Role'] || 'Recepção'
        NeurochatService.notificar_novo_paciente(paciente, setor)
      end

      render json: status_res, status: (params[:action] == 'create' ? :created : :ok)
    else
      render json: { success: false, errors: paciente.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def paciente_params
    params.require(:paciente).permit(:nome, :age, :birth_date, :convenio_id, :weekly_frequency, :planned_specialties, :status)
  end
end
