# 🧠 NeuroSystem

## Enterprise Modular Intranet Ecosystem

### Ecossistema Modular Corporativo de Intranet

------------------------------------------------------------------------

## 📌 Visão Geral \| Overview

**PT-BR:**\
O **NeuroSystem** é um ecossistema corporativo de intranet desenvolvido
para centralizar comunicação, operações, RH, logística e serviços
internos da NeuroCenter em uma arquitetura modular e escalável.

A plataforma substitui processos fragmentados por um sistema unificado
com isolamento de serviços e soberania de dados (100% on-premise).

**EN:**\
**NeuroSystem** is an enterprise intranet ecosystem designed to
centralize communication, operations, HR workflows, logistics, and
internal services within a modular and scalable architecture.

The platform replaces fragmented processes with a unified
service-isolated system ensuring full on-premise data sovereignty.

------------------------------------------------------------------------

## 🏗️ Arquitetura \| Architecture

### Estratégia Arquitetural

**PT-BR:**\
O sistema segue um modelo de microsserviços locais distribuídos por
porta lógica:

-   Cada módulo roda de forma independente\
-   Banco de dados MySQL compartilhado\
-   Isolamento de falhas entre serviços\
-   Deploy independente por módulo

**EN:**\
The system follows a local microservices-oriented approach distributed
by logical ports:

-   Each module runs independently\
-   Shared MySQL database\
-   Service-level fault isolation\
-   Independent deployment per module

### Fluxo Geral

    Usuário | User
          ↓
    Portal Gateway (Dashboard Unificado)
          ↓
    -------------------------------------------------
    NeuroChat | NeuroAgenda | Support TI | NeuroCar
    -------------------------------------------------
                          ↓
                  Shared MySQL Database

------------------------------------------------------------------------

## 🚀 Módulos \| Modules

### 📡 Comunicação \| Communication

-   **NeuroChat (Porta 3000)** -- Mensagens em tempo real com
    WebSockets\
-   **Portal Gateway** -- Navegação e monitoramento dos serviços

### 👥 RH & Governança \| HR & Governance

-   **NeuroRH** -- Portal do colaborador\
-   **Ouvidoria** -- Canal estruturado de feedback

### ⚙️ Operações & Logística \| Operations & Logistics

-   **NeuroCar (Porta 3003)** -- Gestão de frota\
-   **NeuroAgenda (Porta 3002)** -- Reservas com prevenção de conflito\
-   **Support TI (Porta 3001)** -- HelpDesk com SLA

### 📊 Suprimentos & Marketing \| Procurement & Marketing

-   **NeuroCompras** -- Fluxo de requisições\
-   **NeuroPrint** -- Gestão de impressão\
-   **SolicitaMKT** -- Workflow de marketing

------------------------------------------------------------------------

## 🛠 Dashboard Tecnológico \| Technology Dashboard

### Backend

![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)

### Frontend

![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![Blade](https://img.shields.io/badge/Blade-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white)

### Real-Time

![Socket.io](https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socketdotio&logoColor=white)

### Database

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

------------------------------------------------------------------------

## 🗄 Estratégia de Dados \| Data Strategy

**PT-BR:**\
- Banco relacional compartilhado\
- Separação lógica por esquemas\
- Integridade referencial\
- Identidade centralizada de colaboradores

**EN:**\
- Shared relational database\
- Logical schema separation\
- Referential integrity\
- Centralized collaborator identity

------------------------------------------------------------------------

## 🎯 Decisões Arquiteturais \| Architectural Decisions

✔ Deploy on-premise\
✔ Isolamento por porta\
✔ Banco compartilhado para identidade única\
✔ WebSockets para experiência em tempo real\
✔ Estrutura modular para expansão futura

------------------------------------------------------------------------

## 🔧 Requisitos de Ambiente \| Environment Requirements

-   Node.js v18+\
-   PHP 8.1+\
-   MySQL / MariaDB\
-   Apache ou Nginx\
-   npm ou yarn

------------------------------------------------------------------------

## 📈 Roadmap

-   Containerização com Docker\
-   Autenticação SSO centralizada\
-   API Gateway formal\
-   Monitoramento estruturado\
-   CI/CD pipeline

------------------------------------------------------------------------

## 👨‍💻 Autor \| Author

**Marcus Bandeira Morais**\
Analista de TI \| Desenvolvedor de Sistemas\
IT Analyst \| Systems Developer

------------------------------------------------------------------------

NeuroSystem • Modularidade • Performance • Escalabilidade
