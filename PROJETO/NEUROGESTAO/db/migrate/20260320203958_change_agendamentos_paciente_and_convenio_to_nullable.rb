class ChangeAgendamentosPacienteAndConvenioToNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :agendamentos, :paciente_id, true
    change_column_null :agendamentos, :convenio_id, true
  end
end
