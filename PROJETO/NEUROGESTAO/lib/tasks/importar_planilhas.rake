namespace :agendamentos do
  # TASK 1: Importação da Planilha Principal (Grade Semanal)
  desc "Importa a planilha principal AGENDAMENTO.xlsx"
  task importar: :environment do
    arquivo = Rails.root.join('storage', 'planilhas', 'AGENDAMENTO.xlsx')
    
    unless File.exist?(arquivo)
      puts "❌ Erro: O arquivo AGENDAMENTO.xlsx não foi encontrado em storage/planilhas/"
      next # Pula para o final da task
    end

    puts "🚀 Iniciando importação da Grade Semanal..."
    ImportadorAgendaService.new(arquivo.to_s).executar
    puts "✅ Importação da Grade Finalizada!"
  end

  # TASK 2: Enriquecimento com Especialidades (Guias e AVN)
  desc "Importa a planilha de Guias e AVN para enriquecer especialidades"
  task guias: :environment do
    arquivo = Rails.root.join('storage', 'planilhas', 'GUIAS_AVN.xlsx')
    
    if File.exist?(arquivo)
      puts "🚀 Iniciando Enriquecimento de Dados (Especialidades)..."
      ImportadorGuiasService.new(arquivo.to_s).executar
      puts "✅ Dados de Especialidades e Guias atualizados com sucesso!"
    else
      puts "❌ Arquivo GUIAS_AVN.xlsx não encontrado em storage/planilhas/."
    end
  end

  # TASK 3: Limpar e Reimportar Tudo
  desc "Limpa a base de dados (Agendamentos, Pacientes, Profissionais, Convenios e Lista de Espera) e reimporta tudo"
  task resetar: :environment do
    puts "⚠️ APAGANDO DADOS ANTIGOS DA CLÍNICA..."
    Transferencia.delete_all
    Agendamento.delete_all
    ListaEspera.delete_all
    Paciente.delete_all
    Profissional.delete_all
    Convenio.delete_all
    puts "🗑️ Base de dados limpa com sucesso!"
    
    Rake::Task["agendamentos:importar"].invoke
    # Rake::Task["agendamentos:guias"].invoke # Se quiser rodar guias também junto, descomentar. Vamos rodar apenas o básico que o usuario pediu, ou ambos se for padrão.
  end
end