const fs = require('fs');
const path = require('path');

const content = `const RhModel = require('../models/RhModel');
const NotificacaoUtils = require('../utils/notificacoes');
const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');
const fs = require('fs').promises;
const path = require('path');

const TARGET_RH_IDS = [79, 95];

const SolicitacaoController = {
    
    enviarNotificacoesRh: (usuarioId, titulo, resumo) => {
        const msgContent = "🧠 *NOVA SOLICITAÇÃO RH*\\n📌 *Tipo:* " + titulo + "\\n👤 *Por:* " + resumo;
        NotificacaoUtils.enviarMensagem(usuarioId, TARGET_RH_IDS, msgContent);
        const msgUser = "✅ *SOLICITAÇÃO RECEBIDA*\\nOlá! Sua solicitação de *" + titulo + "* foi enviada com sucesso para análise do RH.";
        NotificacaoUtils.enviarMensagem(79, usuarioId, msgUser);
    },

    enviarNotificacaoAbaGroup: (usuarioId, titulo, resumo) => {
        const msgAba = "🧩 *NOTIFICAÇÃO COORDENAÇÃO ABA*\\n📌 *Evento:* " + titulo + "\\n📋 *Detalhes:* " + resumo;
        NotificacaoUtils.enviarMensagemGrupo(usuarioId, 3, msgAba);
    },

    gerarDocumentoSolicitacao: async (tipo, usuarioNome, dados) => {
        try {
            const bases = {
                'dayoff': 'politica_dayoff.pdf',
                'formacao': 'politica_formacao.pdf',
                'saude': 'politica_saude.pdf'
            };
            const arquivoBase = bases[tipo];
            if (!arquivoBase) return null;

            const caminhoBase = path.join(__dirname, '../../public/uploads', arquivoBase);
            const dataBase = await fs.readFile(caminhoBase);

            const pdfDoc = await PDFDocument.load(dataBase);
            const pages = pdfDoc.getPages();
            
            const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
            const fontBold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);
            
            // GARANTIA: NÃO ADICIONAR PÁGINAS. Preencher a página existente.
            let targetPage;
            if (tipo === 'dayoff' && pages.length >= 3) {
                targetPage = pages[2]; // Página 3
            } else {
                targetPage = pages[pages.length - 1]; // Última página
            }

            if (tipo === 'dayoff') {
                targetPage.drawText(usuarioNome, { x: 74, y: 730, size: 10, font: font });
                targetPage.drawText(dados['Cargo'] || '', { x: 260, y: 730, size: 10, font: font });
                targetPage.drawText(dados['CPF'] || '', { x: 440, y: 730, size: 10, font: font });
                targetPage.drawText(dados['Data do Evento'] || '', { x: 505, y: 698, size: 10, font: font });
                const hoje = new Date().toLocaleDateString('pt-BR');
                targetPage.drawText(hoje, { x: 95, y: 588, size: 11, font: font });
                targetPage.drawText(usuarioNome, { x: 250, y: 520, size: 10, font: font });
            } else {
                targetPage.drawText(usuarioNome, { x: 74, y: 730, size: 10, font: font });
                targetPage.drawText(new Date().toLocaleDateString('pt-BR'), { x: 95, y: 588, size: 11, font: font });
            }

            const pdfBytes = await pdfDoc.save();
            const nomeArquivo = "solicitacao_" + tipo + "_" + Date.now() + ".pdf";
            const caminhoFinal = path.join(__dirname, '../../public/uploads', nomeArquivo);
            
            await fs.writeFile(caminhoFinal, pdfBytes);
            return '/uploads/' + nomeArquivo;

        } catch (error) {
            console.error("Erro ao gerar PDF:", error);
            return null;
        }
    },

    salvarDayOff: async (req, res) => {
        try {
            const detalhes = "DAY OFF - " + req.session.user.username;
            const dadosSolicitacao = {
                usuario_id: req.session.user.id,
                tipo: 'dayoff',
                data_evento: req.body.data_aniversario,
                descricao: detalhes
            };
            const pdfPath = await SolicitacaoController.gerarDocumentoSolicitacao('dayoff', req.session.user.username, {
                'Cargo': req.body.cargo,
                'CPF': req.body.cpf,
                'Data do Evento': req.body.data_aniversario
            });
            dadosSolicitacao.caminho_anexo = pdfPath;
            RhModel.criarSolicitacao(dadosSolicitacao, (err) => {
                if (err) return res.redirect('/?erro=Erro.');
                SolicitacaoController.enviarNotificacoesRh(req.session.user.id, "DAY OFF", req.session.user.username);
                res.redirect('/?msg=Day Off solicitado!');
            });
        } catch (error) { res.redirect('/?erro=Erro.'); }
    },

    salvarFormacao: async (req, res) => {
        try {
            const dadosSolicitacao = { usuario_id: req.session.user.id, tipo: 'formacao', data_evento: req.body.data_inicio, descricao: 'CURSO' };
            const pdfPath = await SolicitacaoController.gerarDocumentoSolicitacao('formacao', req.session.user.username, { 'Curso': req.body.nome_curso });
            dadosSolicitacao.caminho_anexo = pdfPath;
            RhModel.criarSolicitacao(dadosSolicitacao, (err) => {
                SolicitacaoController.enviarNotificacoesRh(req.session.user.id, "FORMAÇÃO", req.body.nome_curso);
                res.redirect('/?msg=Enviado!');
            });
        } catch (error) { res.redirect('/?erro=Erro.'); }
    },

    salvarBeneficio: async (req, res) => {
        try {
            const dadosSolicitacao = { usuario_id: req.session.user.id, tipo: 'saude', data_evento: null, descricao: 'SAÚDE' };
            const pdfPath = await SolicitacaoController.gerarDocumentoSolicitacao('saude', req.session.user.username, { 'Beneficiário': req.body.nome_beneficiario });
            dadosSolicitacao.caminho_anexo = pdfPath;
            RhModel.criarSolicitacao(dadosSolicitacao, (err) => {
                SolicitacaoController.enviarNotificacoesRh(req.session.user.id, "SAÚDE", req.body.nome_beneficiario);
                res.redirect('/?msg=Enviado!');
            });
        } catch (error) { res.redirect('/?erro=Erro.'); }
    },

    salvarDesligamentoAT: (req, res) => {
        const dados = { usuario_id: req.session.user.id, tipo: 'desligamento_at', data_evento: req.body.data_solicitacao, descricao: 'Desligamento' };
        RhModel.criarSolicitacao(dados, (err) => {
            SolicitacaoController.enviarNotificacoesRh(req.session.user.id, "ABA: DESLIGAMENTO", req.body.nome_at);
            res.redirect('/?msg=Enviado!');
        });
    },

    salvarContratacaoAT: (req, res) => {
        const dados = { usuario_id: req.session.user.id, tipo: 'contratacao_at', data_evento: req.body.data_solicitacao, descricao: 'Contratação' };
        RhModel.criarSolicitacao(dados, (err) => {
            SolicitacaoController.enviarNotificacoesRh(req.session.user.id, "ABA: CONTRATAÇÃO", req.body.nome_paciente);
            res.redirect('/?msg=Enviado!');
        });
    },

    salvarAtestado: (req, res) => {
        if (!req.file) return res.redirect('/?erro=Anexe arquivo.');
        const dados = { usuario_id: req.session.user.id, data_inicio: req.body.data_inicio, detalhes: 'Atestado', caminho: '/uploads/' + req.file.filename };
        RhModel.salvarAtestado(dados, (err) => {
            SolicitacaoController.enviarNotificacoesRh(req.session.user.id, "ATESTADO MÉDICO", req.session.user.username);
            res.redirect('/?msg=Enviado!');
        });
    }
};

module.exports = SolicitacaoController;
\`;

fs.writeFileSync(path.join(__dirname, 'src/controllers/SolicitacaoController.js'), content, 'utf8');
console.log('File written successfully');
`;
