# 🔄 Git Workflow Guide — Kelompok 2

**Repository**: https://github.com/ErsyaHasby/PCD_TUBES_COBA  
**Main Branch**: `main` (production-ready)  
**Development**: Feature branches per task

---

## 📋 Setup (First Time Only)

### 1️⃣ Clone Repository
```bash
git clone https://github.com/ErsyaHasby/PCD_TUBES_COBA.git
cd PCD_TUBES_COBA
```

### 2️⃣ Configure Git User (Lokal)
```bash
git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### 3️⃣ Verify Remote
```bash
git remote -v
# Should output:
# origin  https://github.com/ErsyaHasby/PCD_TUBES_COBA.git (fetch)
# origin  https://github.com/ErsyaHasby/PCD_TUBES_COBA.git (push)
```

---

## 🌳 Branch Naming Convention

**Format**: `feature/[task-id]-[developer-name]-[brief-description]`

**Examples**:
```
feature/task-1.1-alexandrio-tflite-setup
feature/task-1.2-ersya-camera-integration
feature/task-1.3-muhammad-onboarding-screens
feature/task-1.4-varian-database-sync
```

---

## 🔄 Workflow Per Task

### Step 1: Buat Feature Branch
```bash
# Asumsikan Anda adalah Ersya (task 1.2 - Camera Integration)
git checkout main
git pull origin main  # Pastikan sudah latest
git checkout -b feature/task-1.2-ersya-camera-integration
```

### Step 2: Develop & Commit
**Golden Rules**:
- ✅ Commit sering (1-2 kali per jam jika ada progress)
- ✅ Pesan commit harus deskriptif dan atomic
- ✅ Jangan commit file besar (>50 MB)

**Contoh Commit**:
```bash
git add app/lib/core/services/pcd_pipeline.dart

# Format commit: [TASK-X.X] [Name] Description
git commit -m "[TASK-1.2] [Ersya] Implement YUV to RGB color conversion

- Add YUV420 decoding for Android
- Add BGRA handling for iOS
- Tested on device with 30 FPS performance"
```

### Step 3: Periodic Push
```bash
# Push ke remote setiap hari atau setelah major milestone
git push -u origin feature/task-1.2-ersya-camera-integration
```

### Step 4: Create Pull Request (PR)
Ketika task selesai:

1. **Go to GitHub**: https://github.com/ErsyaHasby/PCD_TUBES_COBA/pulls
2. **Click "New Pull Request"**
3. **Base**: `main` ← **Compare**: `feature/task-1.2-ersya-camera-integration`
4. **Title**: `[TASK-1.2] Camera Integration - Real PCD Pipeline`
5. **Description** (gunakan template di bawah):

```markdown
## Description
Implementasi camera integration dengan real PCD pipeline.

## Changes
- [x] YUV420 to RGB conversion (Android)
- [x] Center crop dengan dynamic aspect ratio
- [x] Resize ke 224×224
- [x] Float32 normalisasi
- [x] Benchmark: ~30 FPS pada mid-range device

## Testing
- [x] Tested on Android emulator
- [x] Tested on physical device (Redmi Note 10)
- [x] No memory leaks detected

## Checklist
- [x] Code follows project style guide
- [x] Added comments for complex logic
- [x] No console warnings/errors
- [x] Ready for merge to main

## Related Issue
Closes #NA (or reference TASK_BREAKDOWN.md)
```

6. **Request Reviewers**: Pilih 1-2 orang dari tim
7. **Wait for Approval** sebelum merge

### Step 5: Merge ke Main
**IMPORTANT**: Jangan merge sendiri. Tunggu minimal 1 review approval.

Setelah approved:
- Click "Merge Pull Request"
- Pilih "Squash and merge" untuk clean history
- Delete branch after merge

### Step 6: Back to Main
```bash
git checkout main
git pull origin main
# Sekarang siap mulai task berikutnya
```

---

## 🚨 Common Issues & Solutions

### ❌ "Your branch is ahead of origin/main by X commits"
```bash
# Berarti ada commit local yang belum di-push
git push origin <branch-name>
```

### ❌ "Merge conflict"
Ketika merge dari main ke feature branch:
```bash
git checkout feature/task-X.X-...
git pull origin main

# Resolve conflicts secara manual
# Di file yang conflict, hapus marker (<<<<, ====, >>>>)
# Keep yang versi yang benar

git add .
git commit -m "[RESOLVE] Merge conflict from main"
git push origin feature/task-X.X-...
```

### ❌ "Large files detected"
```bash
# Jangan commit file >50 MB
# Gunakan .gitignore untuk exclude:
# - Build artifacts (build/, .gradle/)
# - Binary files (*.hprof, *.exe)
# - Node modules (node_modules/)

# Jika sudah commit, remove dari history:
git rm --cached <file>
git commit --amend --no-edit
git push -u origin <branch>
```

---

## 📊 Branch Status Dashboard

**How to check branch status**:
```bash
# List local branches
git branch -a

# Show branch info
git log --oneline --graph --all --decorate

# Show remote branches
git branch -r
```

---

## 👥 Code Review Process

### Untuk Reviewer:
1. **Read** PR description & related tasks
2. **Check** changes di tab "Files Changed"
3. **Request Changes** jika ada issue, atau
4. **Approve** jika sudah OK
5. **Leave Comment** dengan feedback constructive

### Untuk Developer (Reviewee):
1. **Address** feedback dari reviewer
2. **Push** changes baru ke branch (auto-update PR)
3. **Reply** ke comments untuk acknowledge
4. **Re-request review** setelah done

---

## 📅 Integration Timeline

| Minggu | Branch Main | Milestone |
|--------|-------------|-----------|
| **1-2** | 🔄 Active merges | Core Infrastructure |
| **2-3** | 🔄 Active merges | Inference Pipeline |
| **3-4** | 🔄 Active merges | Features & Services |
| **4+** | ✅ Stabilize | Testing & Release |

---

## 🔐 Important Rules

✅ **DO**:
- ✅ Sync dengan `git pull origin main` setiap pagi
- ✅ Push feature branch daily atau setiap major change
- ✅ Write descriptive commit messages
- ✅ Test locally sebelum push
- ✅ Ask for help jika stuck

❌ **DON'T**:
- ❌ Force push ke branch orang lain: `git push --force`
- ❌ Commit password, API keys, credentials
- ❌ Commit files >50 MB
- ❌ Merge ke main tanpa approval
- ❌ Delete branch orang lain

---

## 📞 Need Help?

**Git Cheat Sheet**: https://github.github.com/training-kit/downloads/github-git-cheat-sheet.pdf  
**Atlassian Git Tutorials**: https://www.atlassian.com/git/tutorials  
**Discord/Group Chat**: Ask team members anytime!

---

**Last Updated**: May 22, 2026  
**Status**: Ready for team collaboration ✓
