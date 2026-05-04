require "test_helper"

class ProfissionalTest < ActiveSupport::TestCase
  # Não usar fixtures globais — criamos objetos isolados em cada teste

  # ── Validações ─────────────────────────────────────────────────────────

  test "profissional válido com nome e especialidade" do
    p = Profissional.new(nome: "Dr. Valido #{SecureRandom.hex(4)}", especialidade: "Psicologia", ativo: true)
    assert p.valid?
  end

  test "profissional inválido sem nome" do
    p = Profissional.new(nome: nil, especialidade: "Psicologia", ativo: true)
    assert_not p.valid?
  end

  test "min_age e max_age nulos são válidos" do
    p = Profissional.new(nome: "Dr. Nil Age #{SecureRandom.hex(4)}", min_age: nil, max_age: nil, ativo: true)
    assert p.valid?
  end

  test "min_age negativa é inválida" do
    p = Profissional.new(nome: "Dr. Neg #{SecureRandom.hex(4)}", min_age: -1, ativo: true)
    assert_not p.valid?
  end

  test "max_age não pode ser menor que min_age" do
    p = Profissional.new(nome: "Dr. Invalid #{SecureRandom.hex(4)}", min_age: 10, max_age: 5, ativo: true)
    assert_not p.valid?
    assert_match(/não pode ser menor que a idade mínima/, p.errors[:max_age].first)
  end

  test "max_age igual a min_age é válido" do
    p = Profissional.new(nome: "Dr. Equal #{SecureRandom.hex(4)}", min_age: 10, max_age: 10, ativo: true)
    assert p.valid?
  end

  test "max_age maior que min_age é válido" do
    p = Profissional.new(nome: "Dr. Valid Range #{SecureRandom.hex(4)}", min_age: 5, max_age: 18, ativo: true)
    assert p.valid?
  end

  # ── Scopes ─────────────────────────────────────────────────────────────

  test "scope :ativos retorna apenas profissionais com ativo true" do
    ativo = Profissional.create!(nome: "Ativo #{SecureRandom.hex(4)}", especialidade: "Psicologia", ativo: true)
    inativo = Profissional.create!(nome: "Inativo #{SecureRandom.hex(4)}", especialidade: "Fonoaudiologia", ativo: false)

    ids_ativos = Profissional.ativos.pluck(:id)
    assert_includes ids_ativos, ativo.id
    assert_not_includes ids_ativos, inativo.id
  end

  test "scope :inativos retorna apenas profissionais com ativo false" do
    inativo = Profissional.create!(nome: "Inativo 2 #{SecureRandom.hex(4)}", especialidade: "TO", ativo: false)

    ids_inativos = Profissional.inativos.pluck(:id)
    assert_includes ids_inativos, inativo.id
  end

  # ── Método inativar! ────────────────────────────────────────────────────

  test "inativar! muda ativo para false" do
    p = Profissional.create!(nome: "Dr. Inativar #{SecureRandom.hex(4)}", especialidade: "Psicologia", ativo: true)
    assert p.ativo

    p.inativar!
    assert_not p.reload.ativo
  end
end
