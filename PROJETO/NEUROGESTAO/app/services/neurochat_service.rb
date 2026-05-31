# app/services/neurochat_service.rb
class NeurochatService
  GROUP_ID           = 7 # Geral (conforme antigo)
  RECEPTION_GROUP_ID = 6
  SCHEDULING_GROUP_ID = 7
  RETIRADAS_GROUP_ID  = 14 # Grupo de Retiradas
  TRANSFERENCIAS_GROUP_ID = 17 # Grupo de Trocas/Transferências
  AGENDAMENTO_USER_ID = 112  # Conta compartilhada "AGENDAMENTO" no NeuroChat
  SYSTEM_USER_ID = 112

  # ── Pacientes ──────────────────────────────────────────────────────────

  def self.notificar_novo_paciente(paciente, setor, user_id = nil)
    convenio_nome = paciente.convenio&.nome || 'Sem convênio'
    mensagem = "🆕 **NOVO PACIENTE CADASTRADO**\n" \
               "Nome: **#{paciente.nome}**\n" \
               "Convênio: **#{convenio_nome}**\n" \
               "Ação realizada por: **#{setor}**"
    enviar_para_grupos_operacionais(mensagem, user_id)
  end

  def self.notificar_remocao_paciente(paciente, motivo, setor, user_id = nil)
    profissionais = paciente.agendamentos.map { |a| a.profissional.nome }.uniq.join(', ')
    mensagem = "⚠️ **PACIENTE REMOVIDO**\n" \
               "O paciente **#{paciente.nome}**, que realizava terapias com: **#{profissionais.presence || 'Nenhum'}**,\n" \
               "foi removido da lista de agendamentos.\n" \
               "**Motivo:** #{motivo}\n" \
               "**Ação realizada por:** **#{setor}**"
    enviar_mensagem_grupo(mensagem, RETIRADAS_GROUP_ID, user_id)
    enviar_para_grupos_operacionais(mensagem, user_id)
  end

  # Notifica o Grupo 14 (Retiradas) com todos os detalhes da remoção
  def self.notificar_retirada_paciente(paciente, profissional, dia_semana, horario, motivo, setor, user_id = nil, operador_nome = nil)
    prof_nome = profissional&.nome || 'Não identificado'
    operador_str = operador_nome.present? ? "#{clean_str(operador_nome)} (#{clean_str(setor)})" : clean_str(setor)
    mensagem = "🔴 **PACIENTE RETIRADO DA GRADE**\n" \
               "👤 Paciente: **#{clean_str(paciente.nome)}**\n" \
               "👨‍⚕️ Profissional: **#{clean_str(prof_nome)}**\n" \
               "📅 Horário removido: **#{clean_str(dia_semana)} às #{clean_str(horario)}**\n" \
               "📝 Motivo: #{clean_str(motivo)}\n" \
               "🏢 Confirmado por: **#{operador_str}**"
    enviar_mensagem_grupo(mensagem, RETIRADAS_GROUP_ID)
    enviar_para_grupos_operacionais(mensagem)
  rescue => e
    Rails.logger.error "Erro ao notificar retirada no Grupo 14: #{e.message}"
  end

  # Notifica o Grupo 14 (Retiradas) com os detalhes da REDUÇÃO de grade
  def self.notificar_reducao_grade(paciente, agendamentos, motivo, setor, operador_nome = nil)
    operador_str = operador_nome.present? ? "#{clean_str(operador_nome)} (#{clean_str(setor)})" : clean_str(setor)
    
    horarios_str = agendamentos.map do |ag|
      especialidade_str = ag.profissional&.especialidade.present? ? " (#{ag.profissional.especialidade})" : ""
      "- **#{clean_str(ag.dia_semana)} às #{clean_str(ag.horario)}** - Prof: #{clean_str(ag.profissional&.nome || 'Não identificado')}#{especialidade_str}"
    end.join("\n")

    mensagem = "📉 **SOLICITAÇÃO DE REDUÇÃO DE GRADE**\n" \
               "👤 Paciente: **#{clean_str(paciente.nome)}**\n\n" \
               "📋 **Horários Removidos:**\n" \
               "#{horarios_str}\n\n" \
               "📝 Justificativa/Observação: **#{clean_str(motivo)}**\n" \
               "🏢 Confirmado por: **#{operador_str}**"
               
    enviar_mensagem_grupo(mensagem, RETIRADAS_GROUP_ID)
    enviar_para_grupos_operacionais(mensagem)
  rescue => e
    Rails.logger.error "Erro ao notificar redução no Grupo 14: #{e.message}"
  end

  # Notifica o Grupo 14 (Retiradas) com os detalhes da REMOÇÃO de grade (Alta / Finalização)
  def self.notificar_remocao_grade(paciente, agendamentos, motivo, setor, operador_nome = nil)
    operador_str = operador_nome.present? ? "#{clean_str(operador_nome)} (#{clean_str(setor)})" : clean_str(setor)
    
    horarios_str = agendamentos.map do |ag|
      especialidade_str = ag.profissional&.especialidade.present? ? " (#{ag.profissional.especialidade})" : ""
      "- **#{clean_str(ag.dia_semana)} às #{clean_str(ag.horario)}** - Prof: #{clean_str(ag.profissional&.nome || 'Não identificado')}#{especialidade_str}"
    end.join("\n")

    mensagem = "❌ **SOLICITAÇÃO DE REMOÇÃO DE GRADE (ALTA/FINALIZAÇÃO)**\n" \
               "👤 Paciente: **#{clean_str(paciente.nome)}**\n\n" \
               "📋 **Horários Removidos:**\n" \
               "#{horarios_str}\n\n" \
               "📝 Justificativa/Observação: **#{clean_str(motivo)}**\n" \
               "🏢 Confirmado por: **#{operador_str}**"
               
    enviar_mensagem_grupo(mensagem, RETIRADAS_GROUP_ID)
    enviar_para_grupos_operacionais(mensagem)
  rescue => e
    Rails.logger.error "Erro ao notificar remoção no Grupo 14: #{e.message}"
  end

  def self.notificar_transferencia_paciente(paciente, de_profissional, para_profissional, motivo, setor, dia = nil, hora = nil, user_id = nil)
    novo_horario_str = dia && hora ? "\n📅 **Novo Horário:** **#{dia} às #{hora}**" : ""
    
    # Mensagem customizada para troca de horário (mesmo profissional)
    if de_profissional.id == para_profissional.id
      mensagem = "🕒 **HORÁRIO ALTERADO**\n" \
                 "👤 O paciente **#{paciente.nome}** teve seu horário alterado.\n" \
                 "👨‍⚕️ **Profissional:** **#{de_profissional.nome}**#{novo_horario_str}\n" \
                 "📝 **Motivo:** #{motivo}\n" \
                 "🛠️ **Ação realizada por:** **#{setor}**"
    else
      mensagem = "🔄 **PACIENTE TRANSFERIDO**\n" \
                 "👤 O paciente **#{paciente.nome}** foi transferido.\n" \
                 "👨‍⚕️ **De:** **#{de_profissional.nome}**\n" \
                 "👨‍⚕️ **Para:** **#{para_profissional.nome}**#{novo_horario_str}\n" \
                 "📝 **Motivo:** #{motivo}\n" \
                 "🛠️ **Ação realizada por:** **#{setor}**"
    end

    # Envia para o grupo de transferências (17) E para os grupos operacionais padrão (6 e 7)
    enviar_mensagem_grupo(mensagem, TRANSFERENCIAS_GROUP_ID, user_id)
    enviar_para_grupos_operacionais(mensagem, user_id)
  end

  def self.notificar_alteracao_agendamento(paciente, prof_antigo, prof_novo, dia_antigo, hora_antiga, dia_novo, hora_novo, setor, user_id = nil)
    mensagem = "🔄 **AGENDAMENTO ALTERADO**\n" \
               "👤 Paciente: **#{paciente.nome}**\n"
               
    if prof_antigo.id != prof_novo.id
      mensagem += "👨‍⚕️ Profissional: de **#{prof_antigo.nome}** para **#{prof_novo.nome}**\n"
    else
      mensagem += "👨‍⚕️ Profissional: **#{prof_novo.nome}**\n"
    end
    
    if dia_antigo != dia_novo || hora_antiga != hora_novo
      mensagem += "📅 Horário: de **#{dia_antigo} às #{hora_antiga}** para **#{dia_novo} às #{hora_novo}**\n"
    end
    
    mensagem += "🛠️ Ação realizada por: **#{setor}**"
    
    enviar_mensagem_grupo(mensagem, TRANSFERENCIAS_GROUP_ID, user_id)
  end

  def self.notificar_encaixe(agendamento, setor, user_id = nil)
    mensagem = "⚡ **NOVO ENCAIXE REALIZADO**\n" \
               "👤 Paciente: **#{agendamento.paciente&.nome}**\n" \
               "📅 Horário: #{agendamento.dia_semana} às #{agendamento.horario}\n" \
               "👨‍⚕️ Profissional: #{agendamento.profissional.nome}\n" \
               "🛠️ Realizado pela: #{setor}"
    enviar_para_grupos_operacionais(mensagem, user_id)
  end

  def self.notificar_aprovacao_agendamento(agendamento, setor)
    mensagem = "✅ **AGENDAMENTO CONFIRMADO**\n" \
               "O agendamento de **#{agendamento.paciente&.nome}** foi aprovado.\n" \
               "📅 Horário: #{agendamento.dia_semana} às #{agendamento.horario}\n" \
               "👨‍⚕️ Profissional: #{agendamento.profissional.nome}\n" \
               "🛠️ Ação por: #{setor}"
    enviar_para_grupos_operacionais(mensagem)
  end

  # ── Profissionais ──────────────────────────────────────────────────────

  def self.notificar_inativacao_profissional(profissional, setor)
    pacientes_ativos = profissional.agendamentos
                                   .includes(:paciente)
                                   .map { |a| a.paciente.nome }
                                   .uniq.join(', ')
    mensagem = "🚫 **PROFISSIONAL INATIVADO**\n" \
               "O profissional **#{profissional.nome}** (**#{profissional.especialidade}**) foi inativado.\n" \
               "Pacientes vinculados: **#{pacientes_ativos.presence || 'Nenhum'}**\n" \
               "**Ação realizada por:** **#{setor}**"
    enviar_para_grupos_operacionais(mensagem)
  end

  def self.notificar_curriculo_profissional(profissional, link_curriculo, setor)
    mensagem = "📄 **MINI CURRÍCULO COMPARTILHADO**\n" \
               "Profissional: **#{profissional.nome}**\n" \
               "Especialidade: #{profissional.especialidade}\n" \
               "🔗 [Clique aqui para visualizar](#{link_curriculo})\n" \
               "**Compartilhado por:** #{setor}"
    enviar_mensagem_grupo(mensagem)
  end

  def self.notificar_agendamento_espera(paciente, agendamento, setor)
    convenio_nome = paciente.convenio&.nome || 'Particular/Direto'
    mensagem = "📢 **Novo Agendamento (via Espera)**\n" \
               "👤 Paciente: **#{paciente.nome}**\n" \
               "🩺 Área: **#{agendamento.profissional.especialidade}**\n" \
               "📅 Horário: **#{agendamento.dia_semana}** às **#{agendamento.horario}**\n" \
               "👩‍⚕️ Profissional: **#{agendamento.profissional.nome}**\n" \
               "💳 Convênio: **#{convenio_nome}**\n" \
               "🛠️ Painel: **#{setor}**"
    enviar_para_grupos_operacionais(mensagem)
  end

  # Notifica que há um agendamento PENDENTE aguardando aprovação
  def self.notificar_aguardando_aprovacao(agendamento, setor)
    paciente_nome = clean_str(agendamento.paciente&.nome || "Novo Paciente (Espera)")
    dia    = clean_str(agendamento.dia_semana)
    hora   = clean_str(agendamento.horario)
    prof   = clean_str(agendamento.profissional.nome)
    
    texto = "🕒 **AGENDAMENTO AGUARDANDO APROVAÇÃO**\n" \
            "👤 Paciente: **#{paciente_nome}**\n" \
            "📅 Horário Reservado: **#{dia} às #{hora}**\n" \
            "👨‍⚕️ Profissional: **#{prof}**\n" \
            "🛠️ Solicitado por: **#{setor}**\n" \
            "🔔 *Este horário está bloqueado na grade e aguarda confirmação da gestão.*"
    
    enviar_para_grupos_operacionais(texto)
  end

  # ── Privado ────────────────────────────────────────────────────────────
  
  private

  def self.enviar_para_grupos_operacionais(texto, user_id = nil)
    # Envia para Recepção (6) e Agendamento (7)
    enviar_mensagem_grupo(texto, RECEPTION_GROUP_ID, user_id)
    enviar_mensagem_grupo(texto, SCHEDULING_GROUP_ID, user_id)
  end

  def self.enviar_mensagem_grupo(texto, grupo_id = GROUP_ID, _user_id = nil)
    sender_id = AGENDAMENTO_USER_ID
    sql = "INSERT INTO messages (user_id, text, target_id, target_type, is_read, msg_type, timestamp) " \
          "VALUES (?, ?, ?, 'group', 0, 'text', ?)"

    # Força o Rails a usar a role de escrita especificamente para o banco do NeuroChat
    NeurochatRecord.connected_to(role: :writing) do
      conn = NeurochatRecord.connection
      # Garante modo escrita na sessão do MySQL (redundância de segurança)
      conn.execute("SET SESSION TRANSACTION READ WRITE") rescue nil
      
      sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql, sender_id, texto, grupo_id, Time.current])
      conn.execute(sanitized_sql)
    end
  rescue => e
    Rails.logger.error "Erro ao enviar notificação para o NeuroChat: #{e.message}"
  end

  def self.enviar_mensagem_privada(target_id, texto)
    sql = "INSERT INTO messages (user_id, target_id, target_type, text, msg_type, timestamp, is_read, is_pinned, is_edited, is_deleted) " \
          "VALUES (?, ?, 'private', ?, 'text', ?, 0, 0, 0, 0)"

    NeurochatRecord.connected_to(role: :writing) do
      conn = NeurochatRecord.connection
      conn.execute("SET SESSION TRANSACTION READ WRITE") rescue nil
      
      sanitized_sql = ActiveRecord::Base.send(:sanitize_sql_array, [sql, SYSTEM_USER_ID, target_id, texto, Time.current])
      conn.execute(sanitized_sql)
      
      # Retorna o ID do último insert para o webhook
      conn.select_value("SELECT LAST_INSERT_ID()")
    end
  rescue => e
    Rails.logger.error "Erro ao enviar mensagem privada para o NeuroChat: #{e.message}"
    nil
  end

  def self.fogo_e_esquece_webhook(message_id)
    return unless message_id
    
    require 'net/http'
    require 'uri'
    require 'json'
    
    uri = URI.parse("http://localhost:3000/api/integrate/notify")
    
    Thread.new do
      begin
        http = Net::HTTP.new(uri.host, uri.port)
        http.open_timeout = 2
        http.read_timeout = 2
        request = Net::HTTP::Post.new(uri.request_uri, {'Content-Type': 'application/json'})
        request.body = { messageId: message_id }.to_json
        http.request(request)
      rescue StandardError => e
        Rails.logger.error "[NeuroChat Webhook Error]: #{e.message}"
      end
    end
  end

  def self.clean_str(str)
    return "" if str.nil?
    str.to_s.force_encoding('UTF-8').encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
end
