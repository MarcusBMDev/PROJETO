module SugestaoAgendamento
  extend ActiveSupport::Concern

  # Retorna a lista bruta de profissionais e suas vagas por especialidade
  def extrair_vagas_brutas(especialidades, age)
    return {} if especialidades.blank?
    todos_slots_por_dia = ClinicSlots::ALL
    vagas_por_esp = {}

    especialidades.each do |esp|
      esp_normalizada = esp.to_s.strip.upcase
      profissionais = Profissional.ativos.where("especialidade LIKE ?", "%#{esp_normalizada}%").to_a
      profissionais.select! { |p| p.especialidade.to_s.split(',').map { |e| e.strip.upcase }.include?(esp_normalizada) }

      if esp_normalizada.present? && profissionais.empty?
        profissionais = Profissional.ativos.where("UPPER(especialidade) LIKE ?", "%#{esp_normalizada}%").to_a
      end

      if age.present? && age > 0
        profissionais.select! { |p| (p.min_age.nil? || p.min_age <= age) && (p.max_age.nil? || p.max_age >= age) }
      end

      vagas_por_esp[esp] = profissionais.map do |prof|
        ocupados = prof.agendamentos.where(status: ['confirmado', 'pendente', 'bloqueado']).pluck(:horario, :dia_semana)
        
        horarios = todos_slots_por_dia.each_with_object({}) do |(dia_config, slots), memo|
          ocupados_do_dia = ocupados.select { |h, d| d.to_s.upcase.split('-').first == dia_config.to_s.upcase.split('-').first }
          memo[dia_config] = slots.reject do |slot_hora|
            slot_m = horario_para_minutos(slot_hora)
            ocupados_do_dia.any? do |ocup_hora, _d|
              if ocup_hora.include?('-')
                start_h, end_h = ocup_hora.split('-')
                slot_m >= horario_para_minutos(start_h) && slot_m < horario_para_minutos(end_h)
              else
                slot_m == horario_para_minutos(ocup_hora)
              end
            end
          end
        end
        { id: prof.id, nome: prof.nome, especialidade: esp, horarios: horarios }
      end
    end
    vagas_por_esp
  end

  def buscar_sugestoes_consecutivos(especialidades, age, frequencias = {}, agendamentos_existentes = [])
    return [] if especialidades.blank?

    todos_slots_por_dia = ClinicSlots::ALL

    # 1. Mapeia profissionais já vinculados a especialidades para este paciente
    # Se ele já faz Fono com o Prof A, novas sessões de Fono devem ser com o Prof A.
    prof_por_esp_existente = {}
    agendamentos_existentes.each do |ag|
      next unless ag.profissional
      ag.profissional.especialidade.to_s.upcase.split(',').map(&:strip).each do |esp_prof|
        if especialidades.include?(esp_prof)
          prof_por_esp_existente[esp_prof] = ag.profissional_id
        end
      end
    end

    vagas_por_especialidade = {}
    especialidades.each do |esp|
      # Busca profissionais ATIVOS que possuam a especialidade de forma robusta
      esp_normalizada = esp.to_s.strip.upcase
      profissionais = Profissional.ativos.where("especialidade LIKE ?", "%#{esp_normalizada}%").to_a
      profissionais.select! do |p| 
        p.especialidade.to_s.split(',').map { |e| e.strip.upcase }.include?(esp_normalizada)
      end

      # Se nenhum profissional foi encontrado com o filtro exato, tenta com LIKE puro (fallback)
      if esp_normalizada.present? && profissionais.empty?
        profissionais = Profissional.ativos.where("UPPER(especialidade) LIKE ?", "%#{esp_normalizada}%").to_a
      end

      # Filtro de idade: Só aplica se o paciente tiver uma idade definida e maior que zero
      # Isso evita que pacientes com idade "vazia" (que pode vir como 0) sejam filtrados injustamente.
      if age.present? && age > 0
        profissionais.select! { |p| (p.min_age.nil? || p.min_age <= age) && (p.max_age.nil? || p.max_age >= age) }
      end

      # Mapeamento de vínculo mantido para lógica de priorização futura (não bloqueia mais)
      tem_vinculo = prof_por_esp_existente[esp.upcase]

      vagas_por_especialidade[esp] = profissionais.map do |prof|
        # Flag para priorizar profissionais que o paciente já frequenta
        vinculo_ativo = (tem_vinculo == prof.id)
        # Consideramos agendamentos confirmados, pendentes E bloqueados como "ocupados"
        ocupados = prof.agendamentos.where(status: ['confirmado', 'pendente', 'bloqueado']).pluck(:horario, :dia_semana)
        
        horarios = todos_slots_por_dia.each_with_object({}) do |(dia_config, slots), memo|
          # Filtra ocupados que batem com o dia, ignorando case e hífens extras (ex: SEGUNDA vs SEGUNDA-FEIRA)
          ocupados_do_dia = ocupados.select do |h, d| 
            d.to_s.upcase.split('-').first == dia_config.to_s.upcase.split('-').first
          end

          # Em vez de subtração de strings, verificamos cada slot se ele está "coberto" por algum agendamento
          memo[dia_config] = slots.reject do |slot_hora|
            slot_m = horario_para_minutos(slot_hora)
            
            ocupados_do_dia.any? do |ocup_hora, _d|
              if ocup_hora.include?('-')
                start_h, end_h = ocup_hora.split('-')
                slot_m >= horario_para_minutos(start_h) && slot_m < horario_para_minutos(end_h)
              else
                slot_m == horario_para_minutos(ocup_hora)
              end
            end
          end
        end
        { id: prof.id, nome: prof.nome, vinculo: vinculo_ativo, especialidade: esp, horarios: horarios }
      end
    end

    sugestoes = []
    ordem_dias = { "SEGUNDA-FEIRA" => 1, "TERÇA-FEIRA" => 2, "QUARTA-FEIRA" => 3, "QUINTA-FEIRA" => 4, "SEXTA-FEIRA" => 5 }

    # 1. Montamos todas as vagas individuais disponíveis por dia
    vagas_flat = []
    especialidades.uniq.each do |esp|
      (vagas_por_especialidade[esp] || []).each do |v|
        v[:horarios].each do |dia, slots|
          slots.each do |slot|
            vagas_flat << { 
              esp: esp, 
              prof_id: v[:id], 
              prof_nome: v[:nome], 
              vinculo: v[:vinculo], 
              dia: dia, 
              hora: slot, 
              min: horario_para_minutos(slot) 
            }
          end
        end
      end
    end

    # 2. Busca de CADEIAS (Combos de 2 ou mais)
    # Tentamos montar a maior sequência possível a partir de cada vaga livre
    vagas_flat.group_by { |v| v[:dia] }.each do |dia, vagas_do_dia|
      vagas_do_dia.sort_by! { |v| v[:min] }
      
      vagas_do_dia.each do |v_start|
        cadeia = [v_start]
        esps_na_cadeia = [v_start[:esp]]
        
        # Tenta estender a cadeia consecutivamente (+40 min)
        while true
          ultimo = cadeia.last
          proximo_min = ultimo[:min] + 40
          
          # Busca uma vaga de uma especialidade que ainda não está nesta cadeia
          v_next = vagas_do_dia.find do |v| 
            v[:min] == proximo_min && !esps_na_cadeia.include?(v[:esp])
          end
          
          if v_next
            cadeia << v_next
            esps_na_cadeia << v_next[:esp]
          else
            break
          end
        end

        if cadeia.length >= 2
          sugestoes << {
            prioridade: "combo",
            dia: dia,
            atendimentos: cadeia.map { |c| { especialidade: c[:esp], profissional: c[:prof_nome], profissional_id: c[:prof_id], vinculo: c[:vinculo], horario: c[:hora] } }
          }
        end
      end
    end

    # 3. Incluímos as vagas individuais (para quando não há combo disponível)
    vagas_flat.each do |v|
      sugestoes << {
        prioridade: "individual",
        dia: v[:dia],
        atendimentos: [{ especialidade: v[:esp], profissional: v[:prof_nome], profissional_id: v[:prof_id], vinculo: v[:vinculo], horario: v[:hora] }]
      }
    end

    # 4. Ordenação Final
    sugestoes.sort_by! do |s|
      # Prioridade 1: Tamanho do combo (mais atendimentos primeiro)
      tamanho = -s[:atendimentos].length 
      # Prioridade 2: Vínculo (se algum atendimento na cadeia for com profissional que o paciente já conhece)
      tem_vinculo = s[:atendimentos].any? { |a| a[:vinculo] } ? 0 : 1
      # Prioridade 3: Ordem cronológica na semana
      dia_num = ordem_dias[s[:dia]] || 9
      hora_num = horario_para_minutos(s[:atendimentos].first[:horario])

      [tamanho, tem_vinculo, dia_num, hora_num]
    end

    # 5. Removemos duplicatas parciais (ex: se tem um combo de 3, não precisa mostrar o combo de 2 que faz parte dele no mesmo horário)
    # Isso limpa a interface.
    sugestoes.uniq! { |s| [s[:dia], s[:atendimentos].map { |a| [a[:horario], a[:profissional_id]] }] }
    sugestoes
  end

  def horario_para_minutos(h)
    return 0 if h.blank?
    hh, mm = h.to_s.downcase.gsub('h', ':').split(':')
    hh.to_i * 60 + mm.to_i
  end

  def extrair_especialidades(campo)
    return [] if campo.blank?
    begin
      parsed = JSON.parse(campo)
      if parsed.is_a?(Hash)
        parsed.keys.map(&:to_s).reject(&:blank?)
      elsif parsed.is_a?(Array)
        parsed.map(&:to_s).reject(&:blank?)
      else
        []
      end
    rescue JSON::ParserError
      campo.split(",").map(&:strip).reject(&:blank?)
    end
  end

  def extrair_frequencias(campo)
    return {} if campo.blank?
    begin
      parsed = JSON.parse(campo)
      if parsed.is_a?(Hash)
        parsed.transform_keys(&:to_s)
      elsif parsed.is_a?(Array)
        parsed.each_with_object({}) { |esp, h| h[esp.to_s] = 1 }
      else
        {}
      end
    rescue JSON::ParserError
      campo.split(",").map(&:strip).reject(&:blank?).each_with_object({}) { |esp, h| h[esp.upcase] = 1 }
    end
  end
end
