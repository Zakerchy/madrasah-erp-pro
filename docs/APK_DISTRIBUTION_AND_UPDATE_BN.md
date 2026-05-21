# APK Distribution এবং Update Flow (Bangla)

## 1) APK কোথায় পাবেন
এই repo-তে APK source file committed থাকে না।
APK পাওয়া যাবে GitHub থেকে:
1. `Actions` -> `build-android-apk` workflow success হলে
2. `Releases` -> `latest-apk` tag এ
3. `app-debug.apk` download করে mobile-এ install করুন

## 2) Push দিলে কি হয়
- Branch `main` এ push হলেই workflow auto run করে
- Workflow Flutter Android scaffold না থাকলে auto generate করে
- তারপর APK build করে release update করে

## 3) কেন আগে APK দেখা যাচ্ছিল না
- লোকাল machine-এ `flutter` command নেই
- Repo-তে `mobile-app/android` folder tracked ছিল না
- তাই local build সম্ভব হয়নি; CI workflow কে auto scaffold-ready করা হয়েছে

## 4) App open করলে auto update হবে কি?
সত্য অবস্থা:
- Side-loaded APK (GitHub থেকে install) Android নিজে নিজে silently replace করতে দেয় না
- user confirmation ছাড়া full silent install policy-wise possible না

Best practical options:
1. **Google Play distribution** (recommended): In-App Update API দিয়ে app open এ update prompt/flexible update
2. **GitHub release distribution**: app open এ "new version available" check + download/install prompt (manual confirmation লাগবে)

## 5) Next upgrade path (recommended)
1. একই signing key দিয়ে release APK build pipeline
2. version code/version name auto bump
3. app-open update checker (GitHub release বা Play track)
4. update prompt screen with one-tap download

## 6) Current decision
- Build/release automation ready করা হয়েছে
- True silent auto-update (no user action) side-loaded mode এ feasible না
- Play-based বা prompt-based updater next phase এ করা হবে
