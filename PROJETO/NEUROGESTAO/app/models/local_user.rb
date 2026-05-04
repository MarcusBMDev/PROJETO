# app/models/local_user.rb
class LocalUser < ApplicationRecord
  self.table_name = "users"

  # Método para validar a senha em texto puro do banco local
  def autentica_senha?(senha_digitada)
    return false if self.password.blank?
    self.password == senha_digitada
  end

  # Regra de Negócio para Acesso
  def acesso_agendamento?
    true 
  end
end
