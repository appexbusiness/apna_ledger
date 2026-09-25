Firebase Android config files (staged).

Place per Android flavor after `flutter create`:
  google-services-qa.json    ->  android/app/src/qa/google-services.json
  google-services-prod.json  ->  android/app/src/prod/google-services.json

QA project   : apnaledgerqa        (com.appexbusiness.apnaledgerqa)
Prod project : apnaledger-38818    (com.appexbusiness.apnaledger)

iOS GoogleService-Info.plist is not included — generate via `flutterfire configure`.
See FIREBASE_AND_BUILD_SETUP.md at the repo root for full steps.
