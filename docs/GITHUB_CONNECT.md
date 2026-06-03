# GitHub Connect and Push

## Current State
- Git repo initialized
- Local repo path:
  `/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro`
- Remote configured as:
  `https://github.com/Zakerchy/madrasah-erp-pro.git`
- `git push` is working on `main`
- GitHub repository name is now `madrasah-erp-pro`

## Current Recommendation
Local folder, Git remote, and GitHub repository name are now aligned as `madrasah-erp-pro`.

## Push from terminal
Run:
```bash
cd /Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro
git push origin main
```

## Future updates
After any change:
```bash
git add .
git commit -m "update: <short message>"
git push
```

## Auto checks in GitHub
Relevant workflows:
- `.github/workflows/web-build-check.yml`
- `.github/workflows/android-apk.yml`
- `.github/workflows/deploy-apps-script.yml`

## Full automation workflows
- Backend auto deploy: `.github/workflows/deploy-apps-script.yml`
- Android APK auto build: `.github/workflows/android-apk.yml`

Required GitHub Secrets for full automation:
- `CLASPRC_JSON`
- `APPS_SCRIPT_SCRIPT_ID`
- `APPS_SCRIPT_DEPLOYMENT_ID`
- `APPS_SCRIPT_URL` (preferred)
- `API_BASE_URL` (legacy fallback)
