class Especialidade < ApplicationRecord
  # Garante que o nome seja salvo sempre em maiúsculas para manter o padrão de Palmas
  before_save { self.nome = nome.upcase.strip }
  
  validates :nome, presence: true, uniqueness: true
end