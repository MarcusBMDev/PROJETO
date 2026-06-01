class AddTerapiaGrupoToAgendamentos < ActiveRecord::Migration[8.1]
  def change
    add_column :agendamentos, :terapia_grupo, :boolean, default: false
  end
end
