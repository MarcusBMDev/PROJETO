const pool = require('../config/database');
const ExcelJS = require('exceljs');
const { PDFDocument } = require('pdf-lib');
const fs = require('fs').promises;
const path = require('path');
const sectorsQuotas = require('../config/quotas');

function countPagesInRange(rangeStr, totalPages) {
    if (!rangeStr || rangeStr.toLowerCase().trim() === 'todas' || rangeStr.trim() === '') {
        return totalPages;
    }

    try {
        // Normalização agressiva para tratar diversos separadores comuns
        let normalized = rangeStr.toLowerCase()
            .replace(/\s+e\s+/g, ',')  // "102 e 106" -> "102,106"
            .replace(/\s+e/g, ',')    
            .replace(/e\s+/g, ',')
            .replace(/;/g, ',')        // ";" -> ","
            .replace(/\s+/g, ' ');     // Remove espaços múltiplos

        const parts = normalized.split(',').map(p => p.trim()).filter(p => p !== '');
        let count = 0;
        
        for (const part of parts) {
            if (part.includes('-')) {
                const splitPart = part.split('-');
                if (splitPart.length >= 2) {
                    const startStr = splitPart[0].trim();
                    const endStr = splitPart[1].trim();
                    const start = parseInt(startStr);
                    const end = parseInt(endStr);
                    
                    if (!isNaN(start) && !isNaN(end)) {
                        const s = Math.max(1, start);
                        const e = Math.min(totalPages, end);
                        if (e >= s) {
                            count += (e - s + 1);
                        }
                    }
                }
            } else {
                const pageNum = parseInt(part);
                if (!isNaN(pageNum) && pageNum >= 1 && pageNum <= totalPages) {
                    count += 1;
                }
            }
        }
        
        return count > 0 ? count : totalPages;
    } catch (e) {
        console.error("Erro ao processar range de páginas:", e);
        return totalPages;
    }
}

// Helper para calcular o consumo atual de um setor no mês
async function calculateSectorConsumption(sector, connection) {
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1; // 1-12

    const sql = `
        SELECT SUM(total_printed) as used 
        FROM neuroprint_jobs 
        WHERE sector = ? 
        AND status NOT IN ('cancelado')
        AND YEAR(created_at) = ? 
        AND MONTH(created_at) = ?
    `;

    const [rows] = await connection.execute(sql, [sector, year, month]);
    return rows[0].used || 0;
}

module.exports = {
    // 1. CRIAR PEDIDO
    async store(req, res) {
        const connection = await pool.getConnection();
        try {
            const { user_id, sector, copies, color_mode, is_duplex, two_per_page, deadline, is_urgent, observacao, page_range } = req.body;
            const files = req.files;

            if (!files || files.length === 0) {
                return res.status(400).json({ error: 'Erro: Nenhum PDF enviado.' });
            }

            // --- CONTAGEM DE PÁGINAS ---
            let totalPages = 0;
            let totalPrinted = 0;
            const uploadFolder = path.resolve(__dirname, '..', '..', 'storage', 'uploads');

            for (const file of files) {
                try {
                    const filePath = path.join(uploadFolder, file.filename);
                    const pdfBuffer = await fs.readFile(filePath);
                    const pdfDoc = await PDFDocument.load(pdfBuffer, { ignoreEncryption: true });
                    const filePageCount = pdfDoc.getPageCount();
                    
                    totalPages += filePageCount;
                    
                    // Se houver multi-arquivos, aplicamos o range em cada um (padrão comum de impressão)
                    // Ou se preferir que o range seja global, a lógica mudaria. 
                    // Geralmente, "1-2" de 2 arquivos PDF significa páginas 1-2 de cada.
                    totalPrinted += countPagesInRange(page_range, filePageCount);
                } catch (pdfError) {
                    console.error(`Erro ao contar páginas do arquivo ${file.originalname}:`, pdfError);
                }
            }

            let totalImpressosFinal = totalPrinted;
            
            // Lógica de contagem de folhas:
            const isDuplexTrue = is_duplex === 'on' || is_duplex === 'true' || is_duplex === true || is_duplex === 1;
            const twoPerPageTrue = two_per_page === 'on' || two_per_page === 'true' || two_per_page === true || two_per_page === 1;
            const isUrgentTrue = is_urgent === 'on' || is_urgent === 'true' || is_urgent === true || is_urgent === 1;

            // 1. Se 2 páginas por folha, divide por 2
            if (twoPerPageTrue) {
                totalImpressosFinal = Math.ceil(totalImpressosFinal / 2);
            }

            // 2. Se frente e verso, divide por 2
            if (isDuplexTrue) {
                totalImpressosFinal = Math.ceil(totalImpressosFinal / 2);
            }

            // 3. Multiplica pelas cópias
            totalImpressosFinal = totalImpressosFinal * (parseInt(copies) || 1);
            // ---------------------------

            // --- VALIDAÇÃO DE COTA ---
            if (sector) {
                const used = await calculateSectorConsumption(sector, connection);
                const limit = sectorsQuotas[sector];

                // Regra: Bloqueia apenas se tiver limite definido E não for administrador
                if (limit) {
                    // Busca se o usuário é administrador
                    const [userRows] = await connection.execute('SELECT is_super_admin FROM users WHERE id = ?', [user_id]);
                    const [adminRows] = await connection.execute('SELECT id FROM neuroprint_admins WHERE user_id = ?', [user_id]);
                    const isAdmin = (userRows.length > 0 && userRows[0].is_super_admin === 1) || adminRows.length > 0;

                    if (!isAdmin && (used + totalImpressosFinal) > limit) {
                        return res.status(403).json({ 
                            error: `🚫 Cota excedida para o setor "${sector}".`,
                            detail: `O setor já utilizou ${used} de ${limit} páginas. Este pedido de ${totalImpressosFinal} páginas ultrapassaria o limite mensal.`
                        });
                    }
                }
            }
            // ---------------------------

            const fileNames = files.map(f => f.originalname).join(';');
            const filePaths = files.map(f => f.filename).join(';'); 

            const dataPrazo = deadline && deadline !== '' ? deadline : null;

            const sql = `
                INSERT INTO neuroprint_jobs 
                (user_id, sector, file_name, file_path, file_type, page_range, copies, color_mode, is_duplex, two_per_page, deadline, is_urgent, observacao, status, total_pages, total_printed)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pendente', ?, ?)
            `;

            const tipoArquivo = files.length > 1 ? 'Múltiplos PDFs' : 'application/pdf';

            await connection.execute(sql, [
                user_id, sector, fileNames, filePaths, tipoArquivo, page_range || 'Todas',
                copies || 1, color_mode || 'PB', 
                (isDuplexTrue ? 1 : 0),
                (twoPerPageTrue ? 1 : 0),
                dataPrazo, (isUrgentTrue ? 1 : 0), observacao || '',
                totalPages, totalImpressosFinal
            ]);

            return res.status(201).json({ message: 'Solicitação enviada com sucesso!', total_pages: totalPages, total_printed: totalImpressosFinal });

        } catch (error) {
            console.error('Erro ao salvar pedido:', error);
            return res.status(500).json({ error: 'Erro ao salvar.' });
        } finally {
            connection.release();
        }
    },

    // 2. LISTAR (ADMIN)
    async index(req, res) {
        const connection = await pool.getConnection();
        try {
            const { status, start_date, end_date, page = 1, limit = 50 } = req.query;
            const offset = (parseInt(page) - 1) * parseInt(limit);
            
            let whereSql = ' WHERE 1=1';
            const params = [];

            if (status && status !== 'todos') {
                whereSql += ` AND j.status = ?`;
                params.push(status);
            }

            if (start_date) {
                whereSql += ` AND j.created_at >= ?`;
                params.push(`${start_date} 00:00:00`);
            }

            if (end_date) {
                whereSql += ` AND j.created_at <= ?`;
                params.push(`${end_date} 23:59:59`);
            }

            // Conta o total para paginação
            const [countRows] = await connection.execute(`SELECT COUNT(*) as total FROM neuroprint_jobs j ${whereSql}`, params);
            const total = countRows[0].total;

            const sql = `
                SELECT j.*, u.username AS solicitante
                FROM neuroprint_jobs j
                INNER JOIN users u ON j.user_id = u.id
                ${whereSql}
                ORDER BY 
                    CASE 
                        WHEN j.status = 'pendente' THEN 1 
                        WHEN j.status = 'em_andamento' THEN 2 
                        ELSE 3 
                    END,
                    j.is_urgent DESC,
                    j.created_at DESC
                LIMIT ? OFFSET ?
            `;
            
            const [rows] = await connection.execute(sql, [...params, parseInt(limit), offset]);
            
            return res.json({
                data: rows,
                pagination: {
                    total,
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total_pages: Math.ceil(total / limit)
                }
            });
        } catch (error) {
            console.error('Erro no index admin:', error);
            return res.status(500).json({ error: 'Erro ao listar.' });
        } finally {
            connection.release();
        }
    },

    // 3. MEUS PEDIDOS
    async myRequests(req, res) {
        const connection = await pool.getConnection();
        try {
            const userId = req.query.user_id; 
            const sql = `
                SELECT id, file_name, status, created_at, deadline, total_pages, total_printed 
                FROM neuroprint_jobs 
                WHERE user_id = ? 
                ORDER BY id DESC LIMIT 10
            `;
            const [rows] = await connection.execute(sql, [userId]);
            return res.json(rows);
        } catch (error) {
            console.error('Erro em myRequests:', error);
            return res.status(500).json({ error: 'Erro ao buscar meus pedidos.' });
        } finally {
            connection.release();
        }
    },
 
    // 4. ATUALIZAR STATUS
    async updateStatus(req, res) {
        const connection = await pool.getConnection();
        try {
            const { id } = req.params; 
            const { status } = req.body;
            console.log(`[NeuroPrint Debug] Tentando atualizar pedido ${id} para status: ${status}`);
            
            const sql = 'UPDATE neuroprint_jobs SET status = ? WHERE id = ?';
            const [result] = await connection.execute(sql, [status, id]);

            console.log(`[NeuroPrint Debug] Resultado: affectedRows=${result.affectedRows}, changedRows=${result.changedRows || 'n/a'}`);

            if (result.affectedRows === 0) {
                return res.status(404).json({ error: 'Pedido não encontrado.' });
            }

            return res.json({ message: 'Status atualizado com sucesso!' });
        } catch (error) {
            console.error("[NeuroPrint Debug] Erro no updateStatus:", error); 
            return res.status(500).json({ error: 'Erro ao atualizar status.' });
        } finally {
            connection.release();
        }
    },
    // 5. GRÁFICOS E COTA
    async stats(req, res) {
        const connection = await pool.getConnection();
        try {
            let { status, start_date, end_date } = req.query;
            
            // Se não informou datas, pega o primeiro e o último dia do mês atual
            if (!start_date || !end_date) {
                const now = new Date();
                const year = now.getFullYear();
                const month = now.getMonth();
                
                if (!start_date) {
                    const firstDay = new Date(year, month, 1);
                    start_date = firstDay.toISOString().split('T')[0];
                }
                
                if (!end_date) {
                    const lastDay = new Date(year, month + 1, 0);
                    end_date = lastDay.toISOString().split('T')[0];
                }
            }

            let filterSql = ' WHERE 1=1';
            const params = [];

            if (status && status !== 'todos') {
                filterSql += ` AND j.status = ?`;
                params.push(status);
            }
            if (start_date) {
                filterSql += ` AND j.created_at >= ?`;
                params.push(`${start_date} 00:00:00`);
            }
            if (end_date) {
                filterSql += ` AND j.created_at <= ?`;
                params.push(`${end_date} 23:59:59`);
            }

            const [porSetor] = await connection.execute(`
                SELECT j.sector as label, SUM(j.total_printed) as total 
                FROM neuroprint_jobs j JOIN users u ON j.user_id = u.id ${filterSql} GROUP BY j.sector
            `, params);

            const [porUsuario] = await connection.execute(`
                SELECT u.username as label, COUNT(*) as total 
                FROM neuroprint_jobs j JOIN users u ON j.user_id = u.id ${filterSql} GROUP BY u.username ORDER BY total DESC LIMIT 5
            `, params);

            // COTA MENSAL (Soma tudo que foi impresso ou está em andamento)
            // Nota: Para a cota, talvez faça sentido não filtrar por data para manter o acumulado do mês, 
            // mas aqui vamos permitir filtrar se o usuário quiser ver o consumo do período selecionado.
            const [cota] = await connection.execute(`
                SELECT SUM(total_printed) as total_geral 
                FROM neuroprint_jobs j
                ${filterSql} ${filterSql.includes('status') ? '' : " AND j.status IN ('impresso', 'em_andamento')"}
            `, params);

            return res.json({ 
                porSetor, 
                porUsuario, 
                cota: cota[0].total_geral || 0 
            });
        } catch (error) {
            console.error('Erro em stats:', error);
            return res.status(500).json({ error: 'Erro ao buscar estatísticas.' });
        } finally {
            connection.release();
        }
    },

    // 6. EXCEL
    async downloadReport(req, res) {
        const connection = await pool.getConnection();
        try {
            const { status, start_date, end_date } = req.query;
            let sql = `
                SELECT j.id, u.username, j.sector as department, j.file_name, j.copies, j.total_pages, j.total_printed, j.status, j.created_at, j.deadline, j.is_duplex, j.two_per_page
                FROM neuroprint_jobs j 
                JOIN users u ON j.user_id = u.id 
                WHERE 1=1
            `;
            const params = [];

            if (status && status !== 'todos') {
                sql += ` AND j.status = ?`;
                params.push(status);
            }

            if (start_date) {
                sql += ` AND j.created_at >= ?`;
                params.push(`${start_date} 00:00:00`);
            }

            if (end_date) {
                sql += ` AND j.created_at <= ?`;
                params.push(`${end_date} 23:59:59`);
            }

            sql += ` ORDER BY j.created_at DESC`;

            const [rows] = await connection.execute(sql, params);

            const workbook = new ExcelJS.Workbook();
            const worksheet = workbook.addWorksheet('Relatório');
            worksheet.columns = [
                { header: 'ID', key: 'id' }, 
                { header: 'Solicitante', key: 'username' },
                { header: 'Setor', key: 'department' }, 
                { header: 'Arquivo', key: 'file_name' },
                { header: 'Cópias', key: 'copies' }, 
                { header: 'Pág/Arquivo', key: 'total_pages' },
                { header: 'Frente e Verso', key: 'is_duplex_text' },
                { header: '2 Pág/Folha', key: 'two_per_page_text' },
                { header: 'Total Impresso', key: 'total_printed' },
                { header: 'Status', key: 'status' },
                { header: 'Data Solicitação', key: 'created_at' },
                { header: 'Prazo Limite', key: 'deadline' }
            ];
            rows.forEach(row => {
                const rowData = {
                    ...row,
                    is_duplex_text: row.is_duplex ? 'Sim' : 'Não',
                    two_per_page_text: row.two_per_page ? 'Sim' : 'Não'
                };
                worksheet.addRow(rowData);
            });
            
            res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            res.setHeader('Content-Disposition', 'attachment; filename=Relatorio_NeuroPrint.xlsx');
            await workbook.xlsx.write(res);
            res.end();
        } catch (error) {
            console.error('Erro ao gerar relatório:', error);
            res.status(500).json({ error: 'Erro ao gerar relatório.' });
        } finally {
            connection.release();
        }
    },

    // 7. CONSULTAR STATUS DA COTA (PÚBLICO)
    async getQuotaStatus(req, res) {
        const connection = await pool.getConnection();
        try {
            const { sector } = req.params;
            if (!sector) return res.status(400).json({ error: 'Setor não informado.' });

            const used = await calculateSectorConsumption(sector, connection);
            const limit = sectorsQuotas[sector] || 0; // 0 significa sem limite definido no config

            return res.json({ sector, used, limit });
        } catch (error) {
            console.error('Erro em getQuotaStatus:', error);
            return res.status(500).json({ error: 'Erro ao consultar cota.' });
        } finally {
            connection.release();
        }
    }
};
