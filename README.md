# NexusV2 Dev - Master Repository

Welcome to the root repository for the **NexusV2** project. This repository acts as the central hub, containing the master documentation and linking the Frontend and Backend repositories via Git Submodules.

## 📂 Repository Structure
This project is decoupled into independent repositories to maintain clean development lifecycles:

- **[NexusV2Dev_Frontend](https://github.com/onooinc-code/NexusV2Dev_Frontend)** (`/Nexus-Frontend`): Next.js/React Application.
- **[NexusV2Dev_Backend](https://github.com/onooinc-code/NexusV2Dev_Backend)** (`/Nexus-backend`): Laravel API and AI Orchestration Engine.
- **`/NexusV2_Docs`**: The central brain and technical documentation for the entire project.
- **`/NexusDev`**: Specific execution plans, missing requirements, and AI methodology guides.

## ⚙️ Initializing the Project Locally
When you clone this master repository, the submodules (`Nexus-Frontend` and `Nexus-backend`) will initially be empty. You must initialize them:

```bash
git clone https://github.com/onooinc-code/NexusV2Dev.git
cd NexusV2Dev
git submodule update --init --recursive
```

## 🧠 Developing with AI (Antigravity / Cursor)
To prevent the AI from mixing frontend and backend contexts:
1. Do not open this root repository directly in your IDE for coding.
2. Use a **Multi-root Workspace** (`Nexus.code-workspace`) to open `Nexus-Frontend` and `Nexus-backend` as separate root folders.
3. Always instruct the AI to read the context files inside `NexusDev/` before making architectural changes.
