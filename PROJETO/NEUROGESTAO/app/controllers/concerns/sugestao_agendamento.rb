module SugestaoAgendamento
  extend ActiveSupport::Concern

  def buscar_sugestoes_consecutivos(especialidades, age, frequencias = {}, agendamentos_existentes = [])
    return [] if especialidades.blank?

    todos_slots_por_dia = ClinicSlots::ALL

    vagas_por_especialidade = {}
    especialidades.each do |esp|
      # Busca apenas profissionais ATIVOS que possuam a especialidade
      profissionais = Profissional.ativos.where("especialidade LIKE ?", "%#{esp.upcase}%").to_a
      profissionais.select! { |p| p.especialidade.to_s.upcase.split(',').map(&:strip).include?(esp.upcase) }

      if age.present?
        profissionais.select! { |p| (p.min_age.nil? || p.min_age <= age) && (p.max_age.nil? || p.max_age >= age) }
      end

      vagas_por_especialidade[esp] = profissionais.map do |prof|
        # Consideramos tanto agendamentos confirmados quanto pendentes como "ocupados"
        ocupados = prof.agendamentos.where(status: ['confirmado', 'pendente']).pluck(:horario, :dia_semana)
        
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
        { id: prof.id, nome: prof.nome, especialidade: esp, horarios: horarios }
      end
    end

    sugestoes = []
    esp_keys = especialidades.uniq

    # Lógica de Encaixe com Agendamentos Existentes
    if agendamentos_existentes.any?
      esp_keys.each do |esp|
        vagas = vagas_por_especialidade[esp] || []
        vagas.each do |v|
          v[:horarios].each do |dia, slots|
            ag_do_dia = agendamentos_existentes.select do |ag| 
              ag.dia_semana.to_s.upcase.split('-').first == dia.to_s.upcase.split('-').first 
            end
            
            slots.each do |slot_livre|
              min_livre = horario_para_minutos(slot_livre)
              
              ag_do_dia.each do |ag|
                min_existente = horario_para_minutos(ag.horario.split('-').first)
                diff = (min_livre - min_existente)
                
                if diff.abs == 40
                  esp_ex = ag.profissional.especialidade.split(',').first
                  if diff > 0 # slot livre vem DEPOIS do agendamento existente
                    at1 = { especialidade: esp_ex, profissional: "#{ag.profissional.nome} (Já Agendado)", profissional_id: ag.profissional_id, horario: ag.horario.split('-').first, ja_agendado: true }
                    at2 = { especialidade: esp, profissional: v[:nome], profissional_id: v[:id], horario: slot_livre, ja_agendado: false }
                  else # slot livre vem ANTES
                    at1 = { especialidade: esp, profissional: v[:nome], profissional_id: v[:id], horario: slot_livre, ja_agendado: false }
                    at2 = { especialidade: esp_ex, profissional: "#{ag.profissional.nome} (Já Agendado)", profissional_id: ag.profissional_id, horario: ag.horario.split('-').first, ja_agendado: true }
                  end

                  sugestoes << {
                    prioridade: "consecutivo",
                    dia: dia,
                    atendimento_1: at1,
                    atendimento_2: at2
                  }
                end
              end
            end
          end
        end
      end
    end

    # Usamos repeated_permutation para permitir combos da mesma especialidade (ex: Fono + Fono)
    esp_keys.repeated_permutation(2).each do |esp_a, esp_b|
      # Se for a mesma especialidade, só sugere combo se a frequência pedida for >= 2
      if esp_a == esp_b && (frequencias[esp_a].to_i < 2)
        next
      end

      profs_a = vagas_por_especialidade[esp_a] || []
      profs_b = vagas_por_especialidade[esp_b] || []

      profs_a.each do |pa|
        profs_b.each do |pb|
          # Se for a mesma especialidade, aceitamos o mesmo profissional (sessão dupla)
          # Se forem especialidades diferentes, preferimos profissionais diferentes ou permitimos o mesmo (flexível)
          # Por enquanto, vamos permitir o mesmo profissional para encorajar combos
          todos_slots_por_dia.keys.each do |dia|
            slots_a = pa[:horarios][dia] || []
            slots_b = pb[:horarios][dia] || []

            slots_a.each do |slot_a|
              min_a = horario_para_minutos(slot_a)
              
              slots_b.each do |slot_b|
                min_b = horario_para_minutos(slot_b)
                diff = min_b - min_a

                # Consecutivo: exatamente 40 minutos de diferença (uma sessão após a outra)
                if diff == 40
                  sugestoes << {
                    prioridade: "consecutivo",
                    dia: dia,
                    atendimento_1: { especialidade: esp_a, profissional: pa[:nome], profissional_id: pa[:id], horario: slot_a },
                    atendimento_2: { especialidade: esp_b, profissional: pb[:nome], profissional_id: pb[:id], horario: slot_b }
                  }
                # Próximo: 80 minutos de diferença (um slot vago de 40min entre eles)
                elsif diff == 80
                  sugestoes << {
                    prioridade: "proximo",
                    dia: dia,
                    atendimento_1: { especialidade: esp_a, profissional: pa[:nome], profissional_id: pa[:id], horario: slot_a },
                    atendimento_2: { especialidade: esp_b, profissional: pb[:nome], profissional_id: pb[:id], horario: slot_b }
                  }
                end
              end
            end
          end
        end
      end
    end

    # Sempre incluímos vagas individuais também, para dar opção ao usuário
    esp_keys.each do |esp|
      vagas = vagas_por_especialidade[esp] || []
      vagas.each do |v|
        v[:horarios].each do |dia, slots|
          slots.each do |slot|
            sugestoes << {
              prioridade: "individual",
              dia: dia,
              atendimento_1: { especialidade: esp, profissional: v[:nome], profissional_id: v[:id], horario: slot },
              atendimento_2: nil
            }
            break if sugestoes.length >= 20
          end
          break if sugestoes.length >= 20
        end
        break if sugestoes.length >= 20
      end
    end

    ordem_dias = { "SEGUNDA-FEIRA" => 1, "TERÇA-FEIRA" => 2, "QUARTA-FEIRA" => 3, "QUINTA-FEIRA" => 4, "SEXTA-FEIRA" => 5 }
    sugestoes.sort_by! do |s| 
      pri_score = case s[:prioridade]
                  when "consecutivo" then 0
                  when "proximo"     then 1
                  else 2
                  end
      [pri_score, ordem_dias[s[:dia]] || 9, horario_para_minutos(s[:atendimento_1][:horario])]
    end
    sugestoes.uniq { |s| [s[:dia], s[:atendimento_1], s[:atendimento_2]] }.first(20)
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
