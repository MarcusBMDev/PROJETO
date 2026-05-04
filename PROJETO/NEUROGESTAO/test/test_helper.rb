ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Paralelismo desabilitado: projetos com múltiplos bancos (primary + neurochat)
    # têm conflito de fixtures ao usar :threads. Usar 1 worker garante isolamento correto.
    parallelize(workers: 1)

    # Cada teste roda dentro de uma transação que é revertida ao final.
    # Isso não depende de fixtures globais, evitando 'Duplicate Entry' por FK conflicts.
    self.use_transactional_tests = true

    # OBS: Não usamos 'fixtures :all' para evitar conflito de IDs em tabelas com FKs.
    # Cada teste cria seus próprios objetos com dados únicos (SecureRandom.hex).
  end
end
