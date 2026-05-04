# app/services/auditoria_service.rb
class AuditoriaService
  def self.log(request, acao, entidade, detalhes = nil)
    # Extrai informações dos headers (injetadas pelo auth.js no front)
    user_id   = request.headers['X-User-Id']
    user_name = request.headers['X-User-Name'] || 'Sistema'
    setor     = request.headers['X-User-Role'] || 'Desconhecido'
    ip        = request.remote_ip

    # Se 'entidade' for um objeto ActiveRecord, extraímos o tipo e ID
    tipo = entidade.is_a?(String) ? entidade : entidade.class.name
    id   = entidade.is_a?(String) ? nil : (entidade.respond_to?(:id) ? entidade.id : nil)

    # Cria o registro de auditoria
    Auditoria.create!(
      user_id: user_id,
      user_name: user_name,
      setor: setor,
      acao: acao.to_s.upcase,
      entidade_tipo: tipo,
      entidade_id: id,
      detalhes: detalhes.is_a?(Hash) ? detalhes.to_json : detalhes.to_s,
      ip_address: ip
    )
  rescue => e
    Rails.logger.error "[AuditoriaService Error]: #{e.message}"
    # Não travamos a execução principal por erro no log
  end
end
