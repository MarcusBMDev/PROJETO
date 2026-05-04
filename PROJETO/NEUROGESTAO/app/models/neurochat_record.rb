# app/models/neurochat_record.rb
class NeurochatRecord < ApplicationRecord
  # Define que esta é uma classe base (ponte) e não uma tabela real
  self.abstract_class = true
  
  # A conexão fica aqui, protegida
  connects_to database: { writing: :neurochat, reading: :neurochat }
end