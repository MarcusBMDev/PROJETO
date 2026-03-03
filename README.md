# 🧠 NeuroSystem

## Enterprise Intranet Ecosystem

```{=html}
<p align="center">
```
`<b>`{=html}Modular • Scalable • Real-Time • On-Premise`</b>`{=html}
```{=html}
</p>
```

------------------------------------------------------------------------

## 📌 Overview

**NeuroSystem** is an enterprise-grade intranet ecosystem developed to
centralize communication, operations, and administrative workflows
inside NeuroCenter.

The platform was designed to replace fragmented processes with a unified
modular architecture that prioritizes:

-   Operational efficiency
-   Real-time communication
-   Service isolation
-   Data sovereignty (100% on-premise)
-   Scalable modular growth

------------------------------------------------------------------------

## 🏗️ Architecture

NeuroSystem follows a **Local Microservices-Oriented Architecture**
(modular distributed by port).

### Core Principles

-   Each module runs independently on its own logical port
-   Unified shared database
-   Isolated deployment per service
-   Failure containment between modules
-   Centralized entry point via Portal Gateway

### High-Level Flow

    User
      ↓
    Portal Gateway (Dashboard)
      ↓
    ----------------------------------------
    NeuroChat  |  NeuroAgenda  |  Support TI
    :3000      |  :3002        |  :3001
    ----------------------------------------
              ↓
         Shared MySQL Database

------------------------------------------------------------------------

## 🧩 Portal Gateway

The Portal acts as:

-   Single entry point
-   Service availability monitor
-   Unified navigation dashboard
-   Glassmorphism-based UI interface

------------------------------------------------------------------------

## 🚀 Modules

### 📡 Communication & Core

#### 💬 NeuroChat (Port 3000)

Real-time communication engine powered by WebSockets.

-   Instant messaging
-   Internal notifications
-   Core database engine

#### 🌐 Portal Central

Service orchestration and navigation control.

------------------------------------------------------------------------

### 👥 Human Resources

#### 👔 NeuroRH

Employee portal including:

-   Corporate announcements
-   Vacation requests
-   Document management
-   Internal policies

#### 📢 Ouvidoria

Structured feedback channel integrated with internal routing.

------------------------------------------------------------------------

### ⚙️ Operations & Logistics

#### 🚗 NeuroCar (Port 3003)

Fleet management system:

-   Vehicle check-in/out
-   Mileage tracking
-   Usage history

#### 📅 NeuroAgenda (Port 3002)

Asset and room reservation system with conflict prevention.

#### 🛠️ Support TI (Port 3001)

Internal HelpDesk system:

-   Ticket classification
-   SLA management
-   Full ticket lifecycle history

------------------------------------------------------------------------

### 📊 Supplies & Marketing

#### 🛒 NeuroCompras

Procurement request and approval workflow.

#### 🖨️ NeuroPrint

Print demand management.

#### 🎨 SolicitaMKT

Marketing workflow request system.

------------------------------------------------------------------------

## 🛠️ Technology Stack

  Layer       Technology            Role
  ----------- --------------------- -----------------------------
  Backend     Node.js / Laravel     APIs & Business Logic
  Frontend    Vanilla JS / Blade    UI Rendering
  Real-Time   Socket.io             Bidirectional Communication
  Database    MySQL / MariaDB       Unified Persistence
  Styling     CSS3 (Grid/Flexbox)   Responsive UI

------------------------------------------------------------------------

## 🔧 Environment Setup

### Requirements

-   Node.js v18+
-   PHP 8.1+
-   MySQL / MariaDB
-   Apache or Nginx
-   npm or yarn

------------------------------------------------------------------------

## 🗄️ Data Strategy

All modules share a centralized database using logical schema separation
to ensure:

-   Referential integrity
-   Identity consistency
-   Reduced redundancy
-   Simplified maintenance

------------------------------------------------------------------------

## 🎯 Architectural Decisions

-   On-Premise deployment for data sovereignty
-   Port-based isolation to prevent global downtime
-   Shared database to simplify identity management
-   WebSockets for real-time experience
-   Modular scalability for future expansion

------------------------------------------------------------------------

## 📈 Future Improvements

-   Docker containerization
-   Centralized SSO authentication
-   API Gateway formalization
-   Structured logging & monitoring
-   CI/CD pipeline integration

------------------------------------------------------------------------

## 👨‍💻 Author

**Marcus Bandeira Morais**\
IT Analyst \| Systems Developer\
Specialized in Internal Systems Architecture & Process Automation

------------------------------------------------------------------------

```{=html}
<p align="center">
```
`<i>`{=html}Enterprise-grade internal systems built with modular
intelligence.`</i>`{=html}
```{=html}
</p>
```
