/**
 * Neuro Gestão - Auth Helper
 * Centraliza a lógica de permissões e redirecionamentos
 */

const SETORES_GESTAO = [
    'agendamento', 
    'diretoria', 
    'coordenação', 
    'coordenacao',
    'recepção 1', 'recepçao 1', 'recepcao 1',
    'recepção 2', 'recepçao 2', 'recepcao 2',
    'recepção 3', 'recepçao 3', 'recepcao 3',
    'ti'
];

function getUserRole() {
    let role = (localStorage.getItem('setor') || localStorage.getItem('role') || localStorage.getItem('department') || '').toLowerCase().trim();
    // Remove acentos para comparação mais segura
    return role.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function isSuperAdmin() {
    const val = localStorage.getItem('is_super_admin') || localStorage.getItem('isSuperAdmin') || localStorage.getItem('isAdmin');
    return val === '1' || val === 'true' || val === true;
}

function leadsGestao() {
    const role = getUserRole();
    const isAdmin = isSuperAdmin();
    const setoresNormalizados = SETORES_GESTAO.map(s => s.normalize("NFD").replace(/[\u0300-\u036f]/g, ""));
    
    // Agora permite que o setor esteja contido na string (ex: "diretoria" em "diretoria geral")
    const permitido = isAdmin || role === 'ti' || setoresNormalizados.some(s => role.includes(s));
    
    console.log("NeuroGestao Auth Check:", { role, isAdmin, permitido });
    
    return permitido;
}

function aplicarRestricoesNavegacao() {
    const path = window.location.pathname;
    const isGestor = leadsGestao();

    // Páginas Administrativas
    const paginasAdmin = [
        '/equipe',
        '/pacientes',
        '/convenios_view',
        '/espera',
        '/transferencias'
    ];

    // Se estiver em uma página admin e não for gestor, redireciona para a grade
    if (!isGestor && paginasAdmin.some(p => path.includes(p))) {
        console.warn("Acesso negado: Redirecionando para Grade...");
        window.location.href = '/grade';
        return;
    }

    // Ocultar links da sidebar que são administrativos
    const sidebar = document.querySelector('aside nav');
    if (sidebar && !isGestor) {
        const links = sidebar.querySelectorAll('a');
        links.forEach(link => {
            const href = link.getAttribute('href');
            if (paginasAdmin.some(p => href.includes(p))) {
                link.classList.add('hidden'); // Oculta o link
                link.style.display = 'none';
            }
        });
    }
}

// Executa ao carregar o script
document.addEventListener('DOMContentLoaded', () => {
    aplicarRestricoesNavegacao();
    
    // Interceptar requisições Fetch para incluir os headers de Role e UserName
    const originalFetch = window.fetch;
    window.fetch = function() {
        let [resource, config] = arguments;
        if (!config) config = {};
        if (!config.headers) config.headers = {};

        const role = localStorage.getItem('setor') || 'Desconhecido';
        const userId = localStorage.getItem('userId') || '';
        const userName = localStorage.getItem('userName') || '';

        config.headers['X-User-Role'] = role;
        config.headers['X-User-Id'] = userId;
        config.headers['X-User-Name'] = userName;

        return originalFetch(resource, config);
    };
});
