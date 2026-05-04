document.getElementById('formLogin').addEventListener('submit', async function(evento) {
    evento.preventDefault(); // Evita recarregar a página
    
    const usernameDigitado = document.getElementById('username').value;
    const passwordDigitada = document.getElementById('password').value;
    const mensagemErro = document.getElementById('mensagemErro');

    try {
        // Envia os dados para a nossa API
        const resposta = await fetch('http://localhost:3012/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ 
                username: usernameDigitado, 
                password: passwordDigitada 
            })
        });

        const dados = await resposta.json();

        if (resposta.ok) {
            // Login deu certo
            alert(`Bem-vindo, ${dados.usuario.username}! Setor: ${dados.usuario.department}`);
            localStorage.setItem('usuarioNeuroABA', JSON.stringify(dados.usuario));
            window.location.href = 'index.html'; // Redireciona para o painel
        } else {
            // Erro de login
            mensagemErro.style.display = 'block';
            mensagemErro.innerText = dados.erro;
        }
    } catch (erro) {
        alert("Erro ao conectar com o servidor. Verifique se o Node.js está rodando.");
    }
});