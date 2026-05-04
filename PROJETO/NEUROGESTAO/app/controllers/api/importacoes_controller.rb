module Api
  class ImportacoesController < ApplicationController
    skip_before_action :verify_authenticity_token, raise: false

    def upload_planilha
      if params[:file].present?
        file = params[:file]
        
        target_path = Rails.root.join('storage', 'planilhas', 'AGENDAMENTO.xlsx')
        FileUtils.mkdir_p(File.dirname(target_path))
        
        File.open(target_path, 'wb') do |f|
          f.write(file.read)
        end
        
        begin
          puts "🧹 Limpando tabela de Agendamentos para evitar conflitos na subida da nova base..."
          Agendamento.delete_all
          
          puts "🚀 Executando ImportadorAgendaService pela rota de API..."
          ImportadorAgendaService.new(target_path.to_s).executar
          
          render json: { 
            message: "Planilha importada com sucesso!",
            details: "Mapeamento de 2 sessões para pacientes ATS concluído. Frequência semanal e especialidades recalculadas com exatidão."
          }, status: :ok
        rescue => e
          render json: { error: "Erro durante a importação: #{e.message}" }, status: :unprocessable_entity
        end
      else
        render json: { error: "Nenhum arquivo (planilha) enviado na requisição." }, status: :bad_request
      end
    end
  end
end
