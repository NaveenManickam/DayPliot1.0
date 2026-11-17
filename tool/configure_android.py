#!/usr/bin/env python3
"""Apply DayPilot's Android id, notification, biometrics and Gradle requirements.

Run after `flutter create --platforms=android --org com.naveenmanickam
--project-name daypilot .` using Flutter 3.50+.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "android"
APP_ID = "com.naveenmanickam.daypilot"


def require(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"Required Flutter-generated file is missing: {path}")
    return path.read_text(encoding="utf-8")


def write(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def patch_settings() -> None:
    candidates = [ANDROID / "settings.gradle.kts", ANDROID / "settings.gradle"]
    path = next((item for item in candidates if item.exists()), None)
    if path is None:
        raise SystemExit("Flutter did not generate settings.gradle(.kts).")
    content = require(path)
    content, count = re.subn(
        r'(id\(["\']com\.android\.application["\']\)\s+version\s+)["\'][^"\']+["\']',
        r'\g<1>"9.3.1"', content,
    )
    if count == 0:
        content, count = re.subn(
            r"(id\s+['\"]com\.android\.application['\"]\s+version\s+)['\"][^'\"]+['\"]",
            r'\g<1>"9.3.1"', content,
        )
    if count == 0:
        raise SystemExit("Could not locate the com.android.application plugin version in settings.gradle.")
    # AGP 9 uses built-in Kotlin; the legacy Kotlin Gradle plugin must not be applied.
    content = re.sub(
        r'^\s*id\(["\'](?:org\.jetbrains\.kotlin\.android|kotlin-android)["\']\)\s+version\s+["\'][^"\']+["\']\s+apply\s+false\s*\n',
        '', content, flags=re.MULTILINE,
    )
    content = re.sub(
        r'^\s*id\s+["\'](?:org\.jetbrains\.kotlin\.android|kotlin-android)["\']\s+version\s+["\'][^"\']+["\']\s+apply\s+false\s*\n',
        '', content, flags=re.MULTILINE,
    )
    write(path, content)


def patch_gradle_properties() -> None:
    path = ANDROID / "gradle.properties"
    content = require(path)
    if re.search(r"^android\.builtInKotlin\s*=", content, flags=re.MULTILINE):
        content = re.sub(r"^android\.builtInKotlin\s*=.*$", "android.builtInKotlin=true", content, flags=re.MULTILINE)
    else:
        content += "\nandroid.builtInKotlin=true\n"
    write(path, content)


def patch_gradle_wrapper() -> None:
    path = ANDROID / "gradle" / "wrapper" / "gradle-wrapper.properties"
    content = require(path)
    content, count = re.subn(
        r"gradle-[0-9][0-9.]*-(?:all|bin)\.zip",
        "gradle-9.5.0-all.zip",
        content,
    )
    if count == 0:
        raise SystemExit("Could not find the Gradle distribution URL in gradle-wrapper.properties.")
    write(path, content)


def patch_app_gradle() -> None:
    candidates = [ANDROID / "app" / "build.gradle.kts", ANDROID / "app" / "build.gradle"]
    path = next((item for item in candidates if item.exists()), None)
    if path is None:
        raise SystemExit("Flutter did not generate android/app/build.gradle(.kts).")
    content = require(path)
    is_kts = path.suffix == ".kts"
    if is_kts:
        content = re.sub(r'^\s*id\(["\'](?:kotlin-android|org\.jetbrains\.kotlin\.android)["\']\)\s*\n', '', content, flags=re.MULTILINE)
        content = re.sub(r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 37', content)
        content = re.sub(r'namespace\s*=\s*[^\n]+', f'namespace = "{APP_ID}"', content)
        content = re.sub(r'applicationId\s*=\s*[^\n]+', f'applicationId = "{APP_ID}"', content)
        content = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 24', content)
        if "compileSdk = 37" not in content:
            content = re.sub(r'android\s*\{', 'android {\n    compileSdk = 37', content, count=1)
        if "multiDexEnabled = true" not in content:
            content = re.sub(r'defaultConfig\s*\{', 'defaultConfig {\n        multiDexEnabled = true', content, count=1)
        compile_block = '''compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }'''
        if "isCoreLibraryDesugaringEnabled" not in content:
            content = re.sub(r'compileOptions\s*\{.*?\n    \}', compile_block, content, count=1, flags=re.DOTALL) if re.search(r'compileOptions\s*\{', content) else re.sub(r'android\s*\{', 'android {\n    '+compile_block, content, count=1)
        content = re.sub(r'kotlinOptions\s*\{[^{}]*\}\s*', '', content, flags=re.DOTALL)
        if not re.search(r'kotlin\s*\{\s*compilerOptions', content):
            content = content.replace('\nflutter {', '\nkotlin {\n    compilerOptions {\n        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17\n    }\n}\n\nflutter {', 1)
        if "coreLibraryDesugaring(" not in content:
            match = re.search(r'dependencies\s*\{', content)
            if match:
                content = content[:match.end()] + '\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")' + content[match.end():]
            else:
                content += '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
        if 'androidx.biometric:biometric' not in content:
            match = re.search(r'dependencies\s*\{', content)
            if match:
                content = content[:match.end()] + '\n    implementation("androidx.biometric:biometric:1.1.0")' + content[match.end():]
    else:
        content = re.sub(r"id\s+['\"](?:kotlin-android|org\.jetbrains\.kotlin\.android)['\"]\s*\n", '', content, flags=re.MULTILINE)
        content = re.sub(r'compileSdk\s+flutter\.compileSdkVersion', 'compileSdk 37', content)
        content = re.sub(r'namespace\s+[^\n]+', f'namespace "{APP_ID}"', content)
        content = re.sub(r'applicationId\s+[^\n]+', f'applicationId "{APP_ID}"', content)
        content = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 24', content)
        if 'compileSdk 37' not in content:
            content = re.sub(r'android\s*\{', 'android {\n    compileSdk 37', content, count=1)
        if 'multiDexEnabled true' not in content:
            content = re.sub(r'defaultConfig\s*\{', 'defaultConfig {\n        multiDexEnabled true', content, count=1)
        if 'coreLibraryDesugaringEnabled true' not in content:
            content = re.sub(r'compileOptions\s*\{', 'compileOptions {\n        coreLibraryDesugaringEnabled true\n        sourceCompatibility JavaVersion.VERSION_17\n        targetCompatibility JavaVersion.VERSION_17', content, count=1)
        content = re.sub(r'kotlinOptions\s*\{[^{}]*\}\s*', '', content, flags=re.DOTALL)
        if not re.search(r'kotlin\s*\{\s*compilerOptions', content):
            content = content.replace('\nflutter {', '\nkotlin {\n    compilerOptions {\n        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17\n    }\n}\n\nflutter {', 1)
        if "coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'" not in content:
            match = re.search(r'dependencies\s*\{', content)
            if match:
                content = content[:match.end()] + "\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'" + content[match.end():]
        if 'androidx.biometric:biometric' not in content:
            match = re.search(r'dependencies\s*\{', content)
            if match:
                content = content[:match.end()] + "\n    implementation 'androidx.biometric:biometric:1.1.0'" + content[match.end():]
    write(path, content)


def patch_manifest() -> None:
    path = ANDROID / "app" / "src" / "main" / "AndroidManifest.xml"
    content = require(path)
    for permission in (
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.RECEIVE_BOOT_COMPLETED",
        "android.permission.SCHEDULE_EXACT_ALARM",
        "android.permission.USE_BIOMETRIC",
    ):
        tag = f'<uses-permission android:name="{permission}" />'
        if permission not in content:
            content = content.replace("<application", f"    {tag}\n    <application", 1)
    content = re.sub(r'android:label="[^"]*"', 'android:label="DayPilot"', content, count=1)
    receivers = '''
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON" />
            </intent-filter>
        </receiver>
'''
    if "ScheduledNotificationReceiver" not in content:
        content = content.replace("</application>", receivers + "    </application>", 1)
    write(path, content)


def patch_activity() -> None:
    kotlin_root = ANDROID / "app" / "src" / "main" / "kotlin"
    candidates = list(kotlin_root.rglob("MainActivity.kt"))
    if not candidates:
        raise SystemExit("Could not locate generated MainActivity.kt.")
    old_path = candidates[0]
    destination = kotlin_root.joinpath(*APP_ID.split("."), "MainActivity.kt")
    destination.parent.mkdir(parents=True, exist_ok=True)
    content = f'''package {APP_ID}

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {{
    private val biometricChannel = "com.naveenmanickam.daypilot/biometrics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {{
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, biometricChannel)
            .setMethodCallHandler {{ call, result ->
                when (call.method) {{
                    "isAvailable" -> result.success(isBiometricAvailable())
                    "authenticate" -> authenticate(
                        call.argument<String>("reason") ?: "Unlock DayPilot",
                        result
                    )
                    else -> result.notImplemented()
                }}
            }}
    }}

    private fun isBiometricAvailable(): Boolean {{
        val manager = BiometricManager.from(this)
        return manager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_WEAK) ==
            BiometricManager.BIOMETRIC_SUCCESS
    }}

    private fun authenticate(reason: String, channelResult: MethodChannel.Result) {{
        if (!isBiometricAvailable()) {{
            channelResult.success(false)
            return
        }}
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle("DayPilot")
            .setSubtitle(reason)
            .setNegativeButtonText("Cancel")
            .setAllowedAuthenticators(BiometricManager.Authenticators.BIOMETRIC_WEAK)
            .build()
        val prompt = BiometricPrompt(
            this,
            ContextCompat.getMainExecutor(this),
            object : BiometricPrompt.AuthenticationCallback() {{
                override fun onAuthenticationSucceeded(
                    authenticationResult: BiometricPrompt.AuthenticationResult
                ) {{
                    channelResult.success(true)
                }}

                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {{
                    channelResult.success(false)
                }}
            }}
        )
        prompt.authenticate(promptInfo)
    }}
}}
'''
    write(destination, content)
    if old_path != destination:
        old_path.unlink()


def patch_launch_theme() -> None:
    for path in (ANDROID / "app" / "src" / "main" / "res").rglob("styles.xml"):
        content = require(path)
        content = re.sub(
            r'(<style\s+name="LaunchTheme"\s+parent=")[^"]+(">)',
            r'\1Theme.AppCompat.DayNight\2', content,
        )
        write(path, content)


def remove_template_test() -> None:
    path = ROOT / "test" / "widget_test.dart"
    if path.exists():
        content = path.read_text(encoding="utf-8")
        if "Counter increments smoke test" in content and "FloatingActionButton" in content:
            path.unlink()


def main() -> None:
    if not ANDROID.exists():
        raise SystemExit("Run `flutter create --platforms=android --org com.naveenmanickam --project-name daypilot .` first.")
    patch_settings()
    patch_gradle_properties()
    patch_gradle_wrapper()
    patch_app_gradle()
    patch_manifest()
    patch_activity()
    patch_launch_theme()
    remove_template_test()
    print(f"Configured Android application ID and label for {APP_ID}.")


if __name__ == "__main__":
    main()
