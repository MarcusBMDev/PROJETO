class AuthController < ApplicationController
  def login
    # Tenta buscar no banco novo (agendamentos_clinica_dev)
    usuario = LocalUser.find_by(username: params[:username])

    # Se não achar, faz fallback para o banco legado (neurochat_db)
    unless usuario
      usuario = User.find_by(username: params[:username])
    end

    # Usa o método para validar o hash do Bcrypt / texto puro
    if usuario && usuario.autentica_senha?(params[:password])
      
      # Define o nível de acesso baseado no departamento/setor
      nivel_acesso = definir_nivel_de_acesso(usuario)

      render json: {
        autenticado: true,
        usuario: {
           id: usuario.id,
          nome: usuario.username,
          username: usuario.username,
          departamento: usuario.department,
          nivel_acesso: nivel_acesso,
          is_super_admin: usuario.is_super_admin
        }
      }, status: :ok
    else
      render json: { erro: "Usuário ou senha inválidos" }, status: :unauthorized
    end
  end

  private

  def definir_nivel_de_acesso(usuario)
    # Aqui mapeamos as regras de negócio da clínica
    setores_admin = ["Diretoria Geral", "Recepção", "Agendamento/Recepção", "TI"]
    
    if setores_admin.include?(usuario.department)
      "admin"
    else
      "profissional"
    end
  end
end