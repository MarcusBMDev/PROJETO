// public/js/admin.js

const userData = JSON.parse(localStorage.getItem('neuroUser'));
if (!userData || !userData.isAdmin) window.location.href = 'index.html';

// Configura o nome do admin no topo
document.addEventListener("DOMContentLoaded", () => {
    document.getElementById('adminName').innerText = `Gestor Especialista: ${userData.username}`;
    carregarTudo();
    setInterval(carregarTudo, 30000); // Atualiza a cada 30 segundos
});

function logout() { 
    localStorage.removeItem('neuroUser'); 
    window.location.href = 'login.html'; 
}

let currentTab = 'todos';
let currentPage = 1;
let chart1, chart2;

async function mudarTab(status) {
    currentTab = status;
    document.querySelectorAll('.tab-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.status === status);
    });
    carregarTudo();
}

async function carregarTudo() {
    carregarPedidos(1);
    carregarGraficos();
}

async function carregarPedidos(page = 1) {
    currentPage = page;
    const start = document.getElementById('filterStartDate').value;
    const end = document.getElementById('filterEndDate').value;
    
    const params = new URLSearchParams({ 
        status: currentTab, 
        start_date: start, 
        end_date: end,
        page: page,
        limit: 50,
        t: Date.now()
    });

    try {
        const res = await fetch(`/api/print/jobs?${params}`, { 
            headers: { 'user-id': userData.id, 'Cache-Control': 'no-cache' } 
        });
        const response = await res.json();
        
        const lista = response.data || response;
        const pagination = response.pagination || null;

        const tbody = document.getElementById('tabelaPedidos');
        tbody.innerHTML = '';

        if (!lista || lista.length === 0) {
            tbody.innerHTML = `<tr><td colspan="7" style="text-align:center; padding:30px; color:#999; font-style:italic;">Nenhuma solicitação encontrada para o status <b>${currentTab}</b>.</td></tr>`;
            document.getElementById('paginationContainer').innerHTML = '';
            return;
        }

        lista.forEach(job => {
            const tr = document.createElement('tr');
            if (job.is_urgent) tr.classList.add('urgent-row');

            const nomes = job.file_name.split(';');
            const caminhos = job.file_path.split(';');
            let htmlArquivos = '';
            nomes.forEach((nome, index) => {
                let pathRaw = caminhos[index] || '';
                let cleanFilename = pathRaw.includes('\\') ? pathRaw.split('\\').pop() : pathRaw;
                htmlArquivos += `<a href="/files/${cleanFilename}" target="_blank" style="display:block; text-decoration:none; color:var(--primary); font-weight:500; margin-bottom:4px; font-size:0.8rem;">
                    <i class="fa-solid fa-file-pdf"></i> ${nome.trim()}
                </a>`;
            });

            const dataCriacao = new Date(job.created_at).toLocaleDateString('pt-BR');
            let prazoHtml = `<span class="info-sub"><i class="fa-regular fa-calendar"></i> ${dataCriacao}</span>`;
            
            if (job.deadline) {
                const dataPrazo = new Date(job.deadline);
                prazoHtml += `<br><span class="deadline-badge">⚠️ ${dataPrazo.toLocaleDateString('pt-BR')} ${dataPrazo.toLocaleTimeString('pt-BR', {hour: '2-digit', minute:'2-digit'})}</span>`;
            }

            let statusClass = 'pendente';
            let statusLabel = 'Pendente';
            let botao = '';

            if (job.status === 'em_andamento') { statusClass = 'em_andamento'; statusLabel = 'Imprimindo'; }
            if (job.status === 'impresso') { statusClass = 'impresso'; statusLabel = 'Concluído'; }
            if (job.status === 'cancelado') { statusClass = 'cancelado'; statusLabel = 'Cancelado'; }

            // Lógica dos Botões com o Cancelamento Blindado
            if (job.status === 'pendente' || !job.status) {
                botao = `
                    <button class="btn-action" style="background:var(--primary);" onclick="atualizarStatus(this, ${job.id}, 'em_andamento')">▶ Iniciar</button>
                    <button class="btn-cancel" onclick="cancelarPedido(${job.id})"><i class="fa-solid fa-xmark"></i> Cancelar</button>
                `;
            } else if (job.status === 'em_andamento') {
                botao = `
                    <button class="btn-action" style="background:var(--success);" onclick="atualizarStatus(this, ${job.id}, 'impresso')">✔ Concluir</button>
                    <button class="btn-cancel" onclick="cancelarPedido(${job.id})"><i class="fa-solid fa-xmark"></i> Cancelar</button>
                `;
            }

            const obsHtml = job.observacao ? `<div class="obs-text">"${job.observacao}"</div>` : '<span style="color:#ccc;">-</span>';

            tr.innerHTML = `
                <td><span style="color:#aaa;">#</span>${job.id}</td>
                <td><strong>${job.solicitante}</strong><br><small style="color:#777;">${job.sector || 'Não informado'}</small></td>
                <td style="word-break: break-all;">${htmlArquivos}</td>
                <td>
                    <div style="font-weight:600;">${job.copies} cópia(s)</div>
                    <small style="color:#666;">Modo: ${job.color_mode}</small><br>
                    <small style="color:#666;">Págs: <strong>${job.page_range || 'Todas'}</strong></small><br>
                    <div style="display: flex; gap: 5px; flex-wrap: wrap; margin-top: 4px;">
                        ${job.is_duplex ? '<span style="background:#e8f5e9; color:#1b5e20; border:1px solid #c8e6c9; padding:3px 8px; border-radius:15px; font-size:0.75rem; font-weight:bold; display:inline-flex; align-items:center; gap:3px;"><i class="fa-solid fa-sync"></i> Frente/Verso</span>' : ''}
                        ${job.two_per_page ? '<span style="background:#e3f2fd; color:#0d47a1; border:1px solid #bbdefb; padding:3px 8px; border-radius:15px; font-size:0.75rem; font-weight:bold; display:inline-flex; align-items:center; gap:3px;"><i class="fa-solid fa-grip-vertical"></i> 2 Pág p/ Folha</span>' : ''}
                    </div>
                    <small style="color:#666;">Páginas Arq.: ${job.total_pages || '-'}</small><br>
                    <small style="color:var(--primary); font-weight:700;">Total Impressos: ${job.total_printed || '-'}</small>
                </td>
                <td>${prazoHtml}</td>
                <td style="max-width: 150px;">${obsHtml}</td>
                <td style="text-align:center;">
                    <span class="status-tag status-${statusClass}" style="margin-bottom:8px;">${statusLabel}</span><br>
                    ${botao}
                </td>
            `;
            tbody.appendChild(tr);
        });

        if (pagination && pagination.total_pages > 1) {
            renderPagination(pagination);
        } else {
            document.getElementById('paginationContainer').innerHTML = '';
        }

    } catch (err) { console.error("Erro ao carregar tabela:", err); }
}

function renderPagination(pg) {
    const container = document.getElementById('paginationContainer');
    container.innerHTML = '';

    const btnPrev = document.createElement('button');
    btnPrev.innerHTML = '<i class="fa-solid fa-chevron-left"></i> Anterior';
    btnPrev.style = "width: auto; padding: 8px 15px; font-size: 0.8rem; background: #fff; color: #333; border: 1px solid #ddd;";
    btnPrev.disabled = pg.page === 1;
    btnPrev.onclick = () => carregarPedidos(pg.page - 1);
    container.appendChild(btnPrev);

    const pageText = document.createElement('span');
    pageText.innerText = `Página ${pg.page} de ${pg.total_pages}`;
    pageText.style = "display: flex; align-items: center; font-weight: 600; font-size: 0.9rem; color: #555; padding: 0 10px;";
    container.appendChild(pageText);

    const btnNext = document.createElement('button');
    btnNext.innerHTML = 'Próximo <i class="fa-solid fa-chevron-right"></i>';
    btnNext.style = "width: auto; padding: 8px 15px; font-size: 0.8rem; background: #fff; color: #333; border: 1px solid #ddd;";
    btnNext.disabled = pg.page === pg.total_pages;
    btnNext.onclick = () => carregarPedidos(pg.page + 1);
    container.appendChild(btnNext);
}

// Atualizar Status (Iniciar / Concluir)
async function atualizarStatus(btn, id, novoStatus) {
    const originalText = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i>'; 
    try {
        const res = await fetch(`/api/print/jobs/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', 'user-id': userData.id },
            body: JSON.stringify({ status: novoStatus })
        });
        if(res.ok) {
            carregarPedidos(currentPage);
            setTimeout(carregarGraficos, 500);
        } else {
            alert('Erro ao atualizar status');
        }
    } catch(e) { alert('Erro de conexão'); }
    finally { 
        if (btn) {
            btn.disabled = false;
            btn.innerHTML = originalText;
        }
    }
}

// Função Separada e Blindada para Cancelar
async function cancelarPedido(id) {
    const confirmacao = confirm(`⚠️ Tem a certeza que deseja CANCELAR o pedido #${id}? Esta ação não pode ser desfeita.`);
    if (!confirmacao) return;

    try {
        const res = await fetch(`/api/print/jobs/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', 'user-id': userData.id },
            body: JSON.stringify({ status: 'cancelado' })
        });
        
        if(res.ok) {
            alert(`✅ Pedido #${id} cancelado com sucesso!`);
            carregarTudo(); 
        } else {
            const err = await res.json();
            alert('❌ Erro ao cancelar: ' + (err.error || 'Falha desconhecida'));
        }
    } catch(e) { 
        alert('❌ Erro de conexão ao tentar cancelar.'); 
    }
}

async function carregarGraficos() {
    try {
        const start = document.getElementById('filterStartDate').value;
        const end = document.getElementById('filterEndDate').value;
        const params = new URLSearchParams({ 
            status: currentTab, 
            start_date: start, 
            end_date: end,
            t: Date.now()
        });

        const res = await fetch(`/api/print/stats?${params}`, { 
            headers: { 'user-id': userData.id, 'Cache-Control': 'no-cache' } 
        });
        const data = await res.json();
        
        const ctx1 = document.getElementById('chartSetor').getContext('2d');
        if(chart1) chart1.destroy();
        chart1 = new Chart(ctx1, { 
            type: 'doughnut', 
            data: { 
                labels: data.porSetor.map(d => d.label), 
                datasets: [{ 
                    data: data.porSetor.map(d => d.total), 
                    backgroundColor: ['#0d6efd', '#198754', '#ffc107', '#dc3545', '#6610f2', '#fd7e14'] 
                }] 
            },
            options: { plugins: { legend: { position: 'right', labels: { boxWidth: 12, font: { size: 10 } } } } }
        });

        const ctx2 = document.getElementById('chartUsuario').getContext('2d');
        if(chart2) chart2.destroy();
        chart2 = new Chart(ctx2, { 
            type: 'bar', 
            data: { 
                labels: data.porUsuario.map(d => d.label), 
                datasets: [{ 
                    label: 'Total Pedidos', 
                    data: data.porUsuario.map(d => d.total), 
                    backgroundColor: '#0d6efd',
                    borderRadius: 5
                }] 
            },
            options: { scales: { y: { beginAtZero: true, grid: { display: false } }, x: { grid: { display: false } } }, plugins: { legend: { display: false } } }
        });
        
        const totalCota = 1000;
        const atual = data.cota || 0;
        const percent = Math.min((atual / totalCota) * 100, 100).toFixed(1);
        
        document.getElementById('quotaBar').style.width = percent + '%';
        document.getElementById('quotaText').innerText = `${atual} / ${totalCota}`;
        document.getElementById('quotaPercent').innerText = percent + '%';
        
        if (atual > totalCota) document.getElementById('quotaBar').style.background = 'var(--danger)';
        else if (atual > 800) document.getElementById('quotaBar').style.background = 'var(--warning)';
    } catch(e) {}
}

async function baixarExcel() {
    const start = document.getElementById('filterStartDate').value;
    const end = document.getElementById('filterEndDate').value;
    const params = new URLSearchParams({ status: currentTab, start_date: start, end_date: end });
    
    const res = await fetch(`/api/print/report?${params}`, { headers: { 'user-id': userData.id } });
    if(res.ok) {
        const blob = await res.blob();
        const link = document.createElement('a');
        link.href = window.URL.createObjectURL(blob);
        link.download = `Relatorio_Filtrado_${new Date().toISOString().slice(0,10)}.xlsx`;
        link.click();
    }
}

// --- CÓPIA MANUAL ---
function openManualCopyModal() {
    let modal = document.getElementById('manualCopyModal_V2');
    if (!modal) {
        // Injeta o HTML dinamicamente para evitar problemas de cache no HTML e conflitos de CSS
        const modalHtml = `
            <div id="manualCopyModal_V2" style="display: none; position: fixed; top: 0; left: 0; width: 100vw; height: 100vh; background: rgba(0,0,0,0.6); z-index: 2147483647; justify-content: center; align-items: center; margin: 0; padding: 0;">
                <div style="background: white; width: 400px; max-width: 90%; padding: 25px; border-radius: 12px; box-shadow: 0 10px 40px rgba(0,0,0,0.4); box-sizing: border-box; text-align: left; color: #333;">
                    <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #f0f0f0; padding-bottom: 10px; margin-bottom: 15px;">
                        <h3 style="margin: 0; font-size: 1.2rem; color: #111;"><i class="fa-solid fa-copy"></i> Registrar Cópia Manual</h3>
                        <button onclick="closeManualCopyModal()" style="background: none; border: none; font-size: 1.8rem; cursor: pointer; color: #aaa; line-height: 1;">&times;</button>
                    </div>
                    <form id="manualCopyForm_V2" style="margin: 0;">
                        <div style="margin-bottom: 15px;">
                            <label style="font-weight: bold; font-size: 0.95rem; margin-bottom: 5px; display: block; color: #444;">📍 Setor:</label>
                            <select id="manualCopySector_V2" required style="width: 100%; padding: 12px; border-radius: 6px; border: 1px solid #ccc; font-size: 0.95rem; background: #fafafa; color: #000;">
                                <option value="" disabled selected>Selecione o setor...</option>
                                <option value="Neuropsicopedagogia">Neuropsicopedagogia</option>
                                <option value="Equipe ABA">Equipe ABA</option>
                                <option value="Psicologia">Psicologia</option>
                                <option value="Fonoterapia">Fonoterapia</option>
                                <option value="Terapia Ocupacional">Terapia Ocupacional</option>
                                <option value="Musicoterapia">Musicoterapia</option>
                                <option value="Psicomotricidade">Psicomotricidade</option>
                                <option value="Coordenação">Coordenação</option>
                            </select>
                        </div>
                        <div style="margin-bottom: 15px;">
                            <label style="font-weight: bold; font-size: 0.95rem; margin-bottom: 5px; display: block; color: #444;">📄 Quantidade de Páginas:</label>
                            <input type="number" id="manualCopyAmount_V2" required min="1" style="width: 100%; padding: 12px; border-radius: 6px; border: 1px solid #ccc; font-size: 0.95rem; background: #fafafa; color: #000;">
                        </div>
                        <div style="margin-bottom: 25px;">
                            <label style="font-weight: bold; font-size: 0.95rem; margin-bottom: 5px; display: block; color: #444;">📝 Observação (Opcional):</label>
                            <textarea id="manualCopyObs_V2" rows="2" placeholder="Ex: Cópias para recepção..." style="width: 100%; padding: 12px; border-radius: 6px; border: 1px solid #ccc; font-size: 0.95rem; background: #fafafa; color: #000; resize: vertical;"></textarea>
                        </div>
                        <div style="display: flex; gap: 10px;">
                            <button type="button" style="flex: 1; padding: 12px; background: #e9ecef; border: none; border-radius: 6px; cursor: pointer; color: #333; font-weight: bold; font-size: 0.95rem;" onclick="closeManualCopyModal()">Cancelar</button>
                            <button type="submit" style="flex: 1; padding: 12px; background: #198754; color: white; border: none; border-radius: 6px; cursor: pointer; font-weight: bold; font-size: 0.95rem;">Salvar Registro</button>
                        </div>
                    </form>
                </div>
            </div>
        `;
        document.body.insertAdjacentHTML('beforeend', modalHtml);

        document.getElementById('manualCopyForm_V2').addEventListener('submit', async (e) => {
            e.preventDefault();
            const btn = e.target.querySelector('button[type="submit"]');
            const originalText = btn.innerText;
            btn.disabled = true;
            btn.innerText = 'Salvando...';

            const sector = document.getElementById('manualCopySector_V2').value;
            const amount = parseInt(document.getElementById('manualCopyAmount_V2').value);
            const obs = document.getElementById('manualCopyObs_V2').value.trim();

            try {
                const res = await fetch('/api/print/manual-copy', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'user-id': userData.id },
                    body: JSON.stringify({ sector: sector, total_printed: amount, observacao: obs })
                });
                
                const data = await res.json();
                
                if (res.ok) {
                    alert('✅ Registro de cópia manual salvo com sucesso!');
                    closeManualCopyModal();
                    carregarTudo();
                } else {
                    alert('❌ Erro: ' + (data.error || 'Falha ao salvar.'));
                }
            } catch (err) {
                alert('Erro de conexão ao salvar cópia manual.');
            } finally {
                btn.disabled = false;
                btn.innerText = originalText;
            }
        });
    }

    // Se já existia um modal da tentativa anterior (cache do HTML), vamos forçar esconder
    const oldModal = document.getElementById('manualCopyModal');
    if (oldModal) oldModal.style.display = 'none';

    modal = document.getElementById('manualCopyModal_V2');
    modal.style.display = 'flex';
    document.getElementById('manualCopyForm_V2').reset();
}

function closeManualCopyModal() {
    const modal = document.getElementById('manualCopyModal_V2');
    if (modal) modal.style.display = 'none';
}