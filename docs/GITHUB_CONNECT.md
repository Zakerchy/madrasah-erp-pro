# GitHub Connect and Push

## Current State
- Git repo initialized
- Local repo path:
  `/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-pro`
- Remote configured as:
  `https://github.com/Zakerchy/madrasah-erp-lite.git`
- `git push` is working on `main`
- Local folder name is now `madrasah-erp-pro`, but the GitHub repository name is still `madrasah-erp-lite`

## Current Recommendation
Keep using the current remote until you rename or recreate the GitHub repository on the web.
If you later create `madrasah-erp-pro` in GitHub, then update the remote with:
```bash
git remote set-url origin https://github.com/Zakerchy/madrasah-erp-pro.git
```

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
A workflow is already added at:
- `.github/workflows/local-check.yml`

It runs on push and weekly schedule to validate migration + local smoke flow.

## Full automation workflows
- Backend auto deploy: `.github/workflows/deploy-apps-script.yml`
- Android APK auto build: `.github/workflows/android-apk.yml`

Required GitHub Secrets for full automation:
- `CLASPRC_JSON`
- `APPS_SCRIPT_SCRIPT_ID`
- `APPS_SCRIPT_DEPLOYMENT_ID`
- `APPS_SCRIPT_URL` (preferred)
- `API_BASE_URL` (legacy fallback)
