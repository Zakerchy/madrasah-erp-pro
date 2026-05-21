# ফুল অটোমেশন সেটআপ (একবার করলেই হবে)

আপনার সমস্যা ঠিক: বারবার Apps Script এ paste করা লাগা উচিত না।
এই সেটআপের পর:
- `backend-apps-script` এ code change + `git push` দিলে backend auto deploy হবে
- যেকোনো `git push` এ APK auto build হবে
- `latest-apk` release এ সবসময় সর্বশেষ APK replace হবে

## কী কী একবারই করতে হবে

## ধাপ 1) Apps Script project তৈরি (শুধু একবার)
1. `script.google.com` -> `New project`
2. project name দিন: `Madrasah ERP Lite Backend`
3. `Project Settings` থেকে `Script ID` কপি করুন (পরে secret এ লাগবে)
4. `Code.gs` এ [backend-apps-script/Code.gs](/Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite/backend-apps-script/Code.gs) paste করুন
5. `Code.gs` এ placeholder রেখেই দিন (CI থেকে secret দিয়ে auto bind হবে)
6. `Deploy -> New deployment -> Web app` করুন
7. deployment create হলে `Deployment ID` আর `Web app URL` কপি করুন

## ধাপ 2) local থেকে clasp auth token বের করা (শুধু একবার)
টার্মিনালে:
```bash
npm i -g @google/clasp
clasp login
cat ~/.clasprc.json
```
`~/.clasprc.json` এর পুরো JSON কপি করুন (এটাই `CLASPRC_JSON` secret হবে)

## ধাপ 3) GitHub secrets দিন (শুধু একবার)
Repo -> `Settings` -> `Secrets and variables` -> `Actions` -> `New repository secret`

এই 5টা secret দিন:
1. `CLASPRC_JSON` = `~/.clasprc.json` এর full JSON
2. `APPS_SCRIPT_SCRIPT_ID` = script settings থেকে script id
3. `APPS_SCRIPT_DEPLOYMENT_ID` = web app deployment id
4. `API_BASE_URL` = web app url (`.../exec`)
5. `GOOGLE_SHEET_ID` = আপনার production Google Sheet ID

## ধাপ 4) অটোমেশন কাজ করছে কি না test
1. backend file এ ছোট change করে push দিন
2. GitHub -> Actions -> `deploy-apps-script` success দেখুন
3. যেকোনো file এ ছোট change করে push দিন
4. GitHub -> Actions -> `build-android-apk` success দেখুন
5. GitHub -> Releases -> `latest-apk` এ নতুন APK দেখতে পাবেন

---

## এরপর থেকে update flow (আর paste না)
1. code change
2. commit
3. push

এই 3টার পর বাকিটা auto:
- backend deploy auto (sheet id secret থেকে auto bind)
- apk build auto
- latest-apk release auto update

## Useful commands
```bash
cd /Users/zakerchy/Desktop/MadrasahApp/madrasah-erp-lite
git add .
git commit -m "update: <message>"
git push
```
