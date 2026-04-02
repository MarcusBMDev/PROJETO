const { PDFDocument, rgb, StandardFonts } = require('pdf-lib');
const fs = require('fs');
const path = require('path');

async function gerarRegua() {
    try {
        const filePath = path.join(__dirname, 'public/uploads/politica_dayoff.pdf');
        const data = fs.readFileSync(filePath);
        const pdfDoc = await PDFDocument.load(data);
        const pages = pdfDoc.getPages();
        const page = pages[2]; // Página 3 (Index 2)
        const { width, height } = page.getSize();

        const font = await pdfDoc.embedFont(StandardFonts.Helvetica);

        // Desenha uma grade (Régua)
        for (let x = 0; x <= width; x += 50) {
            page.drawLine({
                start: { x, y: 0 },
                end: { x, y: height },
                thickness: 0.5,
                color: rgb(0.8, 0.8, 0.8),
                opacity: 0.5,
            });
            page.drawText(x.toString(), { x: x + 2, y: 10, size: 8, font });
        }

        for (let y = 0; y <= height; y += 50) {
            page.drawLine({
                start: { x: 0, y },
                end: { x: width, y },
                thickness: 0.5,
                color: rgb(0.8, 0.8, 0.8),
                opacity: 0.5,
            });
            page.drawText(y.toString(), { x: 10, y: y + 2, size: 8, font });
        }

        // Desenha sub-linhas a cada 10
        for (let y = 0; y <= height; y += 10) {
            if (y % 50 === 0) continue;
            page.drawLine({
                start: { x: 0, y },
                end: { x: 15, y },
                thickness: 0.2,
                color: rgb(0.9, 0, 0),
            });
        }

        const pdfBytes = await pdfDoc.save();
        fs.writeFileSync(path.join(__dirname, 'public/uploads/REGUA_CALIBRACAO.pdf'), pdfBytes);
        console.log('✅ Arquivo REGUA_CALIBRACAO.pdf gerado em public/uploads/');
        console.log('Abra este arquivo para identificar as coordenadas exatas das linhas.');
    } catch (e) {
        console.error(e);
    }
}

gerarRegua();
