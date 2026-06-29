class AgendamentosController < ApplicationController
  # GET /agendamentos
  def index
    agendamentos = Agendamento.includes(:profissional, :paciente, :convenio).all
    render json: agendamentos.as_json(
      except: [:created_at, :updated_at],
      include: {
        profissional: { only: [:id, :nome, :especialidade] },
        paciente: { only: [:id, :nome] },
        convenio: { only: [:id, :nome] }
      }
    )
  end

  # GET /agendamentos/vagas?especialidade=ABA
  def vagas
    especialidade = params[:especialidade]
    
    # 1. Definimos a "Grade Vazia" (Slots de 40 min)
    # Segunda: acaba às 10h (3 slots) + tarde normal (6 slots)
    slots_seg = ["08:00", "08:40", "09:20", "14:00", "14:40", "15:20", "16:00", "16:40", "17:20"]
    # Terça a Sexta: manhã (6 slots) + tarde (6 slots)
    slots_pad = ["08:00", "08:40", "09:20", "10:00", "10:40", "11:20", "14:00", "14:40", "15:20", "16:00", "16:40", "17:20"]

    profissionais = Profissional.where(especialidade: especialidade)
    
    resultado = profissionais.map do |prof|
      # Pegamos o que já está ocupado no banco
      ocupados = prof.agendamentos.pluck(:horario, :dia_semana)

      # Filtramos o que sobrou (Vagas Reais)
      vagas_livres = {
        "SEGUNDA-FEIRA" => slots_seg - ocupados.select { |o| o[1] == "SEGUNDA-FEIRA" }.map(&:first),
        "TERÇA-FEIRA"   => slots_pad - ocupados.select { |o| o[1] == "TERÇA-FEIRA" }.map(&:first),
        "QUARTA-FEIRA"  => slots_pad - ocupados.select { |o| o[1] == "QUARTA-FEIRA" }.map(&:first),
        "QUINTA-FEIRA"  => slots_pad - ocupados.select { |o| o[1] == "QUINTA-FEIRA" }.map(&:first),
        "SEXTA-FEIRA"   => slots_pad - ocupados.select { |o| o[1] == "SEXTA-FEIRA" }.map(&:first)
      }

      { profissional: prof.nome, especialidade: prof.especialidade, horarios_disponiveis: vagas_livres }
    end

    render json: resultado
  end

  # POST /agendamentos
  def create
    agendamento = Agendamento.new(agendamento_params)
    if agendamento.save
      render json: agendamento, status: :created
    else
      render json: { errors: agendamento.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /agendamentos/:id
  def update
    agendamento = Agendamento.find(params[:id])
    if agendamento.update(agendamento_params)
      render json: agendamento
    else
      render json: { errors: agendamento.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /agendamentos/:id
  def destroy
    agendamento = Agendamento.find(params[:id])
    agendamento.destroy
    render json: { mensagem: "Agendamento removido com sucesso!" }
  end

  # POST /agendamentos/transferir
  def transferir
    de_prof_id = params[:de_profissional_id]
    para_prof_id = params[:para_profissional_id]

    # Move todos os pacientes de um para o outro em uma única transação
    Agendamento.where(profissional_id: de_prof_id).update_all(profissional_id: para_prof_id)

    render json: { mensagem: "Transferência concluída com sucesso!" }
  end

  def por_profissional
    agendamentos = Agendamento.where(profissional_id: params[:id]).includes(:paciente, :convenio)
    render json: agendamentos.as_json(include: { paciente: { only: [:id, :nome] }, convenio: { only: [:id, :nome] } })
  end

  private

  def agendamento_params
    params.require(:agendamento).permit(:profissional_id, :paciente_id, :convenio_id, :dia_semana, :horario, :observacoes, :cor)
  end
end