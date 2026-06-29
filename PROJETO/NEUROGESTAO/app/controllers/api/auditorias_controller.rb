class Api::AuditoriasController < ApplicationController
  before_action :validar_usuario_logado!
  before_action :validar_acesso_gestao!

  # GET /api/auditorias
  def index
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 50).to_i
    offset = (page - 1) * per_page

    query = Auditoria.recentes

    # Filtro por Busca livre (LOWER case-insensitive)
    if params[:busca].present?
      termo = "%#{params[:busca]}%"
      query = query.where(
        "LOWER(user_name) LIKE ? OR LOWER(acao) LIKE ? OR LOWER(detalhes) LIKE ? OR LOWER(entidade_tipo) LIKE ?",
        termo.downcase, termo.downcase, termo.downcase, termo.downcase
      )
    end

    # Filtro por Ação específica
    if params[:acao].present?
      query = query.where(acao: params[:acao])
    end

    # Filtro por Data Inicial
    if params[:data_inicio].present?
      begin
        query = query.where("created_at >= ?", Date.parse(params[:data_inicio]).beginning_of_day)
      rescue ArgumentError
        # Ignora datas inválidas
      end
    end

    # Filtro por Data Final
    if params[:data_fim].present?
      begin
        query = query.where("created_at <= ?", Date.parse(params[:data_fim]).end_of_day)
      rescue ArgumentError
        # Ignora datas inválidas
      end
    end

    total_registros = query.count
    auditorias = query.offset(offset).limit(per_page)

    # Coleta todas as ações únicas para preencher o filtro select no front
    acoes_disponiveis = Auditoria.distinct.pluck(:acao).compact.sort

    render json: {
      auditorias: auditorias,
      acoes_disponiveis: acoes_disponiveis,
      total: total_registros,
      pagina_atual: page,
      total_paginas: (total_registros.to_f / per_page).ceil
    }
  end
end
