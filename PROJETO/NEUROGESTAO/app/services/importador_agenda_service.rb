require 'roo'

class ImportadorAgendaService
  DIAS_VALIDOS = ["SEGUNDA-FEIRA", "TERÇA-FEIRA", "QUARTA-FEIRA", "QUINTA-FEIRA", "SEXTA-FEIRA", "SÁBADO"]

  def initialize(caminho_arquivo)
    @xlsx = Roo::Excelx.new(caminho_arquivo)
  end

  def executar
    @xlsx.sheets.each do |nome_aba|
      begin
        puts "--> Analisando aba: #{nome_aba}"
        sheet = @xlsx.sheet(nome_aba)

        if nome_aba.upcase.include?("LISTA DE ESPERA")
          processar_lista_espera(sheet)
        elsif nome_aba.upcase == "ATS"
          processar_aba_ats(sheet)
        else
          processar_agenda_comum(nome_aba, sheet)
        end
      rescue => e
        puts "⚠️ Erro crítico na aba #{nome_aba}: #{e.message}"
      end
    end
    
    puts "--> Sincronizando dados adicionais (Terapia e Frequência)..."
    sincronizar_dados_adicionais_pacientes

    puts "✅ Fim da importação blindada!"
  end

  private

  # Verifica se o texto da observação restringe o atendimento a dias específicos
  def atende_no_dia?(dia_semana, obs_texto)
    return true if obs_texto.blank?
    
    texto = obs_texto.downcase
    dias_semana = ["segunda", "terça", "quarta", "quinta", "sexta", "sábado", "domingo"]
    
    # Se a observação não cita nenhum dia da semana, assume que atende todos (Seg a Sex na ATS)
    return true unless dias_semana.any? { |d| texto.include?(d) }

    # Se cita dias, verifica se o dia atual está no texto
    dia_busca = dia_semana.downcase.split('-').first # pega "segunda", "terça", etc
    texto.include?(dia_busca)
  end

  def processar_lista_espera(sheet)
    (5..sheet.last_row).each do |i|
      paciente_nome = sheet.cell(i, 2).to_s.strip
      next if paciente_nome.blank? || paciente_nome.upcase == "PACIENTE"
      next if paciente_nome.match?(/^\d{1,2}H/i) # Filtra sujeiras do Excel

      espec = sheet.cell(i, 1).to_s.strip
      especialidade_final = espec.presence || "Geral/Não Informada"

      espera = ListaEspera.find_or_initialize_by(nome: paciente_nome.upcase)

      if espera.new_record?
        espera.especialidade = especialidade_final
        espera.observacao = "Convênio: #{sheet.cell(i, 3)} | Turno: #{sheet.cell(i, 4)} | Pref: #{sheet.cell(i, 5)}"
        espera.telefone = sheet.cell(i, 6).to_s.strip
        espera.status = 'aguardando'
      else
        esps_atuais = espera.especialidade.to_s.split(',').map(&:strip)
        unless esps_atuais.include?(especialidade_final)
          esps_atuais << especialidade_final
          espera.especialidade = esps_atuais.join(', ')
        end
      end
      
      espera.save!
    end
  rescue => e
    puts "⚠️ Aviso na Lista de Espera: #{e.message}"
  end

  def processar_agenda_comum(nome_aba, sheet)
    # Detecção Inteligente de Formato (Normal vs Supervisão)
    header_row_idx = (1..5).find { |r| sheet.row(r).any? { |c| c.to_s.upcase.include?("PACIENTE") } }
    tem_coluna_profissional = false
    if header_row_idx
      tem_coluna_profissional = sheet.row(header_row_idx).any? { |c| c.to_s.upcase.include?("PROFISSIONAL") }
    end

    # Criamos o prof_fixo apenas se não for uma aba "combinada" e se realmente for necessário
    prof_fixo_nome = nome_aba.strip.upcase
    aba_combinada = prof_fixo_nome.include?("/") || (prof_fixo_nome.size > 15 && !prof_fixo_nome.include?(" "))

    dia_atual = nil
    horario_atual = nil

    (1..sheet.last_row).each do |i|
      col_a = sheet.cell(i, 1).to_s.strip.upcase
      
      if DIAS_VALIDOS.any? { |d| col_a.include?(d) }
        dia_atual = col_a.downcase
        horario_atual = nil
        next
      end

      # Identificação de Horário
      unless col_a.blank? || col_a.include?("HORÁRIO") || col_a.include?("PACIENTE") || col_a.include?("PROFISSIONAL")
        if col_a.match?(/\d/)
          h_parts = col_a.split('-').map do |p|
            p_limpo = p.strip.downcase.tr('h', ':').gsub(/[^\d:]/, '')
            next if p_limpo.blank?
            h, m = p_limpo.split(':')
            format("%02d:%02d", h.to_i, (m || 0).to_i)
          end.compact
          horario_atual = h_parts.join(" - ")
        else
          horario_atual = col_a.strip
        end
      end

      paciente_nome = sheet.cell(i, 2).to_s.strip
      next if paciente_nome.blank? || paciente_nome.split.size < 2
      next if ["LIVRE", "---", "ALMOÇO", "RESERVADO", "PACIENTE"].include?(paciente_nome.upcase)
      next if paciente_nome.match?(/^\d{1,2}H/i)

      next if dia_atual.nil? || horario_atual.nil?

      profs_finais = []
      convenio_nome = ""

      obs_textos = []
      if tem_coluna_profissional
        # Formato Supervisão: Col 2=Paciente, Col 3=Profissional, Col 4=Convênio
        prof_col_raw = sheet.cell(i, 3).to_s.strip
        prof_nomes = limpar_e_dividir_profissionais(prof_col_raw)
        
        if prof_nomes.empty? || ["PROFISSIONAL", "PACIENTE", "CONVENIO"].include?(prof_nomes.first.upcase)
          if aba_combinada
            # Se a aba é combinada e não tem profissional, pula a linha para não criar sujeiras/dummy professionals
            next
          else
            profs_finais = [Profissional.find_or_create_by!(nome: prof_fixo_nome) { |p| p.especialidade = "Não Informada" }]
          end
        else
          profs_finais = prof_nomes.map { |n| Profissional.find_or_create_by!(nome: n.upcase) { |p| p.especialidade = "Não Informada" } }
        end
        convenio_nome = sheet.cell(i, 4).to_s.strip

        (5..10).each do |col|
          val = sheet.cell(i, col).to_s.strip
          obs_textos << val if val.present? && val.upcase != "OBSERVAÇÕES" && val.upcase != "OBSERVAÇÃO"
        end
      else
        # Formato Normal: Col 2=Paciente, Col 3=Convênio
        profs_finais = [Profissional.find_or_create_by!(nome: prof_fixo_nome) { |p| p.especialidade = "Não Informada" }]
        convenio_nome = sheet.cell(i, 3).to_s.strip

        (4..10).each do |col|
          val = sheet.cell(i, col).to_s.strip
          obs_textos << val if val.present? && val.upcase != "OBSERVAÇÕES" && val.upcase != "OBSERVAÇÃO"
        end
      end

      obs_final = obs_textos.join(" | ")

      # Detecta terapia em grupo pela coluna de observações
      is_grupo = obs_textos.any? { |t| t.upcase.include?("TERAPIA EM GRUPO") }

      profs_finais.each do |prof|
        if is_grupo && horario_atual.to_s.include?('-')
          # Terapia em grupo com range: expande para cada slot de 40 min dentro do range
          expandir_range_para_slots(horario_atual).each do |slot_hora|
            salvar_agendamento(paciente_nome, prof, convenio_nome, dia_atual, slot_hora, obs_final, true)
          end
        else
          salvar_agendamento(paciente_nome, prof, convenio_nome, dia_atual, horario_atual, obs_final, is_grupo)
        end
      end
    end
  end

  def processar_aba_ats(sheet)
    header_row_idx = (1..5).find { |r| sheet.row(r).any? { |c| c.to_s.upcase.include?("PACIENTE") } }
    start_row = header_row_idx ? header_row_idx + 1 : 3

    # Identifica os blocos baseados na reinicialização da coluna SALA (coluna 4)
    blocos = []
    (start_row..sheet.last_row).each do |i|
      sala_val = sheet.cell(i, 4).to_s.strip
      # Se a sala for 1 ou 1.0, inicia um novo bloco
      if sala_val == "1" || sala_val == "1.0"
        blocos << { start_row: i }
      end
    end

    # Define o fim de cada bloco (até o início do próximo ou fim da planilha)
    blocos.each_with_index do |bloco, index|
      proximo_bloco = blocos[index + 1]
      bloco[:end_row] = proximo_bloco ? proximo_bloco[:start_row] - 1 : sheet.last_row
    end

    # Processa cada bloco identificado
    blocos.each do |bloco|
      # Encontra o horário definido para este bloco (procurando em qualquer linha do intervalo)
      horario_raw = nil
      (bloco[:start_row]..bloco[:end_row]).each do |i|
        val = sheet.cell(i, 1).to_s.strip
        if val.present? && val.match?(/\d/)
          horario_raw = val
          break
        end
      end
      
      next if horario_raw.nil?

      # Prepara os horários (ex: "8H - 9H20" vira ["08:00", "08:40"])
      horarios_para_salvar = []
      h_parts = horario_raw.split('-').map do |p|
        p_limpo = p.strip.downcase.tr('h', ':').gsub(/[^\d:]/, '')
        next if p_limpo.blank?
        h, m = p_limpo.split(':')
        format("%02d:%02d", h.to_i, (m || 0).to_i)
      end.compact
      
      if h_parts.any?
        hora_inicial = Time.parse(h_parts.first)
        horarios_para_salvar << hora_inicial.strftime("%H:%M")
        horarios_para_salvar << (hora_inicial + 40 * 60).strftime("%H:%M")
      else
        horarios_para_salvar << horario_raw
      end

      # Processa cada linha individual dentro do bloco
      (bloco[:start_row]..bloco[:end_row]).each do |i|
        paciente_nome  = sheet.cell(i, 2).to_s.strip
        convenio_nome  = sheet.cell(i, 3).to_s.strip
        at_col_raw     = sheet.cell(i, 5).to_s.strip
        supervisao_raw = sheet.cell(i, 6).to_s.strip
        obs_ats_raw    = sheet.cell(i, 7).to_s.strip

        # Pula linhas sem paciente ou com placeholders
        next if paciente_nome.blank? || paciente_nome.match?(/^\d{1,2}H/i) || ["LIVRE", "---", "ALMOÇO", "RESERVADO"].include?(paciente_nome.upcase)

        # --- AT: Segunda a Sexta (com filtro de dias se especificado na OBS) ---
        unless at_col_raw.blank?
          at_nomes = limpar_e_dividir_profissionais(at_col_raw)
          at_nomes.each do |nome_at|
            prof = Profissional.find_or_create_by!(nome: nome_at.upcase) { |p| p.especialidade = "ATENDENTE TERAPEUTICO" }
            
            dias_padrao = ["SEGUNDA-FEIRA", "TERÇA-FEIRA", "QUARTA-FEIRA", "QUINTA-FEIRA", "SEXTA-FEIRA"]
            dias_padrao.each do |dia_extenso|
              if atende_no_dia?(dia_extenso, obs_ats_raw)
                dia = dia_extenso.downcase
                horarios_para_salvar.each do |hora_bloco|
                  # Mantemos a observação como nil na ATS conforme pedido,
                  # usando-a apenas para o controle interno de dias.
                  salvar_agendamento(paciente_nome, prof, convenio_nome, dia, hora_bloco, nil)
                end
              end
            end
          end
        end

        # --- Supervisão ---
        unless supervisao_raw.blank?
          parsear_e_salvar_supervisao(paciente_nome, convenio_nome, supervisao_raw)
        end
      end
    end
  end

  def limpar_e_dividir_profissionais(texto)
    return [] if texto.blank?
    texto.split(%r{/|,|;| e |&|\+}).map(&:strip).reject { |n| n.blank? || n.size < 2 }
  end



  # Parseia a coluna de Supervisão (col F) e salva o agendamento.
  # Formato esperado: "NOME_PROF - DIA HORARIO" ex: "MONICA - SEG 8H40"
  # Suporta múltiplas entradas separadas por nova linha ou ponto-e-vírgula.
  def parsear_e_salvar_supervisao(paciente_nome, convenio_nome, texto)
    entradas = texto.split(/\n|;/).map(&:strip).reject(&:blank?)
    entradas.each do |entrada|
      # Captura: NOME - DIA HORARIO (com variações de espaço e separador)
      match = entrada.match(/^(.+?)\s*[-–]\s*(seg|ter|qua|qui|sex|s[aá]b)\w*\s+(\d{1,2}[Hh]\d{0,2})/i)
      next unless match

      prof_nome  = match[1].strip.upcase
      dia_abrev  = match[2].strip.downcase[0..2]
      hora_texto = match[3].strip

      dia  = mapear_dia_abrev(dia_abrev)
      hora = normalizar_hora_supervisao(hora_texto)
      next if dia.nil? || hora.nil?

      prof = Profissional.find_or_create_by!(nome: prof_nome) { |p| p.especialidade = "Não Informada" }
      salvar_agendamento(paciente_nome, prof, convenio_nome, dia, hora)
      puts "   ✅ Supervisão: #{paciente_nome.upcase} → #{prof_nome} | #{dia} às #{hora}"
    end
  rescue => e
    puts "⚠️ Erro ao parsear supervisão '#{texto}': #{e.message}"
  end

  def mapear_dia_abrev(abrev)
    {
      "seg" => "segunda-feira",
      "ter" => "terça-feira",
      "qua" => "quarta-feira",
      "qui" => "quinta-feira",
      "sex" => "sexta-feira",
      "sab" => "sábado",
      "sáb" => "sábado"
    }[abrev.to_s.downcase.strip]
  end

  def normalizar_hora_supervisao(hora_texto)
    limpa = hora_texto.downcase.tr('h', ':').gsub(/[^\d:]/, '')
    partes = limpa.split(':')
    h = partes[0].to_i
    m = (partes[1] || "0").to_i
    format("%02d:%02d", h, m)
  rescue
    nil
  end

  def sincronizar_dados_adicionais_pacientes
    Paciente.find_each do |paciente|
      frequencia = paciente.agendamentos.count
      esps = paciente.agendamentos.joins(:profissional).pluck('profissionais.especialidade').uniq.reject(&:blank?)
      esps = ["Não Informada"] if esps.empty?
      paciente.update(weekly_frequency: frequencia, planned_specialties: esps.join(", "))
    end
  end

  def salvar_agendamento(p_nome, prof, c_nome, dia, hora, observacao = nil, terapia_grupo = false)
    c_limpo = c_nome.blank? ? "PARTICULAR" : c_nome.strip.upcase
    convenio_da_planilha = Convenio.find_or_create_by!(nome: c_limpo)
    p_limpo = p_nome.gsub(/\s*-\s*ABA\s*$/i, '').strip.upcase
    paciente = Paciente.find_or_initialize_by(nome: p_limpo)

    # Lógica de Validação Cruzada de Convênios
    if c_limpo == "PARTICULAR"
      if paciente.convenio_id.present?
        convenio_paciente = Convenio.find_by(id: paciente.convenio_id)
        if convenio_paciente && convenio_paciente.nome.to_s.strip.upcase != "PARTICULAR"
          # Usa o convênio real cadastrado no perfil do paciente para este agendamento
          convenio = convenio_paciente
        else
          convenio = convenio_da_planilha
        end
      else
        convenio = convenio_da_planilha
      end
    else
      # Planilha traz convênio real
      convenio = convenio_da_planilha
      # Se paciente for novo ou não tiver convênio real cadastrado, atualiza no cadastro do paciente
      if paciente.new_record? || paciente.convenio_id.nil?
        paciente.convenio_id = convenio.id
      else
        convenio_paciente = Convenio.find_by(id: paciente.convenio_id)
        if convenio_paciente.nil? || convenio_paciente.nome.to_s.strip.upcase == "PARTICULAR"
          paciente.convenio_id = convenio.id
        end
      end
    end

    if paciente.new_record? || paciente.changed?
      paciente.save!
    end

    begin
      agendamento = Agendamento.find_or_initialize_by(
        profissional: prof,
        paciente: paciente,
        convenio: convenio,
        dia_semana: dia.to_s.strip.downcase,
        horario: hora.to_s.strip,
      )
      
      # Limpa observação se estiver em branco, caso contrário salva o valor da planilha
      agendamento.observacoes = observacao.presence

      # Marca como terapia em grupo quando detectado na observação
      agendamento.terapia_grupo = true if terapia_grupo
      
      agendamento.save!
      puts "   👥 Terapia em Grupo: #{p_nome} → #{prof.nome} | #{dia} às #{hora}" if terapia_grupo
    rescue ActiveRecord::RecordInvalid => e
      puts "⚠️  Aviso: Conflito ou erro ao agendar #{p_nome} com #{prof.nome} às #{hora}. Possível dupla ocorrência. (#{e.message})"
    end
  end

  # Bloqueia SEGUNDA-FEIRA 10:40 e 11:20 para TODOS os profissionais
  def bloquear_producao_segunda
    horarios_producao = ["10:40", "11:20"]
    Profissional.find_each do |prof|
      begin
        horarios_producao.each do |hora|
          next if Agendamento.exists?(profissional: prof, dia_semana: "segunda-feira", horario: hora)
          Agendamento.create(
            profissional: prof,
            dia_semana: "segunda-feira",
            horario: hora,
            status: "bloqueado",
            motivo_bloqueio: "HORÁRIO DE PRODUÇÃO",
            bloqueado_por: "SISTEMA"
          )
        end
      rescue => e
        puts "   ⚠️ Erro ao bloquear produção para #{prof.nome}: #{e.message}"
      end
    end
  end

  # Bloqueia todos os horários vagos de cada profissional como HORÁRIO DE PRODUÇÃO
  def bloquear_horarios_vagos
    slots_padrao = ["08:00", "08:40", "09:20", "10:00", "10:40", "11:20", "14:00", "14:40", "15:20", "16:00", "16:40", "17:20"]
    dias = ["segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira"]

    Profissional.find_each do |prof|
      begin
        # Carrega agendamentos uma vez por profissional para performance
        ags = prof.agendamentos.pluck(:dia_semana, :horario)
        count = 0

        dias.each do |dia|
          slots_padrao.each do |hora|
            slot_min = hora_para_minutos(hora)
            
            ja_ocupado = ags.any? do |ag_dia, ag_hora|
              next false unless ag_dia.to_s.strip.downcase == dia
              
              if ag_hora.to_s.include?('-')
                inicio, fim = ag_hora.split('-').map { |h| hora_para_minutos(h.strip) }
                slot_min >= inicio && slot_min < (fim + 5)
              else
                hora_para_minutos(ag_hora.to_s.strip) == slot_min
              end
            end

            next if ja_ocupado

            Agendamento.create(
              profissional: prof,
              dia_semana: dia,
              horario: hora,
              status: "bloqueado",
              motivo_bloqueio: "HORÁRIO DE PRODUÇÃO",
              bloqueado_por: "SISTEMA"
            )
            count += 1
          end
        end
        puts "   🔒 #{prof.nome}: #{count} horários vagos bloqueados." if count > 0
      rescue => e
        puts "   ⚠️ Erro ao bloquear horários vagos para #{prof.nome}: #{e.message}"
      end
    end
  end

  def hora_para_minutos(str)
    limpa = str.to_s.downcase.tr('h', ':').gsub(/[^\d:]/, '')
    partes = limpa.split(':')
    partes[0].to_i * 60 + (partes[1] || "0").to_i
  end

  # Expande um range de horário (ex: "16:40 - 17:20") em slots individuais
  def expandir_range_para_slots(range_str)
    partes = range_str.split('-').map(&:strip)
    return [range_str] if partes.size < 2

    inicio_min = hora_para_minutos(partes[0])
    fim_min = hora_para_minutos(partes[1])

    slots = []
    slot_padrao = 40 
    atual = inicio_min
    
    # Para terapia em grupo, garantimos que o horário final também receba um agendamento
    # se ele bater com o início de um slot (ex: 17:20)
    while atual <= fim_min
      h = (atual / 60).to_i
      m = atual % 60
      slots << format("%02d:%02d", h, m)
      atual += slot_padrao
    end

    slots.uniq
  end
end