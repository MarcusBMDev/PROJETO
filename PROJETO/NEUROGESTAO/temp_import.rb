caminho = "storage/planilhas/agendamento.xlsx"
puts "Iniciando importação do arquivo: #{caminho}"
ImportadorAgendaService.new(caminho).executar
puts "Processo finalizado!"