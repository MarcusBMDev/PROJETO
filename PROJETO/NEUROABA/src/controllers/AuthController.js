// Importamos APENAS a conexão do banco de usuários (Neurochat)
const { dbUsuarios } = require('../config/database');

const AuthController = {
    async login(req, res) {
        // Recebe o que o usuário digitou na tela
        const { username, password } = req.body;

        try {
            // Busca no banco neurochat_db se existe alguém com esse nome e senha
            // O '?' protege contra ataques de SQL Injection
            const [usuarios] = await dbUsuarios.query(
                'SELECT id, username, department FROM users WHERE username = ? AND password = ?',
                [username, password]
            );

            // O banco sempre retorna um array (lista). Se tiver alguém, o tamanho é maior que 0.
            if (usuarios.length > 0) {
                const usuarioLogado = usuarios[0]; // Pega o primeiro (e único) usuário encontrado
                
                res.status(200).json({ 
                    mensagem: "Login aprovado!", 
                    usuario: usuarioLogado 
                });
            } else {
                // Erro 401 significa "Não Autorizado"
                res.status(401).json({ erro: "Usuário ou senha incorretos." });
            }

        } catch (erro) {
            console.error("Erro ao tentar fazer login:", erro);
            res.status(500).json({ erro: "Erro interno no servidor ao validar o login." });
        }
    }
};

module.exports = AuthController;