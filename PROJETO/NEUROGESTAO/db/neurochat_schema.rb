# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_04_09_192942) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "admins_financeiro", primary_key: "usuario_id", id: :integer, default: nil, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
  end

  create_table "agendamentos", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "bloqueado_por"
    t.integer "bloqueado_por_id"
    t.bigint "convenio_id"
    t.datetime "created_at", null: false
    t.string "dia_semana"
    t.boolean "encaixe", default: false
    t.string "horario"
    t.bigint "lista_espera_id"
    t.text "motivo_bloqueio"
    t.text "observacoes"
    t.bigint "paciente_id"
    t.bigint "profissional_id", null: false
    t.string "status", default: "confirmado"
    t.datetime "updated_at", null: false
    t.index ["convenio_id"], name: "index_agendamentos_on_convenio_id"
    t.index ["lista_espera_id"], name: "index_agendamentos_on_lista_espera_id"
    t.index ["paciente_id"], name: "index_agendamentos_on_paciente_id"
    t.index ["profissional_id", "dia_semana", "horario"], name: "idx_agendamentos_busca"
    t.index ["profissional_id"], name: "index_agendamentos_on_profissional_id"
    t.index ["status"], name: "index_agendamentos_on_status"
  end

  create_table "bookings", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.timestamp "created_at", default: -> { "current_timestamp()" }, null: false
    t.datetime "end_time", precision: nil, null: false
    t.text "materials"
    t.string "role"
    t.integer "room_id", null: false
    t.datetime "start_time", precision: nil, null: false
    t.string "title"
    t.integer "user_id", null: false
    t.index ["room_id"], name: "room_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "convenios", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "ativo"
    t.datetime "created_at", null: false
    t.text "especialidades_atendidas"
    t.text "exigencias"
    t.string "nome"
    t.datetime "updated_at", null: false
  end

  create_table "especialidades", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "nome", null: false
    t.datetime "updated_at", null: false
    t.index ["nome"], name: "index_especialidades_on_nome", unique: true
  end

  create_table "group_members", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "group_id", null: false
    t.boolean "is_admin", default: false
    t.datetime "last_view", precision: nil, default: -> { "current_timestamp()" }
    t.integer "user_id", null: false
  end

  create_table "groups", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "created_by"
    t.boolean "is_broadcast", default: false
    t.string "name", limit: 100, null: false
  end

  create_table "lista_espera", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "age"
    t.date "birth_date"
    t.datetime "created_at", null: false
    t.string "especialidade"
    t.string "nome"
    t.text "observacao"
    t.bigint "paciente_id"
    t.text "planned_specialties"
    t.string "status", default: "aguardando"
    t.string "telefone"
    t.datetime "updated_at", null: false
    t.index ["paciente_id"], name: "index_lista_espera_on_paciente_id"
  end

  create_table "marketing_requests", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "approver", null: false
    t.timestamp "created_at", default: -> { "current_timestamp()" }, null: false
    t.date "deadline", null: false
    t.string "department"
    t.text "description", null: false
    t.text "main_message", null: false
    t.text "notes"
    t.text "reference_files"
    t.text "references_text"
    t.string "request_type", limit: 100, null: false
    t.string "requester_name", null: false
    t.string "status", limit: 50, default: "Pendente"
    t.integer "user_id", null: false
  end

  create_table "message_reactions", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "message_id", null: false
    t.string "reaction", limit: 50, null: false
    t.datetime "timestamp", precision: nil, default: -> { "current_timestamp()" }
    t.integer "user_id", null: false
    t.index ["message_id"], name: "message_id"
    t.index ["user_id"], name: "user_id"
  end

  create_table "messages", id: :integer, charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "file_name"
    t.boolean "is_deleted", default: false
    t.boolean "is_edited", default: false
    t.boolean "is_forwarded", default: false
    t.boolean "is_pinned", default: false
    t.boolean "is_read", default: false
    t.string "msg_type", limit: 20, default: "text"
    t.integer "reply_to_id"
    t.string "sender_name", limit: 100
    t.integer "target_id", null: false
    t.string "target_type", limit: 20, default: "user"
    t.text "text"
    t.datetime "timestamp", precision: nil, default: -> { "current_timestamp()" }
    t.integer "user_id", null: false
  end

  create_table "nc_movimentacao_itens", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "movimentacao_id", null: false
    t.integer "produto_id", null: false
    t.integer "quantidade", null: false
    t.index ["movimentacao_id"], name: "movimentacao_id"
    t.index ["produto_id"], name: "produto_id"
  end

  create_table "nc_movimentacoes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "data_movimentacao", precision: nil, default: -> { "current_timestamp()" }
    t.date "nfe_data"
    t.string "nfe_numero", limit: 50
    t.text "observacao"
    t.string "setor", limit: 100
    t.column "tipo", "enum('entrada','saida')", null: false
    t.integer "usuario_id"
  end

  create_table "nc_produtos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "ativo", default: true
    t.string "codigo", limit: 50
    t.integer "minimo", default: 5
    t.string "nome", null: false
    t.integer "quantidade", default: 0
    t.string "unidade", limit: 20, default: "un"
  end

  create_table "neuroprint_admins", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.timestamp "added_at", default: -> { "current_timestamp()" }, null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "fk_neuroprint_admin"
  end

  create_table "neuroprint_jobs", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.column "color_mode", "enum('PB','Colorida')", default: "PB"
    t.integer "copies", default: 1
    t.timestamp "created_at", default: -> { "current_timestamp()" }, null: false
    t.datetime "deadline", precision: nil
    t.string "file_name", null: false
    t.string "file_path", limit: 500, null: false
    t.string "file_type", limit: 50
    t.boolean "is_duplex", default: false
    t.boolean "is_urgent", default: false
    t.text "observacao"
    t.string "page_range", limit: 100, default: "Todas"
    t.string "sector", limit: 100
    t.string "status", limit: 50, default: "pendente"
    t.integer "total_pages", default: 0
    t.integer "total_printed", default: 0
    t.boolean "two_per_page", default: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "idx_created_at"
    t.index ["status"], name: "idx_status"
    t.index ["user_id"], name: "idx_user_id"
  end

  create_table "ouvidoria_reclamacoes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.timestamp "created_at", default: -> { "current_timestamp()" }, null: false
    t.datetime "data_reclamacao", precision: nil, default: -> { "current_timestamp()" }
    t.string "paciente"
    t.date "prazo_resposta"
    t.text "relato", null: false
    t.integer "responsavel_id"
    t.text "resposta_setor"
    t.string "setor_responsavel"
    t.column "status", "enum('Nova','Em Análise','Encaminhada','Respondida','Finalizada')", default: "Nova"
    t.column "tipo_solicitante", "enum('Funcionario','Paciente')", default: "Paciente"
    t.column "unidade", "enum('Unidade 1','Unidade 2','Unidade 3')", null: false
    t.integer "usuario_id", null: false
    t.index ["usuario_id"], name: "usuario_id"
  end

  create_table "pacientes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "age"
    t.date "birth_date"
    t.integer "convenio_id"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "nome"
    t.text "planned_specialties"
    t.string "status"
    t.datetime "updated_at", null: false
    t.integer "weekly_frequency"
    t.index ["nome"], name: "index_pacientes_on_nome", unique: true
  end

  create_table "profissionais", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.boolean "ativo", default: true
    t.datetime "created_at", null: false
    t.string "especialidade"
    t.integer "max_age"
    t.integer "min_age"
    t.string "nome"
    t.datetime "updated_at", null: false
  end

  create_table "requisicoes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "data_atualizacao", precision: nil, default: -> { "current_timestamp() ON UPDATE current_timestamp()" }
    t.datetime "data_criacao", precision: nil, default: -> { "current_timestamp()" }
    t.text "descricao", null: false
    t.text "foto_caminho"
    t.text "link_produto"
    t.text "motivo_rejeicao"
    t.string "nome_solicitante", limit: 100, null: false
    t.date "prazo_limite"
    t.string "setor", limit: 50, null: false
    t.column "status", "enum('Pendente','Aprovado','Rejeitado','Vital','Pedido Feito','Chegou')", default: "Pendente"
    t.column "urgencia", "enum('Baixa','Media','Alta')", default: "Baixa"
    t.integer "usuario_id", null: false
    t.decimal "valor", precision: 10, scale: 2, default: "0.0"
    t.index ["usuario_id"], name: "fk_usuario_compra"
  end

  create_table "rh_admins", primary_key: "user_id", id: :integer, default: nil, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "data_cadastro", precision: nil, default: -> { "current_timestamp()" }
  end

  create_table "rh_arquivos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "caminho_arquivo"
    t.string "categoria", limit: 50
    t.text "conteudo_texto"
    t.datetime "data_upload", precision: nil, default: -> { "current_timestamp()" }
    t.string "titulo", limit: 100
  end

  create_table "rh_atestados", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "caminho_arquivo"
    t.datetime "data_envio", precision: nil, default: -> { "current_timestamp()" }
    t.integer "usuario_id"
  end

  create_table "rh_solicitacoes", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "caminho_anexo"
    t.datetime "data_criacao", precision: nil, default: -> { "current_timestamp()" }
    t.date "data_evento"
    t.text "descricao"
    t.string "status", limit: 20, default: "pendente"
    t.string "tipo", limit: 50, null: false
    t.integer "usuario_id", null: false
    t.index ["usuario_id"], name: "usuario_id"
  end

  create_table "rooms", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name", null: false
  end

  create_table "transferencias", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "agendamento_ids"
    t.bigint "agendamento_origem_id"
    t.datetime "created_at", null: false
    t.bigint "de_profissional_id"
    t.boolean "encaixe"
    t.text "motivo"
    t.string "novo_dia_semana"
    t.string "novo_horario"
    t.bigint "paciente_id", null: false
    t.bigint "para_profissional_id"
    t.string "solicitante"
    t.string "status", default: "pendente"
    t.integer "tipo", default: 0
    t.datetime "updated_at", null: false
    t.index ["de_profissional_id"], name: "index_transferencias_on_de_profissional_id"
    t.index ["paciente_id"], name: "index_transferencias_on_paciente_id"
    t.index ["para_profissional_id"], name: "index_transferencias_on_para_profissional_id"
  end

  create_table "user_restrictions", primary_key: ["user_id", "restricted_department"], charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "restricted_department", limit: 100, null: false
    t.integer "user_id", null: false
  end

  create_table "users", id: :integer, charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "blocked_departments"
    t.string "department", limit: 50
    t.boolean "is_active", default: true
    t.boolean "is_blocked", default: false
    t.boolean "is_super_admin", default: false
    t.datetime "last_interaction", precision: nil
    t.string "password", limit: 100, null: false
    t.string "photo"
    t.boolean "restrict_inter_dept", default: false
    t.string "setor", limit: 50, default: "GERAL"
    t.string "username", limit: 50, null: false
    t.index ["username"], name: "username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "admins_financeiro", "users", column: "usuario_id", name: "fk_admin_user", on_delete: :cascade
  add_foreign_key "agendamentos", "convenios"
  add_foreign_key "agendamentos", "pacientes"
  add_foreign_key "agendamentos", "profissionais"
  add_foreign_key "bookings", "rooms", name: "bookings_ibfk_1"
  add_foreign_key "bookings", "users", name: "bookings_ibfk_2", on_delete: :cascade
  add_foreign_key "message_reactions", "messages", name: "message_reactions_ibfk_1", on_delete: :cascade
  add_foreign_key "message_reactions", "users", name: "message_reactions_ibfk_2", on_delete: :cascade
  add_foreign_key "nc_movimentacao_itens", "nc_movimentacoes", column: "movimentacao_id", name: "nc_movimentacao_itens_ibfk_1", on_delete: :cascade
  add_foreign_key "nc_movimentacao_itens", "nc_produtos", column: "produto_id", name: "nc_movimentacao_itens_ibfk_2", on_delete: :cascade
  add_foreign_key "neuroprint_admins", "users", name: "fk_neuroprint_admin", on_delete: :cascade
  add_foreign_key "neuroprint_jobs", "users", name: "fk_neuroprint_user", on_delete: :cascade
  add_foreign_key "ouvidoria_reclamacoes", "users", column: "usuario_id", name: "ouvidoria_reclamacoes_ibfk_1"
  add_foreign_key "requisicoes", "users", column: "usuario_id", name: "fk_usuario_compra", on_delete: :cascade
  add_foreign_key "rh_solicitacoes", "users", column: "usuario_id", name: "rh_solicitacoes_ibfk_1", on_delete: :cascade
  add_foreign_key "transferencias", "pacientes"
  add_foreign_key "transferencias", "profissionais", column: "de_profissional_id"
  add_foreign_key "transferencias", "profissionais", column: "para_profissional_id"
  add_foreign_key "user_restrictions", "users", name: "user_restrictions_ibfk_1", on_delete: :cascade
end
