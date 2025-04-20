# 👨🏻‍🚀 Git Profile Manager (Interactive Git Bash Prompt)

> A smart and beginner-friendly Bash profile script to manage multiple Git identities, auto-load SSH keys, and jump into your projects — all from one beautiful terminal experience.

---

## ✨ Features

- 🔐 **Switch Git identity** (personal/work/none) with one menu
- 🔑 **Auto-load SSH keys** for each GitHub profile
- 📁 **Choose or create projects** from organized GitHub folders
- 🧪 **Warns if there are uncommitted Git changes** before switching projects
- 💬 Friendly CLI messages & emoji-enhanced UX
- ✅ Fully compatible with **Git Bash on Windows**

---

## 🛠️ Setup Instructions (Beginner Friendly)

### 1. ✅ Requirements

- Git Bash installed (use [Git for Windows](https://git-scm.com))
- SSH key pairs for each GitHub account:
  - `~/.ssh/id_ed25519_personal`
  - `~/.ssh/id_ed25519_work`

---

### 2. 📄 Install the Script

1. Open Git Bash  
2. Run:
```bash
nano ~/.bash_profile
```
3. Paste the contents of `bash_profile` from this repo
4. Save: `CTRL + O`, `ENTER`, then exit with `CTRL + X`
5. Apply changes:
```bash
source ~/.bash_profile
```

---

### 3. 🗂️ Folder Structure

Example layout (adjust paths as needed):

```
/a/COMPANIES/
├── COMPANY NAME/
│   └── GITHUB/
│       ├── AD-Testing/
│       └── Demo-AG/
└── CONSULTING/
    └── GITHUB/
        └── My-Personal-Project/
```

---

### 4. 🔑 Add Your SSH Keys

#### Personal:
```bash
ssh-keygen -t ed25519 -C "your.personal@email.com" -f ~/.ssh/id_ed25519_personal
cat ~/.ssh/id_ed25519_personal.pub
```

#### Work:
```bash
ssh-keygen -t ed25519 -C "your.work@email.com" -f ~/.ssh/id_ed25519_work
cat ~/.ssh/id_ed25519_work.pub
```

Paste the keys in [GitHub SSH settings](https://github.com/settings/keys).

---

## 🚀 Example Usage

```bash
$ source ~/.bash_profile
Hello, [User Name]. What a beautiful Sunday!!! 🐢

🔐 Which SSH key would you like to use this session?
1) personal
2) work
3) none
#? 2

✅ Work SSH key loaded.
✅ Git is now set to use your WORK account.
📁 Detected base GitHub folder: /a/COMPANIES/APPLY DIGITAL/GITHUB
🗃️  Let's choose a project (or skip)...

1) ApplyDigital-Testing
2) ❌ No project - stay here
3) ➕ Create new project folder
```

## 🛣️ In case you want to change the project in the current account, type and run: 

```bash
select_project


---

## 🧪 Git Status Check

If you have uncommitted changes and try to switch projects, it will warn you:

```bash
⚠️ Uncommitted changes detected...
❗ Switch projects anyway? (y/n):
```


---

## 📂 File Structure

```
.
├── README.md
└── bash_profile
```

---

## 🙌 Author

**Jorge Briceño**
jorgeebricenom@gmail.com  
Last updated: 2025-04-20  
Feedback? PRs welcome 🤘🏻

---

## 📄 License

[MIT](./LICENSE)
