// 1. VERIFICAÇÃO DE SEGURANÇA
const usuarioLogadoTexto = localStorage.getItem('usuarioNeuroABA');
if (!usuarioLogadoTexto) { window.location.href = 'login.html'; }

const terapeuta = JSON.parse(usuarioLogadoTexto);
document.getElementById('nomeTerapeuta').innerText = `Olá, ${terapeuta.username}`;

window.sair = function() {
    localStorage.removeItem('usuarioNeuroABA');
    window.location.href = 'login.html';
};

// 2. BUSCA DE PACIENTES NO BANCO
async function carregarPacientes() {
    try {
        const resposta = await fetch('http://localhost:3012/api/dados-iniciais');
        const dados = await resposta.json();
        const selectPaciente = document.getElementById('paciente');
        selectPaciente.innerHTML = '<option value="">Selecione o paciente...</option>';
        dados.pacientes.forEach(pac => {
            selectPaciente.innerHTML += `<option value="${pac.id}">${pac.nome}</option>`;
        });
        document.getElementById('dataSessao').valueAsDate = new Date();
    } catch (erro) {
        console.error("Erro ao buscar pacientes:", erro);
    }
}

// 3. ESTRUTURA DOS DADOS (Baseado nos seus prints)
const categoriasAtividades = [
    "1 - Atividades de Motricidade Fina",
    "2 - Contar Até 20",
    "3 - Identificar vogais minúscula",
    "4 - Regulação Emocional",
    "5 - Responder perguntas com o 'O que'",
    "6 - Nomear Categoria",
    "7 - Noção Temporal - Nomear Manhã, Tarde e Noite"
];

const opcoesTentativa = `
    <option value="">Selecione...</option>
    <option value="Acerto Independente" style="background-color: #d1fae5; color: #065f46; font-weight: bold;">Acerto Independente</option>
    <option value="Acerto Após Dica" style="background-color: #fef08a; color: #854d0e;">Acerto Após Dica</option>
    <option value="Erro Após dicas" style="background-color: #fecdd3; color: #9f1239;">Erro Após dicas</option>
    <option value="Acerto Após Correção" style="background-color: #fed7aa; color: #9a3412;">Acerto Após Correção</option>
    <option value="Erro Após Correção" style="background-color: #ef4444; color: white;">Erro Após Correção</option>
    <option value="Ausência de Resposta" style="background-color: #e9d5ff; color: #581c87;">Ausência de Resposta</option>
`;

const opcoesDica = `
    <option value="">Selecione...</option>
    <option value="Física Total">Física Total</option>
    <option value="Física Parcial">Física Parcial</option>
    <option value="Modelação Completa">Modelação Completa</option>
    <option value="Modelação Parcial">Modelação Parcial</option>
    <option value="Gestual">Gestual</option>
    <option value="Verbal">Verbal</option>
    <option value="Visual">Visual</option>
`;

// 4. GERADOR DINÂMICO DAS TABELAS
const areaTabelas = document.getElementById('areaTabelasDinamicas');
let htmlFinal = "";

// Para cada uma das 7 categorias, criamos uma tabela
categoriasAtividades.forEach((atividade, indexCat) => {
    htmlFinal += `
        <div class="sessao-atividade">
            <h3 class="titulo-atividade">${atividade}</h3>
            <div class="tabela-wrapper">
                <table>
                    <thead>
                        <tr>
                            <th width="20%">Estímulos</th>
                            <th>Tentativa 01</th>
                            <th>Tipo de Dica</th>
                            <th>Tentativa 02</th>
                            <th>Tipo de Dica</th>
                            <th>Tentativa 03</th>
                            <th>Tipo de Dica</th>
                        </tr>
                    </thead>
                    <tbody>
    `;

    // Para cada atividade, geramos 4 linhas de estímulos
    for (let i = 1; i <= 4; i++) {
        // Criamos IDs únicos (ex: est_0_1, t1_0_1, dica1_0_1) para capturar depois
        htmlFinal += `
            <tr>
                <td><input type="text" id="est_${indexCat}_${i}" placeholder="Descreva o Estímulo ${i}"></td>
                
                <td><select id="t1_${indexCat}_${i}">${opcoesTentativa}</select></td>
                <td><select id="dica1_${indexCat}_${i}">${opcoesDica}</select></td>
                
                <td><select id="t2_${indexCat}_${i}">${opcoesTentativa}</select></td>
                <td><select id="dica2_${indexCat}_${i}">${opcoesDica}</select></td>
                
                <td><select id="t3_${indexCat}_${i}">${opcoesTentativa}</select></td>
                <td><select id="dica3_${indexCat}_${i}">${opcoesDica}</select></td>
            </tr>
        `;
    }

    htmlFinal += `</tbody></table></div></div>`;
});

// Injeta todo o código gerado de uma vez na tela
areaTabelas.innerHTML = htmlFinal;


// 5. PREPARAÇÃO DOS DADOS PARA SALVAR (O Envio será ajustado depois)
// 5. ENVIAR DADOS PARA SALVAR
document.getElementById('formSessao').addEventListener('submit', async function(evento) {
    evento.preventDefault();
    
    const listaEstimulos = [];
    
    // O sistema varre (faz um loop) por todas as 7 categorias e seus 4 estímulos
    categoriasAtividades.forEach((atividade, indexCat) => {
        for (let i = 1; i <= 4; i++) {
            const nomeEst = document.getElementById(`est_${indexCat}_${i}`).value;
            
            // Só guarda no "pacote" se o terapeuta realmente digitou um estímulo
            if (nomeEst.trim() !== "") {
                listaEstimulos.push({
                    categoria: atividade,
                    numero: i,
                    nome: nomeEst,
                    t1: document.getElementById(`t1_${indexCat}_${i}`).value,
                    dica1: document.getElementById(`dica1_${indexCat}_${i}`).value,
                    t2: document.getElementById(`t2_${indexCat}_${i}`).value,
                    dica2: document.getElementById(`dica2_${indexCat}_${i}`).value,
                    t3: document.getElementById(`t3_${indexCat}_${i}`).value,
                    dica3: document.getElementById(`dica3_${indexCat}_${i}`).value
                });
            }
        }
    });

    // Trava de segurança: impede de salvar se estiver tudo em branco
    if(listaEstimulos.length === 0) {
        alert("Por favor, preencha pelo menos um estímulo para poder salvar a sessão!");
        return;
    }

    const dadosSessao = {
        paciente_id: document.getElementById('paciente').value,
        terapeuta_id: terapeuta.id,
        data_sessao: document.getElementById('dataSessao').value,
        relatorio_diario: document.getElementById('relatorio').value,
        estimulos: listaEstimulos
    };

    try {
        const resposta = await fetch('http://localhost:3012/api/salvar-sessao', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(dadosSessao)
        });

        if (resposta.ok) {
            alert("Sessão salva com sucesso no Banco de Dados!");
            window.location.reload(); // Recarrega a página para limpar o formulário para o próximo paciente
        } else {
            alert("Erro ao salvar. Verifique o servidor.");
        }
    } catch (erro) {
        alert("Falha na comunicação com o servidor.");
    }
});

carregarPacientes();