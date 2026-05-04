# 🧠 NeuroGestão

**NeuroGestão** é o núcleo central de agendamento e gerenciamento operacional para clínicas e centros terapêuticos. O sistema atua como o cérebro das operações de recepção, coordenação e gestão, garantindo que os pacientes sejam alocados de forma inteligente e eficiente na grade de horários dos profissionais.

O grande diferencial do NeuroGestão é o seu **Motor de Sugestão Inteligente**, que cruza as terapias necessárias do paciente com as idades compatíveis e as agendas dos terapeutas, buscando sempre criar "combos" (terapias consecutivas) para otimizar o tempo das famílias na clínica.

## 🚀 Principais Funcionalidades

*   **Lista de Espera Dinâmica**: Controle de pacientes aguardando vagas, com alertas visuais de tempo de espera (crítico, alerta, normal) e gestão das terapias mapeadas na triagem (ex: Fono 2x, ABA 3x).
*   **Motor Inteligente de Agendamentos**: Sugere automaticamente os melhores horários na grade. Prioriza atendimentos seguidos (combos) ou no mesmo dia.
*   **Gestão de Grade e Encaixes**: Painel interativo para a recepção visualizar e manipular a grade semanal dos terapeutas, incluindo suporte avançado para "Encaixes" emergenciais.
*   **Central de Aprovação e Transferências**: Fluxos de transferência de pacientes entre profissionais com aprovação gerencial.
*   **Notificações Automatizadas (Integração NeuroChat)**: Notifica diretamente setores e terapeutas (via webhook/API) sobre aprovações, transferências, retiradas e encaixes.

## 🛠️ Tecnologias Utilizadas

O sistema foi desenvolvido utilizando uma arquitetura moderna e pragmática:

**Backend & API:**
*   **Ruby on Rails 8**: Framework central da aplicação.
*   **MySQL**: Banco de dados relacional (via `mysql2`).
*   **Puma**: Servidor web da aplicação.

**Frontend:**
*   **Tailwind CSS**: Framework de estilização baseado em utilitários para construir uma interface rápida e esteticamente agradável (Glassmorphism, Micro-interações).
*   **Vanilla JS**: JavaScript nativo para manipulação ágil do DOM (modais, requisições AJAX para a API do Rails), sem necessidade de frameworks pesados, garantindo leveza.
*   **HTML5 & CSS3**: Estrutura e animações personalizadas.

## ⚙️ Pré-requisitos e Execução Local

Para rodar o projeto localmente em ambiente de desenvolvimento, você precisará de:

*   **Ruby** (Versão definida no `.ruby-version` ou Gemfile)
*   **MySQL Server** rodando localmente
*   **Bundler** para gerenciar as gems

### Passos para rodar:

1.  Clone o repositório e navegue até a pasta do NeuroGestão.
2.  Instale as dependências:
    ```bash
    bundle install
    ```
3.  Configure o banco de dados (ajuste o arquivo `config/database.yml` se necessário) e crie/migre as tabelas:
    ```bash
    rails db:create
    rails db:migrate
    ```
4.  Suba o servidor de desenvolvimento:
    ```bash
    rails server
    ```
5.  Acesse `http://localhost:3000` no seu navegador.

## 🔄 Arquitetura de Comunicação

O **NeuroGestão** é independente, mas se comunica estreitamente com o banco de dados e os serviços do **NeuroChat**. 
Por meio de `Services` no Rails, eventos cruciais na grade de horários disparam envio de mensagens diretas e alertas para grupos operacionais, reduzindo drasticamente as falhas de comunicação interna.
