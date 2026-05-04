class Convenio < ApplicationRecord
  self.table_name = 'convenios'
  has_many :pacientes
  has_many :agendamentos
  has_one_attached :documento

  validates :nome, presence: true, uniqueness: true
end
