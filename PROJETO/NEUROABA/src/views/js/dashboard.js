let graficoAtivo = null; // Agora temos apenas um gráfico principal

async function carregarPacientes() {
    const resposta = await fetch('http://localhost:3012/api/dados-iniciais');
    const dados = await resposta.json();
    const select = document.getElementById('pacienteSelect');
    select.innerHTML = '<option value="">Selecione um paciente...</option>';
    dados.pacientes.forEach(pac => {
        select.innerHTML += `<option value="${pac.id}">${pac.nome}</option>`;
    });
}

document.getElementById('pacienteSelect').addEventListener('change', async function(evento) {
    const pacienteId = evento.target.value;
    const msgStatus = document.getElementById('mensagemStatus');
    const areaGrafico = document.getElementById('areaGrafico');
    
    if(!pacienteId) {
        msgStatus.style.display = 'block';
        areaGrafico.style.display = 'none';
        return;
    }

    msgStatus.style.display = 'block';
    msgStatus.innerText = 'Processando dados da Curva de Aprendizagem...';
    areaGrafico.style.display = 'none';

    try {
        const resposta = await fetch(`http://localhost:3012/api/relatorios/${pacienteId}`);
        const dadosBrutos = await resposta.json();

        if(dadosBrutos.length === 0) {
            msgStatus.innerText = 'Nenhuma sessão cadastrada para este paciente ainda.';
            return;
        }

        msgStatus.style.display = 'none';
        areaGrafico.style.display = 'block';
        
        gerarGraficoLinhas(dadosBrutos);
    } catch (erro) {
        msgStatus.innerText = 'Erro ao buscar dados no servidor.';
    }
});

function gerarGraficoLinhas(dados) {
    if (graficoAtivo) {
        graficoAtivo.destroy(); // Limpa o gráfico anterior se trocar de paciente
    }

    // 1. Coleta todas as datas únicas e agrupa os dados por Categoria
    const dadosPorCategoria = {};
    const conjuntoDeDatas = new Set();

    dados.forEach(linha => {
        const dataFormatada = new Date(linha.data_sessao).toLocaleDateString('pt-BR');
        conjuntoDeDatas.add(dataFormatada);
        
        // Remove os números do início (Ex: "1 - Motricidade" vira só "Motricidade")
        const categoriaLimpa = linha.categoria.replace(/^\d+\s*-\s*/, '');

        if (!dadosPorCategoria[categoriaLimpa]) { dadosPorCategoria[categoriaLimpa] = {}; }
        if (!dadosPorCategoria[categoriaLimpa][dataFormatada]) { dadosPorCategoria[categoriaLimpa][dataFormatada] = { pontuacao: 0, total: 0 }; }

        [linha.tentativa_1, linha.tentativa_2, linha.tentativa_3].forEach(tentativa => {
            if(tentativa) {
                dadosPorCategoria[categoriaLimpa][dataFormatada].total += 1;
                if(tentativa.includes("Independente")) dadosPorCategoria[categoriaLimpa][dataFormatada].pontuacao += 1;
                else if(tentativa.includes("Dica")) dadosPorCategoria[categoriaLimpa][dataFormatada].pontuacao += 0.5;
            }
        });
    });

    // 2. Ordena as datas para a linha do tempo não ficar bagunçada
    const datasOrdenadas = Array.from(conjuntoDeDatas).sort((a, b) => {
        const [d1, m1, a1] = a.split('/');
        const [d2, m2, a2] = b.split('/');
        return new Date(a1, m1-1, d1) - new Date(a2, m2-1, d2);
    });

    // 3. Prepara as Linhas (Datasets)
    const paletaCores = ['#2563eb', '#10b981', '#ef4444', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4'];
    
    const linhasDoGrafico = Object.keys(dadosPorCategoria).map((categoria, index) => {
        const pontosY = datasOrdenadas.map(data => {
            const info = dadosPorCategoria[categoria][data];
            // Se não fez a atividade naquele dia, retorna 'null' para a linha pular o dia
            if (!info || info.total === 0) return null; 
            return Math.round((info.pontuacao / info.total) * 100);
        });

        return {
            label: categoria, // O nome vai aparecer na Legenda Lateral
            data: pontosY,
            borderColor: paletaCores[index % paletaCores.length],
            backgroundColor: paletaCores[index % paletaCores.length],
            borderWidth: 3,
            tension: 0.3, // Curva suave
            spanGaps: true, // Conecta os pontos mesmo se pular um dia
            pointRadius: 5,
            pointHoverRadius: 8
        };
    });

    // 4. Desenha o Gráfico Final com Legenda Lateral
    const ctx = document.getElementById('graficoCurva').getContext('2d');
    graficoAtivo = new Chart(ctx, {
        type: 'line',
        data: {
            labels: datasOrdenadas, // Eixo X
            datasets: linhasDoGrafico // Eixo Y
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'right', // <-- AQUI É A MÁGICA DA LEGENDA LATERAL
                    align: 'start',
                    labels: {
                        font: { size: 13, family: 'Inter' },
                        usePointStyle: true,
                        boxWidth: 8
                    }
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return ` ${context.dataset.label}: ${context.parsed.y}% de Acerto`;
                        }
                    }
                }
            },
            scales: {
                y: { 
                    min: 0, 
                    max: 100,
                    title: { display: true, text: 'Taxa de Sucesso (%)', font: { weight: 'bold' } }
                },
                x: {
                    title: { display: true, text: 'Datas das Sessões', font: { weight: 'bold' } }
                }
            }
        }
    });
}

carregarPacientes();