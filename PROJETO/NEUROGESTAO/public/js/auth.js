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

function getNivelAcesso() {
    return localStorage.getItem('nivel_acesso') || 'profissional';
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
    const nivelAcesso = getNivelAcesso();
    const isNeurochat = (nivelAcesso === 'neurochat');

    // Páginas totalmente administrativas (bloqueadas para qualquer um que não seja gestor)
    const paginasAdminRestritas = [
        '/equipe',
        '/convenios_view',
        '/espera',
        '/transferencias'
    ];

    // Se não for gestor e tentar acessar páginas administrativas restritas, redireciona para a grade
    if (!isGestor && paginasAdminRestritas.some(p => path.includes(p))) {
        console.warn("Acesso negado: Redirecionando para Grade...");
        window.location.href = '/grade';
        return;
    }

    // Se for profissional comum (não gestor e não neurochat), não tem acesso a pacientes
    if (!isGestor && !isNeurochat && path.includes('/pacientes')) {
        console.warn("Acesso negado aos pacientes: Redirecionando para Grade...");
        window.location.href = '/grade';
        return;
    }

    // Ocultar links da sidebar que são administrativos
    const sidebar = document.querySelector('aside nav');
    if (sidebar) {
        const links = sidebar.querySelectorAll('a');
        links.forEach(link => {
            const href = link.getAttribute('href');
            
            // Ocultar equipe, convênios, transferências para quem não for gestor
            if (!isGestor && paginasAdminRestritas.some(p => href.includes(p))) {
                link.classList.add('hidden');
                link.style.display = 'none';
            }
            
            // Ocultar pacientes para profissionais comuns (não gestor e não neurochat)
            if (!isGestor && !isNeurochat && href.includes('/pacientes')) {
                link.classList.add('hidden');
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
        const nivelAcesso = localStorage.getItem('nivel_acesso') || 'profissional';

        config.headers['X-User-Role'] = role;
        config.headers['X-User-Id'] = userId;
        config.headers['X-User-Name'] = userName;
        config.headers['X-User-Access-Level'] = nivelAcesso;

        return originalFetch(resource, config);
    };
});
