import pdfplumber
import os

# Caminho do PDF (Ajustado para o novo nome ou o antigo enquanto não muda)
pdf_path = "NEURORH/public/uploads/politica_dayoff.pdf"
if not os.path.exists(pdf_path):
    pdf_path = "NEUROGESTAO/public/uploads/politica_dayoff.pdf"

print(f"--- ANALISANDO PDF: {pdf_path} ---")

try:
    with pdfplumber.open(pdf_path) as pdf:
        page = pdf.pages[2] # Página 3 (Index 2)
        height = float(page.height)
        
        print(f"Dimensões da página: {page.width} x {page.height}")
        
        # 1. Tenta encontrar linhas horizontais (vetores)
        print("\n[LINHAS ENCONTRADAS]")
        for line in page.lines:
            # pdfplumber 'top' é distância do topo. 
            # pdf-lib 'y' é distância do Rodapé.
            # Y_pdflib = Height - Top
            y_lib = height - float(line['top'])
            print(f"Linha horizontal em Y_PDFLib ≈ {y_lib:.1f} (X: {line['x0']:.1f} até {line['x1']:.1f})")

        # 2. Tenta encontrar textos próximos para contexto
        print("\n[TEXTOS DE REFERÊNCIA]")
        words = page.extract_words()
        for word in words:
            text = word['text'].lower()
            if any(k in text for k in ["eu", "cargo", "cpf", "palmas", "data", "assinatura"]):
                y_lib = height - float(word['top'])
                print(f"Texto '{word['text']}' em X={word['x0']:.1f}, Y_PDFLib ≈ {y_lib:.1f}")

except Exception as e:
    print(f"Erro: {e}")
