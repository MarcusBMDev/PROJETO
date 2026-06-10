require 'roo'
require 'set'

class ImportadorAgendaService
  DIAS_VALIDOS = ["SEGUNDA-FEIRA", "TERÇA-FEIRA", "QUARTA-FEIRA", "QUINTA-FEIRA", "SEXTA-FEIRA", "SÁBADO"]

  def initialize(caminho_arquivo)
    @xlsx = Roo::Excelx.new(caminho_arquivo)
    @slots_presentes = Hash.new { |h, k| h[k] = Set.new }
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

    puts "--> Bloqueando horários de produção nas segundas-feiras (10:40 e 11:20)..."
    bloquear_producao_segunda

    puts "--> Bloqueando horários não preenchidos (exclusivos para produção)..."
    bloquear_horarios_vagos

    puts "✅ Fim da importação blindada!"
  end

  private

  # Verifica se o texto da observação restringe o atendimento a dias específicos para determinado AT
  def at_atende_no_dia?(nome_at, dia_semana, obs_texto)
    return true if obs_texto.blank?

    texto_completo = obs_texto.downcase.strip
    nome_at_down = nome_at.to_s.downcase.strip

    # 1. Se a observação contém referências a múltiplos profissionais com regras separadas,
    # tenta isolar a parte que se refere a este profissional.
    texto_analise = texto_completo
    if texto_completo.include?("/") || texto_completo.include?(";") || texto_completo.include?("|")
      segmentos = texto_completo.split(%r{/|;|\|}).map(&:strip)
      # Procura um segmento que mencione o nome do AT
      segmento_prof = segmentos.find { |seg| seg.include?(nome_at_down) }
      texto_analise = segmento_prof if segmento_prof
    end

    # Se o texto de análise não menciona nenhum dia da semana (ou abreviação), assume que atende todos os dias.
    dias_palavras = ["seg", "ter", "qua", "qui", "sex", "sáb", "sab", "dom"]
    return true unless dias_palavras.any? { |d| texto_analise.include?(d) }

    # 2. Identifica quais dias da semana estão ativados no texto_analise.
    dia_alvo = dia_semana.downcase.strip
    dias_ativados = expandir_dias_do_texto(texto_analise)
    
    dias_ativados.include?(dia_alvo)
  end

  def expandir_dias_do_texto(texto)
    mapa_dias = {
      "segunda-feira" => "segunda-feira",
      "segunda" => "segunda-feira",
      "seg" => "segunda-feira",
      "terça-feira" => "terça-feira",
      "terça" => "terça-feira",
      "terca" => "terça-feira",
      "ter" => "terça-feira",
      "quarta-feira" => "quarta-feira",
      "quarta" => "quarta-feira",
      "quar" => "quarta-feira",
      "qua" => "quarta-feira",
      "quinta-feira" => "quinta-feira",
      "quinta" => "quinta-feira",
      "quin" => "quinta-feira",
      "qui" => "quinta-feira",
      "sexta-feira" => "sexta-feira",
      "sexta" => "sexta-feira",
      "sex" => "sexta-feira",
      "sábado" => "sábado",
      "sabado" => "sábado",
      "sab" => "sábado"
    }

    ordem_dias = ["segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira", "sábado"]

    dias_encontrados = []
    texto_limpo = texto.downcase.strip

    # Normaliza plurais de dias de semana para o singular
    texto_limpo = texto_limpo.gsub(/\bsegundas([-\s]+feiras)?\b/, 'segunda')
    texto_limpo = texto_limpo.gsub(/\bterças([-\s]+feiras)?\b/, 'terça')
    texto_limpo = texto_limpo.gsub(/\btercas([-\s]+feiras)?\b/, 'terca')
    texto_limpo = texto_limpo.gsub(/\bquartas([-\s]+feiras)?\b/, 'quarta')
    texto_limpo = texto_limpo.gsub(/\bquintas([-\s]+feiras)?\b/, 'quinta')
    texto_limpo = texto_limpo.gsub(/\bsextas([-\s]+feiras)?\b/, 'sexta')
    texto_limpo = texto_limpo.gsub(/\bsábados\b/, 'sábado')
    texto_limpo = texto_limpo.gsub(/\bsabados\b/, 'sabado')

    # 1. Encontra ranges do tipo "dia1 a dia2" (ex: "seg a quin")
    regex_range = /\b(segunda-feira|segunda|seg|terça-feira|terça|terca|ter|quarta-feira|quarta|quar|qua|quinta-feira|quinta|quin|qui|sexta-feira|sexta|sex|sábado|sabado|sab)\b\s+(?:a|até|ate)\s+\b(segunda-feira|segunda|seg|terça-feira|terça|terca|ter|quarta-feira|quarta|quar|qua|quinta-feira|quinta|quin|qui|sexta-feira|sexta|sex|sábado|sabado|sab)\b/

    while match = texto_limpo.match(regex_range)
      d1_raw, d2_raw = match[1], match[2]
      d1 = mapa_dias[d1_raw]
      d2 = mapa_dias[d2_raw]
      
      if d1 && d2
        idx1 = ordem_dias.index(d1)
        idx2 = ordem_dias.index(d2)
        if idx1 && idx2 && idx1 <= idx2
          dias_encontrados.concat(ordem_dias[idx1..idx2])
        end
      end
      texto_limpo = texto_limpo.sub(match[0], '')
    end

    # 2. Busca termos individuais restantes
    mapa_dias.keys.sort_by { |k| -k.length }.each do |abrev|
      dia_completo = mapa_dias[abrev]
      if texto_limpo.match?(/\b#{Regexp.escape(abrev)}\b/)
        dias_encontrados << dia_completo
        texto_limpo = texto_limpo.gsub(/\b#{Regexp.escape(abrev)}\b/, '')
      end
    end

    dias_encontrados.uniq
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
    
    if header_row_idx.nil?
      col_horario = 1
      col_paciente = 2
      col_convenio = 3
      col_obs = 4
      col_profissional = 0
      tem_coluna_profissional = false
    else
      header_row = sheet.row(header_row_idx).map { |c| c.to_s.strip.upcase }
      col_horario = (header_row.index { |c| c.include?("HORÁRIO") || c.include?("HORARIO") } || 0) + 1
      col_profissional_idx = header_row.index { |c| c.include?("PROFISSIONAL") }
      col_profissional = col_profissional_idx ? col_profissional_idx + 1 : 0
      tem_coluna_profissional = col_profissional > 0
      col_paciente = (header_row.index { |c| c.include?("PACIENTE") } || 1) + 1
      col_convenio = (header_row.index { |c| c.include?("CONVÊNIO") || c.include?("CONVENIO") } || 2) + 1
      col_obs = (header_row.index { |c| c.include?("OBSERVAÇ") || c.include?("OBSERVAC") } || 3) + 1
    end

    # Criamos o prof_fixo apenas se não for uma aba "combinada" e se realmente for necessário
    prof_fixo_nome = nome_aba.strip.upcase
    aba_combinada = prof_fixo_nome.include?("/") || (prof_fixo_nome.size > 15 && !prof_fixo_nome.include?(" "))

    dia_atual = nil
    horario_atual = nil
    horario_anterior = nil
    periodo_bloqueado = nil

    # Primeiro scan: identifica todos os horários que possuem algum paciente agendado neste dia
    slots_com_paciente = Set.new
    scan_dia = nil
    scan_hora = nil
    start_row = header_row_idx ? header_row_idx + 1 : 1

    (start_row..sheet.last_row).each do |i|
      col_a = sheet.cell(i, col_horario).to_s.strip.upcase
      if DIAS_VALIDOS.any? { |d| col_a.include?(d) }
        scan_dia = col_a.downcase
        scan_hora = nil
        next
      end

      unless col_a.blank? || col_a.include?("HORÁRIO") || col_a.include?("PACIENTE") || col_a.include?("PROFISSIONAL")
        if col_a.match?(/\d/)
          h_parts = col_a.split('-').map do |p|
            p_limpo = p.strip.downcase.tr('h', ':').gsub(/[^\d:]/, '')
            next if p_limpo.blank?
            h, m = p_limpo.split(':')
            format("%02d:%02d", h.to_i, (m || 0).to_i)
          end.compact
          scan_hora = h_parts.join(" - ")
        else
          scan_hora = col_a.strip
        end
      end

      next if scan_dia.nil? || scan_hora.nil?

      pac_nome = sheet.cell(i, col_paciente).to_s.strip
      if pac_nome.present? && pac_nome.split.size >= 2 && !["LIVRE", "---", "ALMOÇO", "RESERVADO", "PACIENTE", "PERÍODO FECHADO", "PERIODO FECHADO", "FECHADO"].include?(pac_nome.upcase)
        slots_com_paciente.add([scan_dia, scan_hora])
      end
    end

    (start_row..sheet.last_row).each do |i|
      col_a = sheet.cell(i, col_horario).to_s.strip.upcase
      
      if DIAS_VALIDOS.any? { |d| col_a.include?(d) }
        dia_atual = col_a.downcase
        horario_atual = nil
        horario_anterior = nil
        periodo_bloqueado = nil
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

      next if dia_atual.nil? || horario_atual.nil?

      # Se mudamos do período da manhã para a tarde, limpamos o bloco
      if horario_atual && horario_anterior
        if !tarde?(horario_anterior) && tarde?(horario_atual)
          periodo_bloqueado = nil
        end
      end
      horario_anterior = horario_atual

      paciente_nome = sheet.cell(i, col_paciente).to_s.strip

      # Pegamos apenas a coluna de observação específica para não puxar a legenda lateral
      obs_val = sheet.cell(i, col_obs).to_s.strip
      obs_final = nil
      if obs_val.present? && !["OBSERVAÇÕES", "OBSERVAÇÃO", "HORÁRIO RESERVADO", "PACIENTE COM PLANO SUSPENSO", "PARTICULAR", "TAG", "FECHADO"].include?(obs_val.upcase)
        obs_final = obs_val
      end

      # --- LÓGICA DE DETECÇÃO DE BLOQUEIO/FECHAMENTO ---
      is_bloqueio = false
      motivo_bloqueio = nil

      # Reset do periodo_bloqueado se houver paciente real
      if paciente_nome.present? && paciente_nome.split.size >= 2 && !["LIVRE", "---", "ALMOÇO", "RESERVADO", "PACIENTE", "PERÍODO FECHADO", "PERIODO FECHADO", "FECHADO"].include?(paciente_nome.upcase)
        periodo_bloqueado = nil
      end

      # 1. Verifica se alguma célula das colunas da tabela indica fechamento (evita ler a legenda fora da tabela)
      cols_verificar = [col_paciente, col_obs]
      cols_verificar << col_profissional if tem_coluna_profissional
      valores_linha = cols_verificar.map { |col| sheet.cell(i, col).to_s.strip }
      termos_bloqueio = ["PERÍODO FECHADO", "PERIODO FECHADO", "FECHADO", "HORÁRIO RESERVADO", "HORARIO RESERVADO", "RESERVADO"]
      celula_bloqueio = valores_linha.find do |val|
        val_up = val.upcase
        termos_bloqueio.any? { |term| val_up == term || val_up.include?(term) } || val_up.start_with?("BLOCK")
      end

      if celula_bloqueio
        is_bloqueio = true
        motivo_bloqueio = obs_final.present? ? "#{celula_bloqueio} - #{obs_final}" : celula_bloqueio
        periodo_bloqueado = motivo_bloqueio
      # 2. Caso de reposição sem paciente mas com observação
      elsif paciente_nome.blank? && obs_final.present?
        is_bloqueio = true
        motivo_bloqueio = obs_final
        periodo_bloqueado = motivo_bloqueio
      # 3. Propagação do bloco ativo em células vazias
      elsif paciente_nome.blank? && obs_final.blank? && periodo_bloqueado.present?
        # Apenas propaga se este horário não possuir pacientes reais agendados
        if slots_com_paciente.include?([dia_atual, horario_atual])
          periodo_bloqueado = nil
        else
          is_bloqueio = true
          motivo_bloqueio = periodo_bloqueado
        end
      end

      # --- DETERMINAÇÃO DOS PROFISSIONAIS ---
      profs_finais = []
      
      if tem_coluna_profissional
        prof_col_raw = sheet.cell(i, col_profissional).to_s.strip
        prof_nomes = limpar_e_dividir_profissionais(prof_col_raw)
        
        if prof_nomes.empty? || ["PROFISSIONAL", "PACIENTE", "CONVENIO"].include?(prof_nomes.first.upcase)
          if aba_combinada
            # Para aba combinada, se o profissional for em branco (ou for uma tag de bloqueio),
            # mas for um bloqueio de sala, nós bloqueamos para todos os profissionais da aba!
            if is_bloqueio
              profs_finais = obter_profissionais_da_aba(nome_aba)
            else
              next
            end
          else
            profs_finais = [Profissional.find_or_create_by!(nome: prof_fixo_nome) { |p| p.especialidade = "Não Informada" }]
          end
        else
          profs_finais = prof_nomes.map { |n| Profissional.find_or_create_by!(nome: n.upcase) { |p| p.especialidade = "Não Informada" } }
        end
      else
        profs_finais = obter_profissionais_da_aba(nome_aba)
      end

      # Registra a presença de horário na planilha para cada profissional da linha
      profs_finais.each do |prof|
        if horario_atual.include?('-')
          expandir_range_para_slots(horario_atual).each do |slot_hora|
            @slots_presentes[prof.nome.upcase].add([dia_atual, slot_hora])
          end
        else
          @slots_presentes[prof.nome.upcase].add([dia_atual, horario_atual])
        end
      end

      # --- APLICAÇÃO DOS DADOS ---
      if is_bloqueio
        profs_finais.each do |prof|
          salvar_bloqueio(prof, dia_atual, horario_atual, motivo_bloqueio)
        end
      else
        # Processamento normal do paciente
        next if paciente_nome.blank? || paciente_nome.split.size < 2
        next if ["LIVRE", "---", "ALMOÇO", "RESERVADO", "PACIENTE"].include?(paciente_nome.upcase)
        next if paciente_nome.match?(/^\d{1,2}H/i)

        convenio_nome = sheet.cell(i, col_convenio).to_s.strip
        is_grupo = obs_final.to_s.upcase.include?("TERAPIA EM GRUPO")

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
  end

  def processar_aba_ats(sheet)
    header_row_idx = (1..5).find { |r| sheet.row(r).any? { |c| c.to_s.upcase.include?("PACIENTE") } }
    start_row = header_row_idx ? header_row_idx + 1 : 3

    # Identifica as seções não vazias da planilha
    sections = []
    in_section = false
    current_section = nil

    (start_row..sheet.last_row).each do |i|
      empty = (1..7).all? { |c| sheet.cell(i, c).to_s.strip.blank? }
      if !empty
        if !in_section
          current_section = { start_row: i }
          sections << current_section
          in_section = true
        end
        current_section[:end_row] = i
      else
        in_section = false
      end
    end

    # Identifica os blocos dinamicamente baseando-se nas tags de horário na coluna 1
    blocos = []
    sections.each do |section|
      time_rows = []
      (section[:start_row]..section[:end_row]).each do |i|
        val = sheet.cell(i, 1).to_s.strip
        if val.present? && val.match?(/\d/)
          time_rows << { row: i, time: val }
        end
      end

      next if time_rows.empty?

      splits = []
      if time_rows.first[:row] > section[:start_row]
        splits << { start_row: section[:start_row], time: time_rows.first[:time] }
      end

      time_rows.each do |tr|
        splits << { start_row: tr[:row], time: tr[:time] }
      end

      splits.each_with_index do |split, idx|
        next_split = splits[idx + 1]
        split[:end_row] = next_split ? next_split[:start_row] - 1 : section[:end_row]
        blocos << split
      end
    end

    # Processa cada bloco identificado
    blocos.each do |bloco|
      horario_raw = bloco[:time]
      next if horario_raw.nil?

      # Prepara o horário formatado (ex: "8H - 9H20" vira "08:00 - 09:20")
      h_parts = horario_raw.split('-').map do |p|
        p_limpo = p.strip.downcase.tr('h', ':').gsub(/[^\d:]/, '')
        next if p_limpo.blank?
        h, m = p_limpo.split(':')
        format("%02d:%02d", h.to_i, (m || 0).to_i)
      end.compact
      
      horario_final = h_parts.size >= 2 ? h_parts.join(" - ") : horario_raw

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
              if at_atende_no_dia?(nome_at, dia_extenso, obs_ats_raw)
                dia = dia_extenso.downcase
                # Salva o agendamento diretamente com a string do intervalo formatado
                salvar_agendamento(paciente_nome, prof, convenio_nome, dia, horario_final, nil)
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
    texto.split(%r{/|,|;| e |&|\+}).map(&:strip).reject do |n|
      n.blank? || n.size < 2 || 
      ["PROFISSIONAL", "PACIENTE", "CONVENIO", "FECHADO", "BLOCK"].any? { |term| n.upcase.include?(term) }
    end
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

  def tarde?(horario_str)
    return false if horario_str.blank?
    hora = horario_str.split(':').first.to_i
    hora >= 12
  end

  def obter_profissionais_da_aba(nome_aba)
    # Se for a aba MÔNICALAURANATÁLIA, retorna os três profissionais
    if nome_aba.upcase.include?("MÔNICALAURANATÁLIA") || nome_aba.upcase.include?("MONICALAURANATALIA")
      ["MÔNICA", "LAURA", "NATÁLIA"].map { |n| Profissional.find_or_create_by!(nome: n) { |p| p.especialidade = "Não Informada" } }
    else
      [Profissional.find_or_create_by!(nome: nome_aba.strip.upcase) { |p| p.especialidade = "Não Informada" }]
    end
  end

  def salvar_bloqueio(prof, dia, hora, motivo)
    begin
      agendamento = Agendamento.find_or_initialize_by(
        profissional: prof,
        dia_semana: dia.to_s.strip.downcase,
        horario: hora.to_s.strip
      )
      
      agendamento.assign_attributes(
        paciente: nil,
        convenio: nil,
        observacoes: nil,
        status: "bloqueado",
        motivo_bloqueio: motivo.to_s.strip,
        bloqueado_por: "SISTEMA"
      )
      
      agendamento.save!
      puts "   🔒 Bloqueio: #{prof.nome} | #{dia} às #{hora} | Motivo: #{motivo}"
    rescue => e
      puts "⚠️  Aviso: Erro ao salvar bloqueio para #{prof.nome} às #{hora}. (#{e.message})"
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

  # Bloqueia todos os horários vagos de cada profissional como HORÁRIOS FECHADOS EXCLUSIVOS PARA PRODUÇÃO (exceto ATs)
  def bloquear_horarios_vagos
    slots_padrao = ["08:00", "08:40", "09:20", "10:00", "10:40", "11:20", "14:00", "14:40", "15:20", "16:00", "16:40", "17:20"]
    dias = ["segunda-feira", "terça-feira", "quarta-feira", "quinta-feira", "sexta-feira"]

    Profissional.where.not(especialidade: "ATENDENTE TERAPEUTICO").find_each do |prof|
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

            # Só bloqueia se o horário NÃO estava presente na planilha para este profissional (ou seja, é um horário indisponível/não trabalhado)
            next if @slots_presentes[prof.nome.upcase]&.include?([dia, hora])

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