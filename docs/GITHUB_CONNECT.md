# GitHub Connect and Push

## Current State
- Git repo initialized
- Initial commit done
- Remote configured as:
  `https://github.com/Zakerchy/madrasah-erp-lite.git`
- Push failed because repository does not exist yet.

## Step 1: Create repository in GitHub
Create this repository in your GitHub account:
- Name: `madrasah-erp-lite`
- Visibility: Private or Public (your choice)

## Step 2: Push from terminal
Run:
```bash
cd /Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite
git push -u origin main
```

## Step 3: Future updates
After any change:
```bash
git add .
git commit -m "update: <short message>"
git push
```

## Auto checks in GitHub
A workflow is already added at:
- `.github/workflows/local-check.yml`

It runs on push and weekly schedule to validate migration + local smoke flow.
