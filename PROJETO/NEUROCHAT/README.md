# 💬 NeuroChat

**NeuroChat** é o sistema de mensageria interna e notificações em tempo real, servindo como a espinha dorsal de comunicação entre as equipes, terapeutas, recepção e gestão.

Além do chat humano-para-humano (organizado por departamentos), o NeuroChat recebe **Webhooks** de outros microserviços (como NeuroGestão e Suporte). Por exemplo, quando um paciente novo é agendado ou há um encaixe, o NeuroChat emite um alerta instantâneo para o setor responsável, automatizando a comunicação clínica.

## 🛠️ Tecnologias Utilizadas
*   **Node.js**: Core do servidor, ideal para WebSockets e tempo real.
*   **Integrações**: API de Webhooks para comunicação inter-serviços.

## ⚙️ Como Executar
1. Acesse o diretório `NEUROCHAT`.
2. Instale as dependências: `npm install`
3. Execute o servidor em modo de desenvolvimento: `npm run dev` (ou conforme especificado no `package.json`).
