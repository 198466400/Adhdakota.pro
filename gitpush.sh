#!/data/data/com.termux/files/usr/bin/bash

# === Termux Auto-Push (SSH, Safe Version) ===

# Ensure SSH key exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key missing. Generate with: ssh-keygen -t ed25519 -C 'dakota@example.com'"
    exit 1
fi

# Fix corrupted global config
git config --global user.name "Dakota"
git config --global user.email "dakota@example.com"

# Enter project
cd ~/Adhdakota.pro || exit

# Ensure remote is correct
git remote remove origin 2>/dev/null
git remote add origin git@github.com:198466400/Adhdakota.pro.git

# Stage everything
git add .

# Commit with timestamp
git commit -m "Auto-push $(date '+%Y-%m-%d %H:%M:%S')" || echo "Nothing to commit."

# Force branch name to main
git branch -M main

# Push (SSH, zero prompts)
git push -u origin main --force
