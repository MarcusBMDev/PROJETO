# app/models/user.rb
class User < NeurochatRecord
  # Define o nome exato da tabela no banco legado
  self.table_name = "users"

  # Método para validar a senha em texto puro do Laravel/novo banco
  def autentica_senha?(senha_digitada)
    return false if self.password.blank?
    self.password == senha_digitada
  end

  # Regra de Negócio para Acesso
  def acesso_agendamento?
    true 
  end
end