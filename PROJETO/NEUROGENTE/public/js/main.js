/**
 * Função para alternar entre as Abas Principais
 */
function openTab(evt, tabName) {
    // 1. Esconde todo o conteúdo de abas principais
    const tabContents = document.getElementsByClassName("tab-content");
    for (let i = 0; i < tabContents.length; i++) {
        tabContents[i].style.display = "none";
        tabContents[i].classList.remove('active');
    }

    // 2. Remove a classe 'active' de todos os botões do menu principal
    const tabLinks = document.getElementsByClassName("tab-link");
    for (let i = 0; i < tabLinks.length; i++) {
        tabLinks[i].classList.remove("active");
    }

    // 3. Mostra a aba clicada e marca o botão como ativo
    const activeTab = document.getElementById(tabName);
    if (activeTab) {
        activeTab.style.display = "block";
        activeTab.classList.add('active');
        
        if (evt && evt.currentTarget) {
            evt.currentTarget.classList.add("active");
        }
    }
}

/**
 * Função para alternar entre as Sub-Abas internas
 */
function openSubTab(evt, parentId, subTabId) {
    const parentContainer = document.getElementById(parentId);
    if (!parentContainer) return;

    // 1. Esconde os conteúdos de sub-abas dentro deste container
    const subContents = parentContainer.getElementsByClassName("sub-tab-content");
    for (let i = 0; i < subContents.length; i++) {
        subContents[i].style.display = "none";
    }

    // 2. Remove active dos botões de sub-aba dentro deste container
    const subLinks = parentContainer.getElementsByClassName("sub-tab-link");
    for (let i = 0; i < subLinks.length; i++) {
        subLinks[i].classList.remove("active");
    }

    // 3. Mostra a sub-aba selecionada
    const activeSub = document.getElementById(subTabId);
    if (activeSub) {
        activeSub.style.display = "block";
        if (evt && evt.currentTarget) {
            evt.currentTarget.classList.add("active");
        }
    }
}

/**
 * Executa quando a página termina de carregar
 */
document.addEventListener('DOMContentLoaded', () => {
    if(window.location.hash === '#restrito') {
        const btnRestrito = document.querySelector('button[onclick*="restrito"]');
        if(btnRestrito) {
            openTab({ currentTarget: btnRestrito }, 'restrito');
        }
    }
});