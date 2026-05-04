File.open("final_diagnostic.txt", "w") do |f|
  f.puts "--- PART 1: Ana Carolina ID 3 ---"
  prof = Profissional.find(3)
  agendamentos = prof.agendamentos
  f.puts "Total records for Ana Carolina: #{agendamentos.count}"
  
  agendamentos.each do |a|
    f.puts "- ID: #{a.id} | Day: #{a.dia_semana} | Time: #{a.horario} | Patient: #{a.paciente&.nome}"
  end
  
  f.puts "\n--- PART 2: Simulated JSON for strategic Grade ---"
  ctrl = Api::AgendamentosController.new
  ctrl.request = ActionDispatch::Request.new({})
  ctrl.response = ActionDispatch::Response.new
  ctrl.params = { id: 3 }
  ctrl.por_profissional
  payload = JSON.parse(ctrl.response.body)
  
  isa_json = payload.find{|j| j['paciente_nome']&.include?('ISA CECILIA')}
  f.puts "ISA CECILIA in JSON: #{isa_json.inspect}"

  f.puts "\n--- PART 3: Dashboard Card Math ---"
  atv = Profissional.ativos.count
  slots_da_semana = ClinicSlots::MONDAY.size + (ClinicSlots::STANDARD.size * 4)
  total_cap = atv * slots_da_semana
  f.puts "Active Profs: #{atv} | Slots/Week: #{slots_da_semana} | Total Cap: #{total_cap}"
  
  ocupados = 0
  Agendamento.where(status: ['confirmado', 'pendente']).each do |ag|
    if ag.horario.to_s.include?('-')
      p1, p2 = ag.horario.split('-')
      h1, m1 = p1.to_s.downcase.gsub('h',':').split(':')
      h2, m2 = p2.to_s.downcase.gsub('h',':').split(':')
      minutos = ((h2.to_i * 60 + m2.to_i) - (h1.to_i * 60 + m1.to_i))
      ocupados += [minutos / 40, 1].max
    else
      ocupados += 1
    end
  end
  f.puts "Global Occupation (Calculated): #{ocupados}"
  f.puts "Vacancies for Card: #{total_cap - ocupados}"
end
