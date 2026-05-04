# app/models/auditoria.rb
class Auditoria < ApplicationRecord
  # Opcional: validações
  validates :user_name, presence: true
  validates :acao, presence: true
  validates :entidade_tipo, presence: true

  # Escopo para consultas rápidas
  scope :recentes, -> { order(created_at: :desc) }
end
