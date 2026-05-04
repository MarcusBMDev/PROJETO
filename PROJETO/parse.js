const fs = require('fs');

try {
    const content = fs.readFileSync('c:/GitHub/PROJETO/neurochat_db.sql', 'utf8');
    
    // Instead of parsing perfectly, let's just find ALL occurrences of:
    // 'status_string', 'YYYY-MM-DD HH:MM:SS', total_pages, total_printed)
    
    const rowEndRegex = /'(pendente|impresso|em_andamento|cancelado)',\s*'(\d{4}-\d{2}-\d{2}[^']+)',\s*(-?\d+),\s*(-?\d+)\)/g;

    let match;
    let count = 0;
    let totalAllTime = 0;
    let totalApril = 0;

    let largeJobs = [];

    while ((match = rowEndRegex.exec(content)) !== null) {
        count++;
        let status = match[1];
        let dateStr = match[2];
        let total_pages = parseInt(match[3], 10);
        let total_printed = parseInt(match[4], 10);

        // Somente conta o que não for cancelado, igual a lógica do controller
        if (status !== 'cancelado') {
            totalAllTime += total_printed;
            if (dateStr.startsWith('2026-04')) {
                totalApril += total_printed;
                if (total_printed >= 100) {
                    largeJobs.push({ status, dateStr, total_pages, total_printed });
                }
            }
        }
    }
    
    console.log(`Total rows processed: ${count}`);
    console.log(`Total printed (All time, exc. cancelado): ${totalAllTime}`);
    console.log(`Total printed (April 2026, exc. cancelado): ${totalApril}`);
    
    console.log(`\nJobs => 100 pages em April:`);
    largeJobs.sort((a,b) => b.total_printed - a.total_printed).forEach(j => {
        console.log(`Date: ${j.dateStr} | Status: ${j.status} | Pages: ${j.total_pages} | Printed: ${j.total_printed}`);
    });

} catch (e) {
    console.error(e);
}
