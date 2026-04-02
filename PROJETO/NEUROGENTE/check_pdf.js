const { PDFDocument } = require('pdf-lib');
const fs = require('fs');
const path = require('path');

async function checkPdf() {
    try {
        const filePath = path.join(__dirname, 'public/uploads/solicitacao_dayoff_1774529270944.pdf');
        const data = fs.readFileSync(filePath);
        const pdfDoc = await PDFDocument.load(data);
        console.log(`Páginas no gerado: ${pdfDoc.getPageCount()}`);
    } catch (e) {
        console.error(e);
    }
}
checkPdf();
