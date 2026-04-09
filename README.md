# 👨🏻‍🚀 Git Profile Manager (Interactive Git Bash Prompt)

> A smart and beginner-friendly Bash profile script to manage multiple Git identities, auto-load SSH keys, and jump into your projects — all from one beautiful terminal experience.

---

## ✨ Features

- 🔐 **Switch Git identity** across unlimited accounts with one dynamic menu
- 🔑 **Auto-load SSH keys** for each profile
- ➕ **Add, edit, or remove accounts** via guided wizard — no code changes needed
- 📁 **Choose or create projects** from organized GitHub folders
- 🌿 **Switch or create branches** right after opening a repo
- 🧪 **Warns about uncommitted changes** before switching projects
- ❓ **Built-in Git command reference** (status, commit, branches, sync, undo, SSH)
- ⏸️ **Autorun toggle** — enable or disable the menu on terminal open
- 💬 Friendly CLI messages & emoji-enhanced UX
- ✅ Fully compatible with **Git Bash on Windows**

---

## 🗂️ File Structure

```
git-profile-manager/
├── bash_profile          ← entry point (source this in ~/.bash_profile)
├── bash_profile_v1.sh    ← original v1 archive (reference only)
├── .gitignore
└── lib/
    ├── prompt.sh         ← terminal prompt rendering
    ├── config.sh         ← account config read/write helpers
    ├── accounts.sh       ← dynamic account menu
    ├── projects.sh       ← project selector
    ├── branches.sh       ← branch switcher / creator
    ├── setup.sh          ← add / edit / remove account wizards
    └── help.sh           ← git command reference

~/.git-profile-manager/   ← private config (auto-created, outside repo)
└── config.sh             ← your accounts (never committed)
```

---

## 🛠️ Setup Instructions (Beginner Friendly)

### 1. ✅ Requirements

- Git Bash installed — [Git for Windows](https://git-scm.com)
- SSH key pairs for each GitHub account (the setup wizard can generate these for you)

---

### 2. 📄 Install the Script

1. Clone or download this repo to a permanent location, for example:
   ```
   /a/YOUR-PATH/git-profile-manager/
   ```

2. Open Git Bash and edit your profile:
   ```bash
   nano ~/.bash_profile
   ```

3. Add this line (adjust the path to match where you cloned the repo):
   ```bash
   source "/a/YOUR-PATH/git-profile-manager/bash_profile"
   ```

4. Save: `CTRL + O`, `ENTER`, then exit: `CTRL + X`

5. Apply changes:
   ```bash
   source ~/.bash_profile
   ```

On **first run**, the script auto-generates your config file at `~/.git-profile-manager/config.sh` with two starter accounts (personal + work). You can edit or replace them via the Settings menu.

---

### 3. 🗂️ GitHub Folder Layout

Organize your projects like this (adjust company names as needed):

```
/a/COMPANIES/
├── PERSONAL-COMPANY/
│   └── GITHUB/
│       ├── my-personal-project/
│       └── git-profile-manager/
└── WORK-COMPANY/
    └── GITHUB/
        ├── project-one/
        └── project-two/
```

Each account points to one GitHub root folder. The project selector automatically detects subfolders that contain a `.git` directory.

---

### 4. 🔑 Add SSH Keys

#### Option A — Use the built-in wizard (recommended)
Open the account menu → `s` Settings → `1` Add new account.  
The wizard will optionally run `ssh-keygen` for you and print the public key to paste into GitHub.

#### Option B — Manual
```bash
# Personal
ssh-keygen -t ed25519 -C "your.personal@email.com" -f ~/.ssh/id_ed25519_personal
cat ~/.ssh/id_ed25519_personal.pub

# Work
ssh-keygen -t ed25519 -C "your.work@email.com" -f ~/.ssh/id_ed25519_work
cat ~/.ssh/id_ed25519_work.pub
```

Paste each public key into [GitHub → Settings → SSH Keys](https://github.com/settings/keys).

---

## 🚀 Example Usage

### Opening a new terminal

```
Hello, Jorge. What a beautiful Wednesday!!! 🐢

───────────────────────────────────────────────────────────
🔐 Select GitHub Profile:
  1) 🏡 PERSONAL
  2) 🏢 WORK
  ─────────────────────────────
  s) ⚙️  Settings
  h) ❓ Help
  0) 🌄 Exit
#? 2

✅ SSH key loaded: id_ed25519_work
✅ Git identity set: your-username <your.email@company.com>

📁 Base folder: /a/COMPANIES/WORK-COMPANY/GITHUB
───────────────────────────────────────────────────────────
🧭 Controls: [number]=open  /text=search  /=clear  b=back  r=root  c=create  0=exit

  1) 💽  project-one                     (main)  🟢 clean
  2) 💽  project-two                     (dev)   🔴 dirty (3)

Enter your choice: 1

📂 Switched to: project-one

🌿 Branch actions for: project-one (current: main)
  1) 🌿 Switch branch
  2) ➕ Create new branch
  3) ✅ Stay on main
#? 3

✅ Staying on branch: main
```

---

## ⚙️ Adding a New Account

```
s) Settings → 1) Add new account

1️⃣  Account label: Freelance
2️⃣  Git username: JorgeFree
3️⃣  Git email: your.email@freelance.com
4️⃣  SSH key filename [id_ed25519_freelance]:
5️⃣  GitHub root folder path: /a/COMPANIES/FREELANCE-COMPANY/GITHUB
6️⃣  Generate SSH key now? [y/N]: y

🔑 Generating SSH key...
📋 Your public key — paste into GitHub → Settings → SSH Keys:
───────────────────────────────────────────────────────────
ssh-ed25519 AAAA... your.email@freelance.com
───────────────────────────────────────────────────────────
Press Enter when done...

✅ Account 'Freelance' saved as account #3.
```

---

## 🛣️ Useful Commands

| Command | Description |
|---|---|
| `am` | Open the account menu |
| `git-whoami` | Show current Git identity |
| `select_branch` | Open branch switcher for the current repo |
| `gpm-disable` | Disable the menu auto-launching on terminal open |
| `gpm-enable` | Re-enable auto-launch |

---

## 🧪 Git Status Check

If you have uncommitted changes and navigate away from a repo, the tool warns you:

```
⚠️  Commit reminder: Your CURRENT repo has uncommitted changes:
 M  src/index.js
?? notes.txt

💡 To commit now:
   git add -A
   git commit -m "<message>"

✅ Commits are local — only 'git push' needs GitHub/SSH.
```

---

## 🔐 Security

- SSH keys live in `~/.ssh/` — **outside this repo**, never tracked by git
- Account config lives in `~/.git-profile-manager/` — **outside this repo**, never tracked by git
- `.gitignore` in this repo blocks accidental credential commits (`*.pem`, `*.key`, `*.pub`, `*.env`, etc.)

---

## 😎 Author

**Jorge Briceño**  
jorgeebricenom@gmail.com  
Last updated: 2026-04-09  
Feedback? PRs welcome 🤘🏻

---

## 📄 License

[MIT](./LICENSE)
