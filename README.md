<p align="center">
  <h1 align="center">🛡️ Git Shield</h1>
  <p align="center">
    <strong>Universal, Automated Malware & Backdoor Protection for Git Repositories</strong><br>
    Stop GitHub supply chain attacks, fake interview trojans, disguised font scripts, and VS Code auto-run exploits before they execute on your machine.
  </p>
  <p align="center">
    <img src="https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue?style=for-the-badge&logo=apple&logoColor=white" alt="Platforms">
    <img src="https://img.shields.io/badge/Protection-Lazarus%20%2F%20BeaverTail-red?style=for-the-badge&logo=security" alt="Protection">
    <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License">
    <a href="https://github.com/ranasheikh64/git-shield/stargazers"><img src="https://img.shields.io/github/stars/ranasheikh64/git-shield?style=for-the-badge&color=yellow" alt="Stars"></a>
  </p>
</p>

---

## ⚡ 1-Line Instant Installation

Run **one single command** in your terminal. Git Shield will permanently configure your machine — every time you run `git pull` or `git checkout` in **any** repository, it will automatically scan, neutralize, and clean all threats!

### 🍏 macOS & 🐧 Linux
```bash
curl -fsSL https://raw.githubusercontent.com/ranasheikh64/git-shield/main/install.sh | bash
```

### 🪟 Windows (PowerShell - Run as Administrator or Standard User)
```powershell
irm https://raw.githubusercontent.com/ranasheikh64/git-shield/main/install.ps1 | iex
```

---

## 🚨 The Threat: How Developers Are Being Hacked Today

Recent global cyber campaigns (known as **Lazarus / BeaverTail / Contagious Interview**) specifically target software engineers, web3 developers, and open-source contributors using poisoned GitHub repositories.

### ⚠️ The Attack Pattern:
1. **The Poisoned Pull:** When you clone or pull a repo from GitHub, the attacker slips in malicious configuration files.
2. **Auto-Execution on Folder Open:** 
   ```json
   // .vscode/settings.json
   {
     "task.allowAutomaticTasks": true
   }
   ```
   Combined with:
   ```json
   // .vscode/tasks.json
   {
     "tasks": [{
       "label": "eslint-check",
       "command": "node",
       "args": ["./public/fonts/fa-solid-300.ttf"],
       "runOptions": { "runOn": "folderOpen" }
     }]
   }
   ```
3. **Disguised Script (`fa-solid-300.ttf`):** It looks like a Font Awesome `.ttf` font file, but it is actually a **22KB obfuscated JavaScript info-stealer**.
4. **Ethereum Dead-Drop Resolver & C2:** It connects to Ethereum RPC nodes to dynamically resolve the attacker's Command & Control (C2) server, downloads a second-stage stealer into `~/.node_modules/`, and spawns a background daemon that siphons:
   - 🔑 Saved browser passwords & active login cookies
   - 💼 Crypto wallet extensions (MetaMask, Phantom, etc.)
   - 🐙 GitHub Personal Access Tokens & SSH keys
   - 📄 Local `.env` secrets and API credentials

---

## 🖥️ Visual Detection & Output

### 🚨 When a threat is detected during `git pull`:
```bash
$ git pull origin main
Updating 147996e..fb3ddf6
Fast-forward
 .vscode/tasks.json             | 25 +++++++++++++++++++++++++
 public/fonts/fa-solid-300.ttf  |  1 +
 server/init                    | 30 +++++++++++++++++++++++++

🛡️  [Git Shield] Scanning repository for malicious files, backdoors, and auto-run exploits...
🚨 [ALERT] Malicious .vscode/tasks.json detected! (Attempts silent execution on folder open)
🚨 [ALERT] Trojan script disguised as font/image: ./public/fonts/fa-solid-300.ttf! Deleting...
🚨 [ALERT] Obfuscated backdoor loader detected in: server/init! Deleting...
🚨 [ALERT] Terminating rogue background process(es): 766
⚠️  [Git Shield] Warning: Neutralized and cleaned 4 malicious threat(s).
```

### ✅ When your repository is clean:
```bash
$ guard-repo
🛡️  [Git Shield] Scanning repository for malicious files, backdoors, and auto-run exploits...
✅ [Git Shield] Repository is 100% clean and safe.
```

---

## 🛡️ What Git Shield Does Under the Hood

| Protection Feature | How Git Shield Protects You |
| :--- | :--- |
| **Global Git Hook** | Uses `core.hooksPath` so **every project** on your PC is automatically defended on `git pull` & `git checkout`. |
| **Disguised Media Check** | Inspects `.ttf`, `.png`, `.svg`, `.woff` files to verify they are real binaries, not disguised JavaScript or bash scripts. |
| **Task Hijack Neutralization** | Instantly purges `.vscode/tasks.json` with `runOn: folderOpen` and strips malicious `task.allowAutomaticTasks`. |
| **IDE Hardening** | Automatically updates VS Code, Cursor, and VSCodium User Settings to force `"task.allowAutomaticTasks": "off"`. |
| **Lifecycle Hook Sanitization** | Scans `package.json` for suspicious `preinstall` or `postinstall` commands. |
| **Process Killer** | Detects and kills active stealth node/python background processes connected to known C2 patterns. |

---

## 🛠️ Manual Usage

You can manually scan any directory at any time:

```bash
# macOS / Linux
guard-repo

# Windows (PowerShell)
& "$HOME\.git-shield\guard-repo.ps1"
```

---

## 🗑️ Uninstallation

If you ever need to uninstall Git Shield:

### macOS / Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/ranasheikh64/git-shield/main/uninstall.sh | bash
```

### Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/ranasheikh64/git-shield/main/uninstall.ps1 | iex
```

---

## ⭐ Support & Star

If **Git Shield** saved your project or machine from being compromised, please **give this repo a Star (⭐)** and share it with fellow developers!

- **Author:** [Rana Sheikh (@ranasheikh64)](https://github.com/ranasheikh64)
- **Report Threats:** If you encounter new attack patterns, please open an Issue or Pull Request.

---

## 📄 License

Distributed under the [MIT License](LICENSE). Free for open-source and commercial use.
