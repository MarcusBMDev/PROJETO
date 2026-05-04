class Agendamento < ApplicationRecord
  self.table_name = 'agendamentos'
  belongs_to :profissional
  belongs_to :paciente, optional: true
  belongs_to :convenio, optional: true
  belongs_to :bloqueador, class_name: 'User', foreign_key: 'bloqueado_por_id', optional: true

  validates :profissional_id, :dia_semana, :horario, presence: true
  validates :paciente_id, :convenio_id, presence: true, unless: -> { status == 'bloqueado' }

  # Regra 1: O PROFISSIONAL não pode ter dois pacientes no mesmo horário/dia (exceto se for ENCAIXE)
  validates :horario, uniqueness: {
    scope: [:profissional_id, :dia_semana],
    message: "já possui um agendamento para este profissional neste dia",
    unless: -> { encaixe }
  }

  # REGRA 2 REMOVIDA INTENCIONALMENTE:
  # Um paciente pode ter múltiplos atendimentos no mesmo dia (em especialidades diferentes).
  # Ex: ABA às 8h com Prof. Ana Paula e FONO às 8h40 com Prof. Jayde — no mesmo dia.
  # O sistema de sugestão de horários consecutivos considera essa possibilidade.
end