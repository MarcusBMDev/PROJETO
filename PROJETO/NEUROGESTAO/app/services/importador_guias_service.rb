# app/services/importador_guias_service.rb
require 'roo'

class ImportadorGuiasService
  def initialize(caminho_arquivo)
    @xlsx = Roo::Excelx.new(caminho_arquivo)
  end

  def executar
    processar_aba_guias
    processar_aba_avn
  end

  private

  def processar_aba_guias
    puts "--> Processando aba: Guias Março 2026"
    aba = @xlsx.sheet("Guias Março 2026")
    
    # Pulamos a primeira linha (cabeçalho)
    aba.each_with_index do |linha, index|
      next if index == 0 || linha[0].blank?

      nome_paciente   = limpar_nome(linha[0])
      nome_convenio   = linha[1].to_s.strip
      especialidade   = linha[2].to_s.strip
      nome_prof       = linha[5].to_s.strip

      # ATUALIZAÇÃO CRUCIAL: Vincula a especialidade ao profissional
      profissional = Profissional.find_or_create_by!(nome: nome_prof)
      profissional.update(especialidade: especialidade) if profissional.especialidade.blank?

      salvar_agendamento(nome_paciente, nome_convenio, profissional, especialidade, "GUIA MARÇO")
    end
  end

  def processar_aba_avn
    puts "--> Processando aba: AVN Março 2026"
    aba = @xlsx.sheet("AVN Março 2026")
    
    aba.each_with_index do |linha, index|
      next if index == 0 || linha[0].blank?

      nome_paciente = limpar_nome(linha[0])
      nome_convenio = linha[1].to_s.strip
      nome_prof     = linha[4].to_s.strip # Na AVN o Profissional está na coluna E (index 4)

      profissional = Profissional.find_or_create_by!(nome: nome_prof)
      
      # Como AVN não tem coluna de especialidade, usamos "AVN" como padrão se estiver vazio
      salvar_agendamento(nome_paciente, nome_convenio, profissional, "Avaliação Neuropsicológica", "AVN MARÇO")
    end
  end

  def limpar_nome(nome)
    nome.to_s.strip.gsub(/\s*-\s*ABA\s*$/i, '')
  end

  def salvar_agendamento(nome_pac, nome_conv, profissional, espec, obs)
    paciente = Paciente.find_or_create_by!(nome: nome_pac)
    convenio = Convenio.find_or_create_by!(nome: nome_conv.blank? ? "Particular" : nome_conv)

    # Cria o registro de agendamento (evita duplicatas exatas)
    Agendamento.find_or_create_by!(
      profissional: profissional,
      paciente: paciente,
      convenio: convenio,
      observacoes: obs
    )
  end
end