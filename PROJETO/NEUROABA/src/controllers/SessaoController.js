// Importamos nossas conexões de banco de dados
const { dbPrincipal, dbPacientes, dbUsuarios } = require('../config/database');

const SessaoController = {
    // 1. Função que o Frontend vai chamar para preencher as "caixinhas de seleção"
    async listarDadosIniciais(req, res) {
        try {
            // Puxa todos os pacientes e terapeutas ativos
            const [pacientes] = await dbPacientes.query('SELECT id, nome FROM pacientes');
            const [terapeutas] = await dbUsuarios.query('SELECT id, username FROM users');
            
            // Envia para a tela
            res.json({ pacientes, terapeutas });
        } catch (erro) {
            console.error(erro);
            res.status(500).json({ erro: "Erro ao buscar pacientes e terapeutas." });
        }
    },

    // 2. Função para salvar o relatório completo
    async salvarSessao(req, res) {
        // Recebe os dados enviados pelo botão "Salvar" lá na tela
        const { paciente_id, terapeuta_id, data_sessao, relatorio_diario, estimulos } = req.body;

        // Pega uma conexão dedicada para fazer a Transação (Garantia de segurança)
        const conexao = await dbPrincipal.getConnection();

        try {
            await conexao.beginTransaction(); // Inicia a gravação segura

            // Passo A: Salva o cabeçalho da Sessão
            const [resultadoSessao] = await conexao.query(
                'INSERT INTO sessoes (paciente_id, terapeuta_id, data_sessao, relatorio_diario) VALUES (?, ?, ?, ?)',
                [paciente_id, terapeuta_id, data_sessao, relatorio_diario]
            );

            // Descobre qual foi o ID (número) da sessão que acabou de ser criada
            const sessaoId = resultadoSessao.insertId;

            // Passo B: Salva cada um dos 5 estímulos vinculados a essa sessão
            for (let i = 0; i < estimulos.length; i++) {
                const est = estimulos[i];
                await conexao.query(
                    'INSERT INTO respostas_estimulos (sessao_id, categoria, numero_estimulo, nome_estimulo, tentativa_1, dica_1, tentativa_2, dica_2, tentativa_3, dica_3) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                    [sessaoId, est.categoria, est.numero, est.nome, est.t1, est.dica1, est.t2, est.dica2, est.t3, est.dica3]
                );
            }

            await conexao.commit(); // Confirma que tudo deu certo e salva de vez!
            res.status(201).json({ mensagem: 'Sessão salva com sucesso!', idSessao: sessaoId });

        } catch (erro) {
            await conexao.rollback(); // Se deu qualquer erro no meio do caminho, desfaz tudo!
            console.error("Erro ao salvar a sessão:", erro);
            res.status(500).json({ erro: 'Erro ao salvar a sessão. Tente novamente.' });
        } finally {
            conexao.release(); // Libera a conexão para o próximo terapeuta usar
        }
    },


    // 3. Função para buscar os dados do Dashboard
    async buscarRelatorioPaciente(req, res) {
        const { paciente_id } = req.params;

        try {
            // Fazemos um JOIN: Junta o cabeçalho da sessão com os estímulos respondidos
            const [dados] = await dbPrincipal.query(`
                SELECT s.data_sessao, r.categoria, r.tentativa_1, r.tentativa_2, r.tentativa_3
                FROM sessoes s
                JOIN respostas_estimulos r ON s.id = r.sessao_id
                WHERE s.paciente_id = ?
                ORDER BY s.data_sessao ASC
            `, [paciente_id]);

            res.json(dados);
        } catch (erro) {
            console.error("Erro ao gerar relatório:", erro);
            res.status(500).json({ erro: "Erro ao buscar dados do paciente." });
        }
    },

    // 4. Função para listar o Histórico de Sessões
    async listarHistorico(req, res) {
        try {
            // Como todos os bancos estão no mesmo servidor, podemos buscar dados deles 
            // usando a sintaxe banco.tabela
            const [sessoes] = await dbPrincipal.query(`
                SELECT 
                    s.id, 
                    s.data_sessao, 
                    p.nome AS paciente_nome, 
                    t.username AS terapeuta_nome
                FROM neuroaba_db.sessoes s
                JOIN agendamentos_clinica_dev.pacientes p ON s.paciente_id = p.id
                JOIN neurochat_db.users t ON s.terapeuta_id = t.id
                ORDER BY s.data_sessao DESC
                LIMIT 100
            `);

            res.json(sessoes);
        } catch (erro) {
            console.error("Erro ao buscar histórico:", erro);
            res.status(500).json({ erro: "Erro ao buscar o histórico de sessões." });
        }
    }
};
module.exports = SessaoController;
