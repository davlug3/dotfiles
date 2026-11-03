# Architecture Decision Record (ADR): Manifest-Driven Dependency Management
**Status:** Accepted
**Date:** 2026-11-03
**Authors:** AI Agent

## 📖 Context
The initial dotfiles repository contained numerous hardcoded, procedural scripts (`run_once_*`, `installers/*`) responsible for installing and configuring external dependencies (e.g., `ripgrep`, `starship`, `lilypond`). This approach was brittle, difficult to maintain, and prone to inconsistency across different operating systems or deployment environments.

## 🎯 Decision
We are refactoring the entire dependency management system into a single, declarative model governed by a central manifest file (`manifest/dependencies.yaml`) and an execution handler (`handlers/package_handler.sh`).

**The core principle:** Installation logic should *declare* what is needed (Manifest) and *how* to do it (Handler), rather than being embedded procedurally in every bootstrap script.

## ✨ Changes Implemented
1.  **Central Manifest (`manifest/dependencies.yaml`):** This file is now the single source of truth for all required packages, listing both the package name and its installation type (e.g., `standalone-binary`, `apt`).
2.  **Generic Handler (`handlers/package_handler.sh`):** A new module was created to read the manifest, iterate over dependencies, and dispatch control flow to specific, abstracted installation functions (`install_package`). This abstracts away the "how."
3.  **Installer Cleanup:** All primary entry point scripts (`installers/install-*.sh`, `installers/install-*.ps1`) have been stripped of their internal logic. They now function merely as wrappers that source and execute the central handler using the manifest file.

## ⚙️ New Workflow Diagram (Conceptual)
`[Bootstrap Script] -> sources handlers/package_handler.sh -> process_manifest() [Manifest] -> calls install_package(pkg, type)`

### Key Improvements & Benefits
*   **Maintainability:** Adding a new dependency requires only updating the manifest and potentially adding logic to `handlers/package_handler.sh`. No core scripts need modification.
*   **Auditability:** The system state is immediately visible by inspecting `manifest/dependencies.yaml`.
*   **Consistency:** All platform-specific installation failures or successes are funneled through one controlled point, making debugging reliable.

## ⚠️ Limitations & Follow-Up Actions (Next Steps)
1.  **Manifest Parsing:** Currently, the YAML parsing within `handlers/package_handler.sh` is stubbed. This must be fully implemented to read complex data structures from `manifest/dependencies.yaml`.
2.  **Template Integration:** The logic for updating `run_once_*` templates to call `process_manifest()` needs to be completed across all remaining files (e.g., the template scripts that auto-execute).
3.  **Error Handling Polish:** Improve error reporting in the handler to provide clearer context when a dependency installation fails, guiding the user on how to fix it.

This ADR documents the architectural shift and provides clear next steps for continuous improvement.