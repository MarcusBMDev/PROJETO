class Api::ConveniosController < ApplicationController
  before_action :validar_acesso_gestao!, except: [:index]
  def index
    convenios = Convenio.all.order(:nome)
    render json: convenios.map { |c| 
      json = c.as_json(only: [:id, :nome, :ativo, :exigencias, :especialidades_atendidas])
      begin
        json[:documento_url] = c.documento.attached? ? rails_blob_url(c.documento, only_path: true) : nil
        json[:documento_nome] = c.documento.attached? ? c.documento.filename.to_s : nil
      rescue
        json[:documento_url] = nil
        json[:documento_nome] = nil
      end
      json
    }
  end

  def create
    convenio = Convenio.new(convenio_params)
    convenio.ativo = true
    if convenio.save
      render json: convenio_json(convenio), status: :created
    else
      render json: { errors: convenio.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    convenio = Convenio.find(params[:id])
    if convenio.update(convenio_params)
      render json: convenio_json(convenio)
    else
      render json: { errors: convenio.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    convenio = Convenio.find(params[:id])
    
    # Se não houver nenhum vínculo, podemos apagar de vez
    if convenio.pacientes.empty? && convenio.agendamentos.empty?
      convenio.destroy
      render json: { message: 'Convênio removido do sistema.' }
    else
      # Se houver vínculos, apenas inativamos para não quebrar o banco
      convenio.update(ativo: false)
      render json: { message: 'Convênio inativado devido a vínculos existentes.' }
    end
  end

  private

  def convenio_json(c)
    json = c.as_json(only: [:id, :nome, :ativo, :exigencias, :especialidades_atendidas])
    begin
      json[:documento_url] = c.documento.attached? ? rails_blob_url(c.documento, only_path: true) : nil
      json[:documento_nome] = c.documento.attached? ? c.documento.filename.to_s : nil
    rescue
      json[:documento_url] = nil
      json[:documento_nome] = nil
    end
    json
  end

  def convenio_params
    params.require(:convenio).permit(:nome, :exigencias, :especialidades_atendidas, :documento)
  end
end
