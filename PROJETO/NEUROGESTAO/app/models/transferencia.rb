class Transferencia < ApplicationRecord
  belongs_to :paciente
  belongs_to :de_profissional, class_name: 'Profissional', optional: true
  belongs_to :para_profissional, class_name: 'Profissional', optional: true

  enum :tipo, { transferencia: 0, remocao: 1, reducao: 2 }

  validates :paciente_id, :tipo, :solicitante, :motivo, presence: true, on: :create
end
