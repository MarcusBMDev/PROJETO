class ListaEspera < ApplicationRecord
  include AgeCalculable
  self.table_name = 'lista_espera'
  belongs_to :paciente, optional: true

  validates :nome, :especialidade, presence: true
  
  validates :nome, :especialidade, presence: true


  private

end
