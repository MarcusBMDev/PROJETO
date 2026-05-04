class Api::TransferenciasController < ApplicationController
  before_action :validar_acesso_gestao!
  # GET /transferencias
  def index
    transferencias = Transferencia.includes(:paciente, :de_profissional, :para_profissional)
                                  .where(status: 'pendente')
                                  .order(created_at: :desc)
    
    render json: transferencias.as_json(
      include: {
        paciente: { only: [:id, :nome] },
        de_profissional: { only: [:id, :nome] },
        para_profissional: { only: [:id, :nome] }
      }
    )
  end

  # POST /transferencias
  def create
    t = Transferencia.new(transferencia_params)
    t.status = 'pendente'
    
    if t.save
      AuditoriaService.log(request, 'SOLICITAR_TRANSFERENCIA', t, "Tipo: #{t.tipo}, Paciente: #{t.paciente&.nome}")
      render json: { mensagem: "Solicitação de transferência enviada para análise da gestão." }, status: :created
    else
      render json: { errors: t.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /transferencias/:id/aprovar
  def aprovar
    t = Transferencia.find(params[:id])
    
    if t.status != 'pendente'
      return render json: { errors: ["Esta solicitação já foi processada."] }, status: :unprocessable_entity
    end

    begin
      Agendamento.transaction do
        case t.tipo
        when 'transferencia'
          processar_aprovacao_transferencia(t)
        when 'remocao'
          processar_aprovacao_remocao(t)
        when 'reducao'
          processar_aprovacao_reducao(t)
        end
        t.update!(status: 'aprovado')
      end

      # Notificação NeuroChat (para todos os tipos aplicáveis)
      notificar_gestao_aprovacao(t)

      # --- NOVA NOTIFICAÇÃO PARA GRUPOS OPERACIONAIS (6 e 7) ---
      begin
        setor = request.headers['X-User-Role'] || 'Gestão'
        case t.tipo
        when 'transferencia'
          NeurochatService.notificar_transferencia_paciente(t.paciente, t.de_profissional, t.para_profissional, t.motivo, setor, t.novo_dia_semana, t.novo_horario)
        when 'remocao', 'reducao'
          NeurochatService.notificar_remocao_paciente(t.paciente, t.motivo, setor)
        end
      rescue => e
        Rails.logger.error "Falha ao emitir notificação operacional: #{e.message}"
      end

      AuditoriaService.log(request, 'APROVAR_TRANSFERENCIA', t, "Tipo: #{t.tipo}, Executor: #{request.headers['X-User-Name']}")
      render json: { mensagem: "Solicitação aprovada e executada com sucesso!" }
    rescue => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end
  end

  # POST /transferencias/:id/rejeitar
  def rejeitar
    t = Transferencia.find(params[:id])
    if t.update(status: 'rejeitado')
      AuditoriaService.log(request, 'REJEITAR_TRANSFERENCIA', t, "Rejeitado por #{request.headers['X-User-Name']}")
      render json: { mensagem: "Solicitação rejeitada com sucesso." }
    else
      render json: { errors: ["Falha ao rejeitar solicitação."] }, status: :unprocessable_entity
    end
  end

  private

  def processar_aprovacao_transferencia(t)
    if t.agendamento_origem_id.present? && t.novo_horario.present? && t.novo_dia_semana.present?
      # Caso 1: Transferência para horário específico escolhido no modal
      ag = Agendamento.find(t.agendamento_origem_id)
      
      # Verifica conflitos (ignora se o pedido de transferência for marcado como encaixe)
      if !t.encaixe && Agendamento.exists?(profissional_id: t.para_profissional_id, dia_semana: t.novo_dia_semana, horario: t.novo_horario)
        raise "Horário #{t.novo_dia_semana} às #{t.novo_horario} já está ocupado no profissional de destino."
      end
      
      ag.update!(
        profissional_id: t.para_profissional_id,
        dia_semana: t.novo_dia_semana,
        horario: t.novo_horario,
        encaixe: t.encaixe,
        data_encaixe: t.encaixe ? Date.today : nil
      )
    else
      # Caso 2: Fallback para comportamento antigo (transfere todos os horários para EXATAMENTE os mesmos slots)
      agendamentos = Agendamento.where(profissional_id: t.de_profissional_id, paciente_id: t.paciente_id)
      raise "Nenhum agendamento encontrado para transferência." if agendamentos.empty?

      agendamentos.each do |ag|
        if Agendamento.exists?(profissional_id: t.para_profissional_id, dia_semana: ag.dia_semana, horario: ag.horario)
          raise "Horário #{ag.dia_semana} às #{ag.horario} ocupado no profissional de destino."
        end
        ag.update!(profissional_id: t.para_profissional_id)
      end
    end
  end

  def processar_aprovacao_remocao(t)
    ids = JSON.parse(t.agendamento_ids || "[]")
    agendamentos = Agendamento.includes(:profissional).where(id: ids)
    raise "Nenhum agendamento encontrado para remoção." if agendamentos.empty?

    setor = t.solicitante.presence || 'Gestão'

    # Captura os dados de cada agendamento ANTES de destruir e notifica o Grupo 14
    agendamentos.each do |ag|
      begin
        NeurochatService.notificar_retirada_paciente(
          t.paciente,
          ag.profissional,
          ag.dia_semana,
          ag.horario,
          t.motivo.presence || 'Remoção aprovada pela gestão',
          setor
        )
      rescue => e
        Rails.logger.error "Erro ao notificar retirada (agendamento #{ag.id}): #{e.message}"
      end
    end

    agendamentos.destroy_all
  end

  def processar_aprovacao_reducao(t)
    ids = JSON.parse(t.agendamento_ids || "[]")
    agendamentos = Agendamento.where(id: ids)
    raise "Nenhum agendamento encontrado para redução." if agendamentos.empty?
    
    # Quantidade de sessões removidas
    removidas = agendamentos.count
    agendamentos.destroy_all
    
    # Atualiza a frequência do paciente
    p = t.paciente
    nova_freq = [ (p.weekly_frequency || 1) - removidas, 1 ].max
    p.update!(weekly_frequency: nova_freq)
  end

  def notificar_gestao_aprovacao(t)
    # Atualmente a notificação é disparada para o grupo de gestão no NeuroChat
    begin
      paciente = t.paciente
      tipo_msg = case t.tipo
                when 'transferencia' then "Uma TRANSFERÊNCIA"
                when 'remocao'       then "Uma REMOÇÃO"
                when 'reducao'       then "Uma REDUÇÃO"
                end

      profissional_nome = t.para_profissional&.nome || t.de_profissional&.nome || "Equipe"
      # Log de auditoria ou integração futura
      Rails.logger.info "Aprovação: #{tipo_msg} de #{paciente.nome} (#{profissional_nome})"
    rescue StandardError => e
      Rails.logger.error "Erro na notificação: #{e.message}"
    end
  end

  def transferencia_params
    params.require(:transferencia).permit(
      :paciente_id, :de_profissional_id, :para_profissional_id, 
      :motivo, :tipo, :solicitante, :agendamento_ids,
      :agendamento_origem_id, :novo_dia_semana, :novo_horario, :encaixe
    )
  end
end