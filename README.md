# gitops-ai-zsh

AI-powered Git helper for Zsh that

- stages all changes,
- generates a **Conventional Commit** message with OpenAI GPT-4o-mini,
- pulls the latest changes with `--rebase`, and
- pushes in one tidy command: **`gitops`**.

---

## ✨ Features

- **Conventional Commit, single-line** messages – types: build / chore / ci / docs / feat / fix / perf / refactor / revert / style / test.
- **Scope auto-detected** from the remote URL (`org/project.git` ➡️ scope=`(ORG)`).
- **OpenAI fallback** – if the API call fails, falls back to `chore(scope): auto-commit`.
- Cap at the first 400 diff lines so you keep token usage predictable.

---

## 🚀 Installation

### oh-my-zsh

```zsh
git clone https://github.com/petitbon/gitops-ai-zsh.git $ZSH_CUSTOM/plugins/gitops-ai-zsh
plugins+=(gitops-ai-zsh)   # add to your ~/.zshrc
source ~/.zshrc
```
