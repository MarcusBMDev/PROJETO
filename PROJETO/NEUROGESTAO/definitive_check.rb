File.open("definitive_fix.txt", "w") do |f|
  # 1. Stats reconciliation
  atv = Profissional.ativos.count
  slots_da_semana = ClinicSlots::MONDAY.size + (ClinicSlots::STANDARD.size * 4)
  total_cap = atv * slots_da_semana
  
  slots_ocup_globais = 0
  Agendamento.where(status: ['confirmado', 'pendente']).each do |ag|
    if ag.horario.to_s.include?('-')
      p1, p2 = ag.horario.split('-')
      h1, m1 = p1.to_s.downcase.gsub('h',':').split(':')
      h2, m2 = p2.to_s.downcase.gsub('h',':').split(':')
      minutos = ((h2.to_i * 60 + m2.to_i) - (h1.to_i * 60 + m1.to_i))
      slots_ocup_globais += [minutos / 40, 1].max
    else
      slots_ocup_globais += 1
    end
  end
  
  f.puts "DATA FOR DASHBOARD CARD:"
  f.puts "Total Capacity: #{total_cap} (Profs: #{atv})"
  f.puts "Occupied Slots: #{slots_ocup_globais}"
  f.puts "Available: #{total_cap - slots_ocup_globais}"
  
  # 2. Ana Carolina Day Audit
  prof = Profissional.find(3)
  f.puts "\nANA CAROLINA (ID 3) ALL APPOINTMENTS:"
  prof.agendamentos.order(:horario).each do |a|
    f.puts "[#{a.dia_semana}] #{a.horario} - #{a.paciente&.nome} (ID: #{a.id})"
  end
  
  # 3. Check for hidden Ana Carolinas
  f.puts "\nOTHER ANA CAROLINAS?"
  Profissional.where("nome LIKE '%ANA CAROLINA%'").each do |p|
    next if p.id == 3
    f.puts "FOUND ANOTHER: ID #{p.id} | Name: #{p.nome}"
  end
end
