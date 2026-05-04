require 'roo'

class ImportadorAgendaService
  DIAS_VALIDOS = ["SEGUNDA-FEIRA", "TERÇA-FEIRA", "QUARTA-FEIRA", "QUINTA-FEIRA", "SEXTA-FEIRA", "SÁBADO"]

  def initialize(caminho_arquivo)
    @xlsx = Roo::Excelx.new(caminho_arquivo)
  end

  def executar
    @xlsx.sheets.each do |nome_aba|
      puts "--> Analisando aba: #{nome_aba}"
      sheet = @xlsx.sheet(nome_aba)

      if nome_aba.upcase.include?("LISTA DE ESPERA")
        processar_lista_espera(sheet)
      elsif nome_aba.upcase == "ATS"
        processar_aba_ats(sheet)
      else
        processar_agenda_comum(nome_aba, sheet)
      end
    end
    
    puts "--> Sincronizando dados adicionais (Terapia e Frequência)..."
    sincronizar_dados_adicionais_pacientes
    
    puts "✅ Fim da importação blindada!"
  end

  private

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
    header_row_idx = (1..5).find { |r| sheet.row(r).any? { |c| c.to_s.upcase.include?("PROFISSIONAL") } }
    tem_coluna_profissional = !header_row_idx.nil?

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

      if tem_coluna_profissional
        # Formato Supervisão: Col 2=Paciente, Col 3=Profissional, Col 4=Convênio
        prof_col_raw = sheet.cell(i, 3).to_s.strip
        prof_nomes = limpar_e_dividir_profissionais(prof_col_raw)
        
        if prof_nomes.empty? || ["PROFISSIONAL", "PACIENTE", "CONVENIO"].include?(prof_nomes.first.upcase)
          # Se a aba é combinada, não usamos o nome dela como profissional! Usamos um placeholder.
          fallback_nome = aba_combinada ? "COORDENAÇÃO/SUPERVISÃO" : prof_fixo_nome
          profs_finais = [Profissional.find_or_create_by!(nome: fallback_nome) { |p| p.especialidade = "Não Informada" }]
        else
          profs_finais = prof_nomes.map { |n| Profissional.find_or_create_by!(nome: n.upcase) { |p| p.especialidade = "Não Informada" } }
        end
        convenio_nome = sheet.cell(i, 4).to_s.strip
      else
        # Formato Normal: Col 2=Paciente, Col 3=Convênio
        profs_finais = [Profissional.find_or_create_by!(nome: prof_fixo_nome) { |p| p.especialidade = "Não Informada" }]
        convenio_nome = sheet.cell(i, 3).to_s.strip
      end

      profs_finais.each do |prof|
        salvar_agendamento(paciente_nome, prof, convenio_nome, dia_atual, horario_atual)
      end
    end
  end

  def processar_aba_ats(sheet)
    horarios_memoria = []

    (4..sheet.last_row).each do |i|
      horario_raw = sheet.cell(i, 1).to_s.strip
      horarios_para_salvar = []
      
      if horario_raw.blank?
        horarios_para_salvar = horarios_memoria
      elsif horario_raw.match?(/\d/)
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
      else
        parte = horario_raw.split('-').first
        horarios_para_salvar << (parte ? parte.strip : "")
      end

      horarios_memoria = horarios_para_salvar unless horarios_para_salvar.empty?

      paciente_nome  = sheet.cell(i, 2).to_s.strip
      at_col_raw     = sheet.cell(i, 5).to_s.strip
      supervisao_raw = sheet.cell(i, 6).to_s.strip

      # Pula linha se não houver paciente nem nenhum profissional a processar
      next if paciente_nome.blank? || (at_col_raw.blank? && supervisao_raw.blank?)
      next if paciente_nome.match?(/^\d{1,2}H/i)

      convenio_nome = sheet.cell(i, 3).to_s.strip
      obs_texto     = sheet.cell(i, 7).to_s

      # --- AT: 2 sessões seguidas de 40min, Seg-Sex (ou dias da OBS) ---
      unless at_col_raw.blank?
        at_nomes = limpar_e_dividir_profissionais(at_col_raw)
        at_nomes.each do |nome_at|
          prof = Profissional.find_or_create_by!(nome: nome_at.upcase) { |p| p.especialidade = "AT" }
          
          DIAS_VALIDOS.each do |dia_extenso|
            dia = dia_extenso.downcase
            if atende_no_dia?(nome_at, obs_texto, dia_extenso)
              horarios_para_salvar.each do |hora_bloco|
                salvar_agendamento(paciente_nome, prof, convenio_nome, dia, hora_bloco)
              end
            end
          end
        end
      end

      # --- Supervisão: 1 sessão de 40min no dia e hora especificados (col F) ---
      unless supervisao_raw.blank?
        parsear_e_salvar_supervisao(paciente_nome, convenio_nome, supervisao_raw)
      end
    end
  end

  def limpar_e_dividir_profissionais(texto)
    return [] if texto.blank?
    texto.split(%r{/|,|;| e |&|\+}).map(&:strip).reject { |n| n.blank? || n.size < 2 }
  end

  def atende_no_dia?(nome_prof, obs_texto, dia_extenso)
    obs_limpa = obs_texto.to_s.downcase.strip
    return true if obs_limpa.empty?

    # Se a OBS não mencionar nenhum dia da semana, ignoramos o conteúdo
    # (ex: "Se não tiver outra opção de AT" não deve filtrar dias)
    dias_keywords = ["seg", "ter", "qua", "qui", "sex", "sab", "sáb"]
    return true unless dias_keywords.any? { |d| obs_limpa.include?(d) }
    
    # Lowercase para garantir match correto
    dia_curto = dia_extenso[0..2].downcase
    
    if obs_limpa.include?("-") || obs_limpa.include?(":") || obs_limpa.include?("/")
      blocos = obs_limpa.split(%r{/|;})
      bloco_deste_prof = blocos.find { |b| b.include?(nome_prof.downcase) }
      
      if bloco_deste_prof
        tem_qualquer_dia = DIAS_VALIDOS.any? { |d| bloco_deste_prof.include?(d[0..2].downcase) } || bloco_deste_prof.include?("seg a qui")
        return true unless tem_qualquer_dia

        return checking_day_in_text(bloco_deste_prof, dia_curto)
      else
        outros_nomes = obs_limpa.scan(/[a-záéíóúàãõ]{4,}/).any? { |n| n != nome_prof.downcase && DIAS_VALIDOS.none?{ |d| d.downcase.include?(n) } }
        return !outros_nomes
      end
    end

    checking_day_in_text(obs_limpa, dia_curto)
  end

  def checking_day_in_text(texto, dia_curto)
    if texto.include?("seg a qui")
      return ["seg", "ter", "qua", "qui"].include?(dia_curto)
    elsif texto.include?("seg a sex")
      return ["seg", "ter", "qua", "qui", "sex"].include?(dia_curto)
    end
    if dia_curto == "ter"
      return texto.include?("ter")
    end
    texto.include?(dia_curto)
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

  def salvar_agendamento(p_nome, prof, c_nome, dia, hora)
    c_limpo = c_nome.blank? ? "PARTICULAR" : c_nome.strip.upcase
    convenio = Convenio.find_or_create_by!(nome: c_limpo)
    p_limpo = p_nome.gsub(/\s*-\s*ABA\s*$/i, '').strip.upcase
    paciente = Paciente.find_or_initialize_by(nome: p_limpo)
    if paciente.new_record? || paciente.convenio_id.nil?
      paciente.convenio_id = convenio.id
      paciente.save!
    end

    begin
      Agendamento.find_or_create_by!(
        profissional: prof,
        paciente: paciente,
        convenio: convenio,
        dia_semana: dia.to_s.strip.downcase,
        horario: hora.to_s.strip,
      )
    rescue ActiveRecord::RecordInvalid => e
      puts "⚠️  Aviso: Conflito ou erro ao agendar #{p_nome} com #{prof.nome} às #{hora}. Possível dupla ocorrência. (#{e.message})"
    end
  end
end