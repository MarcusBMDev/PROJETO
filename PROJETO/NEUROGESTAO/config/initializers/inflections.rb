ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.plural(/^([\w ]*)al$/i, '\1ais')
  inflect.singular(/^([\w ]*)ais$/i, '\1al')
  inflect.plural(/^([\w ]*)ao$/i, '\1oes')
  inflect.singular(/^([\w ]*)oes$/i, '\1ao')
  inflect.irregular 'convenio', 'convenios'
  inflect.irregular 'agendamento', 'agendamentos'
  inflect.irregular 'paciente', 'pacientes'
  inflect.irregular 'transferencia', 'transferencias'
end