# 🧠 NeuroSystem

```{=html}
<p align="center">
```
`<strong>`{=html}Enterprise Modular Intranet
Ecosystem`</strong>`{=html}`<br>`{=html} Scalable • Real-Time •
On-Premise • Service-Isolated Architecture
```{=html}
</p>
```

------------------------------------------------------------------------

## 🚀 Project Overview

**NeuroSystem** is an enterprise-grade modular intranet ecosystem
designed to centralize communication, operations, HR workflows,
logistics, and internal services within NeuroCenter.

The platform replaces fragmented tools with a unified, service-isolated
architecture optimized for:

-   Operational efficiency\
-   Real-time collaboration\
-   Fault isolation between modules\
-   Data sovereignty (100% on-premise deployment)\
-   Modular scalability

------------------------------------------------------------------------

## 🧠 Architecture Strategy

NeuroSystem follows a **Local Microservices-Oriented Architecture**,
where:

-   Each module runs independently on its own port\
-   Services share a centralized MySQL database\
-   Failures in one module do not impact the entire system\
-   Deployment can be performed per module

### High-Level Flow

    User
      ↓
    Portal Gateway (Unified Dashboard)
      ↓
    -------------------------------------------------
    NeuroChat | NeuroAgenda | Support TI | NeuroCar
    -------------------------------------------------
                        ↓
                Shared MySQL Database

------------------------------------------------------------------------

## 🧩 Core Modules

### 📡 Communication Layer

-   **NeuroChat (Port 3000)** -- Real-time messaging powered by
    WebSockets\
-   **Portal Gateway** -- Centralized service navigation and status
    monitoring

### 👥 HR & Governance

-   **NeuroRH** -- Employee portal and internal request cockpit\
-   **Ouvidoria** -- Structured internal feedback routing

### ⚙️ Operations & Logistics

-   **NeuroCar (Port 3003)** -- Fleet control and mileage tracking\
-   **NeuroAgenda (Port 3002)** -- Asset & room reservation system\
-   **Support TI (Port 3001)** -- Internal HelpDesk with SLA control

### 📊 Procurement & Marketing

-   **NeuroCompras** -- Supply request and approval workflow\
-   **NeuroPrint** -- Print demand management\
-   **SolicitaMKT** -- Marketing workflow system

------------------------------------------------------------------------

## 🛠 Technology Dashboard

### Backend

![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Laravel](https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)

### Frontend

![JavaScript](https://img.shields.io/badge/JavaScript-F7DF1E?style=for-the-badge&logo=javascript&logoColor=black)
![Blade](https://img.shields.io/badge/Blade-FF2D20?style=for-the-badge&logo=laravel&logoColor=white)
![CSS3](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white)

### Real-Time Communication

![Socket.io](https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socketdotio&logoColor=white)

### Database

![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=for-the-badge&logo=mariadb&logoColor=white)

------------------------------------------------------------------------

## 🗄 Data Strategy

-   Shared relational database\
-   Logical schema separation\
-   Referential integrity enforcement\
-   Centralized collaborator identity management

------------------------------------------------------------------------

## 🎯 Key Architectural Decisions

✔ On-Premise deployment for data sovereignty\
✔ Port-based service isolation\
✔ Centralized database for simplified identity control\
✔ WebSockets for real-time interaction\
✔ Modular scalability for future expansion

------------------------------------------------------------------------

## 🔧 Environment Requirements

-   Node.js v18+\
-   PHP 8.1+\
-   MySQL / MariaDB\
-   Apache or Nginx\
-   npm or yarn

------------------------------------------------------------------------

## 📈 Roadmap

-   Docker containerization\
-   Centralized SSO authentication\
-   API Gateway abstraction layer\
-   Structured logging & monitoring\
-   CI/CD integration

------------------------------------------------------------------------

## 👨‍💻 Author

**Marcus Bandeira Morais**\
IT Analyst \| Systems Developer\
Specialist in Internal Systems Architecture & Process Automation

------------------------------------------------------------------------

```{=html}
<p align="center">
```
Enterprise-grade internal systems engineered with modular intelligence.
```{=html}
</p>
```
