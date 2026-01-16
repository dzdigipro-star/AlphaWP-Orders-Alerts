# AlphaWP Orders - GitHub Build Instructions

## Quick Start

1. **Create a new GitHub repository**
   - Go to https://github.com/new
   - Name it `alphawp-orders-app` (or any name you want)
   - Make it **Private** (recommended)
   - Click **Create repository**

2. **Add your Firebase config**
   - You need to add `google-services.json` from Firebase
   - Go to Firebase Console → Project Settings → Your Android app
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`

3. **Push files to GitHub**
   Open a terminal in this `mobile-app` folder and run:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/alphawp-orders-app.git
   git push -u origin main
   ```

4. **Download your APK**
   - Go to your GitHub repo → **Actions** tab
   - Click on the latest workflow run
   - Scroll down to **Artifacts**
   - Download `alphawp-orders-release`
   - Extract and install the APK on your phone!

## Updating the App

Any time you push changes to the `main` branch, a new APK will be built automatically.

## Troubleshooting

- **Build failed**: Make sure `google-services.json` is in `android/app/`
- **Actions not running**: Enable Actions in repo Settings → Actions → General
