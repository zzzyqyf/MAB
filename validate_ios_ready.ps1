# iOS Readiness Validation Script for MAB Project
# Run this on Windows before pushing to GitHub for Codemagic build

Write-Host "`n🔍 MAB Project - iOS Readiness Check`n" -ForegroundColor Cyan

$allPassed = $true

# Test 1: Flutter environment
Write-Host "📱 Test 1: Flutter Environment" -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-String "Flutter" | Select-Object -First 1
    Write-Host "   ✅ Flutter installed: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Flutter not found or not in PATH" -ForegroundColor Red
    $allPassed = $false
}

# Test 2: Firebase config files
Write-Host "`n📱 Test 2: Firebase Configuration Files" -ForegroundColor Yellow
if (Test-Path "ios\Runner\GoogleService-Info.plist") {
    Write-Host "   ✅ GoogleService-Info.plist exists" -ForegroundColor Green
    $content = Get-Content "ios\Runner\GoogleService-Info.plist" -Raw
    if ($content -match "com\.example\.flutterApplicationFinal") {
        Write-Host "   ✅ Bundle ID matches: com.example.flutterApplicationFinal" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Bundle ID mismatch in GoogleService-Info.plist" -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "   ❌ GoogleService-Info.plist NOT FOUND" -ForegroundColor Red
    $allPassed = $false
}

# Test 3: Info.plist configuration
Write-Host "`n📱 Test 3: Info.plist Configuration" -ForegroundColor Yellow
if (Test-Path "ios\Runner\Info.plist") {
    $infoPlist = Get-Content "ios\Runner\Info.plist" -Raw
    
    $checks = @(
        @{Key="UIBackgroundModes"; Name="Background modes"},
        @{Key="FirebaseAppDelegateProxyEnabled"; Name="Firebase proxy"},
        @{Key="NSAppTransportSecurity"; Name="Network security"},
        @{Key="NSCameraUsageDescription"; Name="Camera permission"},
        @{Key="NSLocalNetworkUsageDescription"; Name="Local network permission"}
    )
    
    foreach ($check in $checks) {
        if ($infoPlist -match $check.Key) {
            Write-Host "   ✅ $($check.Name) configured" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $($check.Name) MISSING" -ForegroundColor Red
            $allPassed = $false
        }
    }
} else {
    Write-Host "   ❌ Info.plist NOT FOUND" -ForegroundColor Red
    $allPassed = $false
}

# Test 4: Podfile
Write-Host "`n📱 Test 4: Podfile Configuration" -ForegroundColor Yellow
if (Test-Path "ios\Podfile") {
    $podfile = Get-Content "ios\Podfile" -Raw
    
    $pods = @("Firebase/Core", "Firebase/Messaging", "Firebase/Auth", "Firebase/Firestore")
    foreach ($pod in $pods) {
        if ($podfile -match [regex]::Escape($pod)) {
            Write-Host "   ✅ $pod configured" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $pod MISSING" -ForegroundColor Red
            $allPassed = $false
        }
    }
    
    if ($podfile -match "platform :ios, '11.0'") {
        Write-Host "   ✅ iOS 11.0 platform set" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  iOS platform version may need verification" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ Podfile NOT FOUND" -ForegroundColor Red
    $allPassed = $false
}

# Test 5: Sound files
Write-Host "`n📱 Test 5: Alarm Sound Files" -ForegroundColor Yellow
if (Test-Path "assets\sounds\beep00000.mp3") {
    Write-Host "   ✅ beep00000.mp3 exists in assets" -ForegroundColor Green
} else {
    Write-Host "   ❌ beep00000.mp3 NOT FOUND in assets" -ForegroundColor Red
    $allPassed = $false
}

if (Test-Path "ios\Runner\Resources\beep.mp3") {
    Write-Host "   ✅ beep.mp3 copied to iOS Resources" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  beep.mp3 NOT FOUND in iOS Resources (may cause issues)" -ForegroundColor Yellow
    Write-Host "      Run: Copy-Item 'assets\sounds\beep00000.mp3' 'ios\Runner\Resources\beep.mp3'" -ForegroundColor Gray
}

# Test 6: FCM Service
Write-Host "`n📱 Test 6: FCM Service Implementation" -ForegroundColor Yellow
if (Test-Path "lib\shared\services\fcm_service.dart") {
    $fcmService = Get-Content "lib\shared\services\fcm_service.dart" -Raw
    
    if ($fcmService -match "setForegroundNotificationPresentationOptions") {
        Write-Host "   ✅ iOS foreground notifications configured" -ForegroundColor Green
    } else {
        Write-Host "   ❌ iOS foreground notifications NOT configured" -ForegroundColor Red
        $allPassed = $false
    }
    
    if ($fcmService -match "DarwinNotificationDetails|DarwinInitializationSettings") {
        Write-Host "   ✅ iOS notification details configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  iOS notification details may need verification" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ fcm_service.dart NOT FOUND" -ForegroundColor Red
    $allPassed = $false
}

# Test 7: Alarm Service
Write-Host "`n📱 Test 7: Alarm Service Implementation" -ForegroundColor Yellow
if (Test-Path "lib\shared\services\alarm_service.dart") {
    $alarmService = Get-Content "lib\shared\services\alarm_service.dart" -Raw
    
    if ($alarmService -match "AudioContextIOS") {
        Write-Host "   ✅ iOS audio context configured" -ForegroundColor Green
    } else {
        Write-Host "   ❌ iOS audio context NOT configured" -ForegroundColor Red
        $allPassed = $false
    }
    
    if ($alarmService -match "defaultToSpeaker") {
        Write-Host "   ✅ iOS speaker output configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  iOS speaker output may need verification" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ❌ alarm_service.dart NOT FOUND" -ForegroundColor Red
    $allPassed = $false
}

# Test 8: Dependencies
Write-Host "`n📱 Test 8: Dependencies (pubspec.yaml)" -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    $pubspec = Get-Content "pubspec.yaml" -Raw
    
    $requiredPackages = @(
        "firebase_core",
        "firebase_messaging",
        "firebase_auth",
        "cloud_firestore",
        "flutter_local_notifications",
        "audioplayers",
        "audio_session",
        "mqtt_client",
        "provider",
        "hive"
    )
    
    foreach ($package in $requiredPackages) {
        if ($pubspec -match [regex]::Escape("${package}:")) {
            Write-Host "   ✅ $package configured" -ForegroundColor Green
        } else {
            Write-Host "   ❌ $package MISSING" -ForegroundColor Red
            $allPassed = $false
        }
    }
} else {
    Write-Host "   ❌ pubspec.yaml NOT FOUND" -ForegroundColor Red
    $allPassed = $false
}

# Test 9: Flutter analyze
Write-Host "`n📱 Test 9: Flutter Analyze" -ForegroundColor Yellow
try {
    Write-Host "   Running flutter analyze..." -ForegroundColor Gray
    $analyzeResult = flutter analyze 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ No analysis errors" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Analysis found issues (check output)" -ForegroundColor Yellow
        Write-Host $analyzeResult -ForegroundColor Gray
    }
} catch {
    Write-Host "   ❌ Flutter analyze failed" -ForegroundColor Red
    $allPassed = $false
}

# Test 10: Bundle ID consistency
Write-Host "`n📱 Test 10: Bundle ID Consistency" -ForegroundColor Yellow
try {
    $projectPbxproj = Get-Content "ios\Runner.xcodeproj\project.pbxproj" -Raw
    
    if ($projectPbxproj -match "com\.example\.flutterApplicationFinal") {
        Write-Host "   ✅ Bundle ID in project.pbxproj matches" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Bundle ID mismatch in project.pbxproj" -ForegroundColor Red
        $allPassed = $false
    }
} catch {
    Write-Host "   ⚠️  Could not verify project.pbxproj" -ForegroundColor Yellow
}

# Final Summary
Write-Host "`n" + "="*60 -ForegroundColor Cyan
if ($allPassed) {
    Write-Host "✅ ALL CHECKS PASSED - Ready for Codemagic!" -ForegroundColor Green
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Push code to GitHub" -ForegroundColor White
    Write-Host "2. Set up Codemagic account" -ForegroundColor White
    Write-Host "3. Upload APNs key to Firebase Console" -ForegroundColor White
    Write-Host "4. Configure code signing in Codemagic" -ForegroundColor White
    Write-Host "5. Build and test on real iPhone" -ForegroundColor White
} else {
    Write-Host "❌ SOME CHECKS FAILED - Review errors above" -ForegroundColor Red
    Write-Host "`nFix issues before pushing to GitHub" -ForegroundColor Yellow
}
Write-Host "="*60 -ForegroundColor Cyan

Write-Host "`n📖 See IOS_CODEMAGIC_SETUP_GUIDE.md for detailed instructions`n" -ForegroundColor Cyan
