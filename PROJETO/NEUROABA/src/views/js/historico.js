// Verificação de Segurança (Igual às outras telas)
const usuarioLogadoTexto = localStorage.getItem('usuarioNeuroABA');
if (!usuarioLogadoTexto) { window.location.href = 'login.html'; }

window.sair = function() {
    localStorage.removeItem('usuarioNeuroABA');
    window.location.href = 'login.html';
};

// Função para buscar e montar a tabela
async function carregarHistorico() {
    const tabela = document.getElementById('tabelaHistorico');
    
    try {
        const resposta = await fetch('http://localhost:3012/api/historico');
        const sessoes = await resposta.json();

        if (sessoes.length === 0) {
            tabela.innerHTML = '<tr><td colspan="5" style="text-align: center;">Nenhuma sessão encontrada.</td></tr>';
            return;
        }

        tabela.innerHTML = ''; // Limpa o "Carregando"

        sessoes.forEach(sessao => {
            // Formata a data para o padrão Brasileiro
            const dataFormatada = new Date(sessao.data_sessao).toLocaleDateString('pt-BR');
            
            tabela.innerHTML += `
                <tr>
                    <td><strong>#${sessao.id}</strong></td>
                    <td>${dataFormatada}</td>
                    <td>${sessao.paciente_nome}</td>
                    <td>${sessao.terapeuta_nome}</td>
                    <td>
                        <button class="btn-editar" onclick="abrirEdicao(${sessao.id})">✏️ Corrigir</button>
                    </td>
                </tr>
            `;
        });

    } catch (erro) {
        tabela.innerHTML = '<tr><td colspan="5" style="color: red; text-align: center;">Erro ao carregar o histórico.</td></tr>';
    }
}

// Essa função será criada no próximo passo!
window.abrirEdicao = function(idSessao) {
    alert(`Em breve: Abrir a sessão #${idSessao} para edição e correção!`);
}

// Inicia a busca assim que a tela abre
carregarHistorico();