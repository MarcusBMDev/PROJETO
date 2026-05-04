class Api::ProfissionaisController < ApplicationController
  before_action :validar_acesso_gestao!, except: [:index, :especialidades]
  # GET /profissionais
  def index
    # Retorna TODOS para que a interface decida onde exibir inativos
    render json: Profissional.order(:nome).all.map { |p| 
      json = p.as_json(only: [:id, :nome, :especialidade, :ativo, :min_age, :max_age])
      begin
        json[:curriculo_url] = p.curriculo.attached? ? rails_blob_url(p.curriculo, only_path: true) : nil
        json[:curriculo_nome] = p.curriculo.attached? ? p.curriculo.filename.to_s : nil
      rescue
        json[:curriculo_url] = nil
        json[:curriculo_nome] = nil
      end
      json
    }
  end

  # GET /profissionais/especialidades
  def especialidades
    render json: Especialidade.order(:nome).pluck(:nome)
  end

  # POST /profissionais
  def create
    @profissional = Profissional.new(profissional_params)
    @profissional.ativo = true
    if @profissional.save
      registrar_especialidade(@profissional.especialidade)
      AuditoriaService.log(request, 'CRIAR_PROFISSIONAL', @profissional, "Especialidade: #{@profissional.especialidade}")
      render json: profissional_json(@profissional), status: :created
    else
      render json: { errors: @profissional.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /profissionais/:id
  def update
    @profissional = Profissional.find(params[:id])
    if @profissional.update(profissional_params)
      registrar_especialidade(@profissional.especialidade)
      render json: profissional_json(@profissional)
    else
      render json: { errors: @profissional.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /profissionais/:id/share_curriculo
  def share_curriculo
    @profissional = Profissional.find(params[:id])
    setor = request.headers['X-User-Role'] || 'Gestão Neuro'

    if @profissional.curriculo.attached?
      link = rails_blob_url(@profissional.curriculo, host: request.base_url)
      NeurochatService.notificar_curriculo_profissional(@profissional, link, setor)
      render json: { message: "Currículo de #{@profissional.nome} compartilhado no Neurochat." }
    else
      render json: { error: "Este profissional não possui currículo anexado." }, status: :unprocessable_entity
    end
  end

  # DELETE /profissionais/:id
  def destroy
    @profissional = Profissional.find(params[:id])
    setor = request.headers['X-User-Role'] || 'Desconhecido'

    # Se tiver agendamentos, apenas inativa (Pedido do Usuário)
    if @profissional.agendamentos.exists?
      @profissional.inativar!
      AuditoriaService.log(request, 'INATIVAR_PROFISSIONAL', @profissional, "Possui agendamentos")
      NeurochatService.notificar_inativacao_profissional(@profissional, setor)
      render json: { 
        status: 'inactivated',
        mensagem: "Profissional inativado com sucesso (possui agendamentos). O grupo de agendamentos foi notificado." 
      }
      return
    end

    # Se não tiver agendamentos, tenta excluir (se houver transferências, o restrict_with_error vai agir)
    if @profissional.destroy
      AuditoriaService.log(request, 'EXCLUIR_PROFISSIONAL', @profissional, "Remoção física do banco")
      render json: { 
        status: 'deleted',
        mensagem: "Profissional removido com sucesso do banco de dados." 
      }
    else
      # Se falhou a exclusão (ex: por histórico de transferências), inativamos
      @profissional.inativar!
      AuditoriaService.log(request, 'INATIVAR_PROFISSIONAL', @profissional, "Possui histórico de transferências")
      NeurochatService.notificar_inativacao_profissional(@profissional, setor)
      render json: { 
        status: 'inactivated',
        mensagem: "Profissional inativado (possui histórico de transferências). O grupo de agendamentos foi notificado." 
      }
    end
  end

  private

  def profissional_json(p)
    json = p.as_json(only: [:id, :nome, :especialidade, :ativo, :min_age, :max_age])
    begin
      json[:curriculo_url] = p.curriculo.attached? ? rails_blob_url(p.curriculo, only_path: true) : nil
      json[:curriculo_nome] = p.curriculo.attached? ? p.curriculo.filename.to_s : nil
    rescue
      json[:curriculo_url] = nil
      json[:curriculo_nome] = nil
    end
    json
  end

  # Mantém a tabela de especialidades sempre sincronizada
  def registrar_especialidade(nomes)
    return if nomes.blank?
    nomes.split(',').each do |n|
      Especialidade.find_or_create_by(nome: n.upcase.strip)
    end
  end

  def profissional_params
    params.require(:profissional).permit(:nome, :especialidade, :min_age, :max_age, :ativo, :curriculo)
  end
end