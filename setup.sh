#!/bin/bash
set -e
mkdir -p app/src/main/java/com/kotha/app app/src/main/res/xml app/src/main/res/values

cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
    <uses-permission android:name="android.permission.CALL_PHONE" />
    <uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
    <application
        android:label="কথা"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity android:name=".MainActivity" android:exported="true" android:launchMode="singleTop" android:configChanges="orientation|screenSize|keyboardHidden">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service android:name=".KothaAccessibilityService" android:permission="android.permission.BIND_ACCESSIBILITY_SERVICE" android:exported="true">
            <intent-filter>
                <action android:name="android.accessibilityservice.AccessibilityService" />
            </intent-filter>
            <meta-data android:name="android.accessibilityservice" android:resource="@xml/accessibility_config" />
        </service>
        <service android:name=".KothaForegroundService" android:exported="false" android:foregroundServiceType="microphone" />
    </application>
</manifest>
EOF

cat > app/src/main/res/xml/accessibility_config.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged|typeViewClicked"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows|flagDefault"
    android:canPerformGestures="true"
    android:canRetrieveWindowContent="true"
    android:notificationTimeout="100"
    android:description="@string/accessibility_description" />
EOF

cat > app/src/main/res/values/strings.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">কথা</string>
    <string name="accessibility_description">কথা ফোনের অ্যাপ খুলতে ও বাটন চাপতে এটা ব্যবহার করে।</string>
</resources>
EOF

cat > app/src/main/java/com/kotha/app/KothaAccessibilityService.java <<'EOF'
package com.kotha.app;

import android.accessibilityservice.AccessibilityService;
import android.view.accessibility.AccessibilityEvent;

public class KothaAccessibilityService extends AccessibilityService {
    public static KothaAccessibilityService instance;

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        instance = this;
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) { }

    @Override
    public void onInterrupt() { }

    @Override
    public void onDestroy() {
        super.onDestroy();
        instance = null;
    }
}
EOF

cat > app/src/main/java/com/kotha/app/KothaForegroundService.java <<'EOF'
package com.kotha.app;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.IBinder;

public class KothaForegroundService extends Service {
    @Override
    public void onCreate() {
        super.onCreate();
        NotificationManager nm = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        NotificationChannel ch = new NotificationChannel("kotha_bg", "কথা", NotificationManager.IMPORTANCE_LOW);
        nm.createNotificationChannel(ch);
        Notification n = new Notification.Builder(this, "kotha_bg")
                .setContentTitle("কথা চলছে")
                .setContentText("কথা আপনার কথা শুনছে")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .build();
        startForeground(2, n);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) { return null; }
}
EOF

cat > app/src/main/java/com/kotha/app/KothaActions.java <<'EOF'
package com.kotha.app;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;

public class KothaActions {
    public static void openWhatsApp(Context ctx) {
        Intent i = ctx.getPackageManager().getLaunchIntentForPackage("com.whatsapp");
        if (i != null) {
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            ctx.startActivity(i);
        }
    }

    public static void openUrl(Context ctx, String url) {
        Intent i = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        ctx.startActivity(i);
    }
}
EOF
