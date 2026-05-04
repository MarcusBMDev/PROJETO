require "test_helper"

class PacienteTest < ActiveSupport::TestCase
  # Não usar fixtures globais — criamos objetos isolados em cada teste

  # ── Validações ─────────────────────────────────────────────────────────

  test "paciente válido com nome presente" do
    p = Paciente.new(nome: "Valido Test #{SecureRandom.hex(4)}")
    assert p.valid?
  end

  test "paciente inválido sem nome" do
    p = Paciente.new(nome: nil)
    assert_not p.valid?
    assert_predicate p.errors[:nome], :any?
  end

  test "weekly_frequency inválida se for zero" do
    p = Paciente.new(nome: "Freq Test #{SecureRandom.hex(4)}", weekly_frequency: 0)
    assert_not p.valid?
  end

  test "weekly_frequency inválida se for 8" do
    p = Paciente.new(nome: "Freq Test #{SecureRandom.hex(4)}", weekly_frequency: 8)
    assert_not p.valid?
  end

  test "weekly_frequency válida quando nil" do
    p = Paciente.new(nome: "Freq Nil #{SecureRandom.hex(4)}", weekly_frequency: nil)
    assert p.valid?
  end

  test "weekly_frequency válida no intervalo 1 a 7" do
    [1, 3, 7].each do |freq|
      p = Paciente.new(nome: "Freq #{freq} #{SecureRandom.hex(4)}", weekly_frequency: freq)
      assert p.valid?, "Deveria ser válido com weekly_frequency=#{freq}"
    end
  end

  test "age inválida se negativa" do
    p = Paciente.new(nome: "Age Test #{SecureRandom.hex(4)}", age: -1)
    assert_not p.valid?
  end

  test "age válida quando nil" do
    p = Paciente.new(nome: "Age Nil #{SecureRandom.hex(4)}", age: nil)
    assert p.valid?
  end

  # ── Soft Delete ────────────────────────────────────────────────────────

  test "soft_delete preenche deleted_at e muda status para inativo" do
    p = Paciente.create!(nome: "Soft Del #{SecureRandom.hex(4)}")
    assert_nil p.deleted_at
    assert_equal "ativo", p.status

    p.soft_delete
    assert_not_nil p.deleted_at
    assert_equal "inativo", p.status
  end

  test "reativar limpa deleted_at e muda status para ativo" do
    p = Paciente.create!(nome: "Reativar #{SecureRandom.hex(4)}")
    p.soft_delete
    p.reativar

    assert_nil p.reload.deleted_at
    assert_equal "ativo", p.status
  end

  test "ativo? retorna true quando deleted_at é nil" do
    p = Paciente.create!(nome: "Ativo #{SecureRandom.hex(4)}")
    assert p.ativo?
  end

  test "ativo? retorna false após soft_delete" do
    p = Paciente.create!(nome: "Inativo #{SecureRandom.hex(4)}")
    p.soft_delete
    assert_not p.ativo?
  end

  # ── Scopes ─────────────────────────────────────────────────────────────

  test "scope :ativos não inclui pacientes com soft_delete" do
    ativo = Paciente.create!(nome: "Ativo Scope #{SecureRandom.hex(4)}")
    inativo = Paciente.create!(nome: "Inativo Scope #{SecureRandom.hex(4)}")
    inativo.soft_delete

    ids_ativos = Paciente.ativos.pluck(:id)
    assert_includes ids_ativos, ativo.id
    assert_not_includes ids_ativos, inativo.id
  end

  test "scope :inativos retorna apenas pacientes com soft_delete" do
    p = Paciente.create!(nome: "Inativo Inat #{SecureRandom.hex(4)}")
    p.soft_delete

    ids_inativos = Paciente.inativos.pluck(:id)
    assert_includes ids_inativos, p.id
  end
end
