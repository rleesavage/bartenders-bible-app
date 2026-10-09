from pathlib import Path
import os
import base64

old = "com.example.bartenders_bible"
new = "com.webolium.bartendersbible"

for p in Path("android").rglob("*"):
    if p.is_file() and p.suffix in {".kt", ".kts", ".java", ".xml"}:
        try:
            s = p.read_text()
        except UnicodeDecodeError:
            continue
        if old in s:
            p.write_text(s.replace(old, new))

manifest = Path("android/app/src/main/AndroidManifest.xml")
s = manifest.read_text()
s = s.replace(
    'android:label="bartenders_bible"',
    "android:label=\"Bartender's Bible\""
)

if 'android.permission.INTERNET' not in s:
    s = s.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <uses-permission android:name="android.permission.INTERNET" />'
    )

if 'android.permission.RECORD_AUDIO' not in s:
    s = s.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <uses-permission android:name="android.permission.RECORD_AUDIO" />'
    )

if '<queries>' not in s:
    s = s.replace(
        '</manifest>',
        '    <queries>\n'
        '        <intent>\n'
        '            <action android:name="android.speech.RecognitionService" />\n'
        '        </intent>\n'
        '    </queries>\n'
        '</manifest>'
    )

manifest.write_text(s)

ks_b64 = os.environ["BB_UPLOAD_KEYSTORE_BASE64"]
store_password = os.environ["BB_UPLOAD_STORE_PASSWORD"]
key_password = os.environ["BB_UPLOAD_KEY_PASSWORD"]
key_alias = os.environ["BB_UPLOAD_KEY_ALIAS"]

Path("android/app/upload-keystore.jks").write_bytes(base64.b64decode(ks_b64))

Path("android/key.properties").write_text(
    "storePassword=" + store_password + "\n"
    "keyPassword=" + key_password + "\n"
    "keyAlias=" + key_alias + "\n"
    "storeFile=upload-keystore.jks\n"
)

gradle = Path("android/app/build.gradle.kts")
g = gradle.read_text()

imports = '''import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

'''
if "val keystoreProperties = Properties()" not in g:
    g = imports + g

signing_block = '''
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

'''
if 'create("release")' not in g:
    marker = "    buildTypes {"
    if marker not in g:
        raise SystemExit("Could not find buildTypes block in android/app/build.gradle.kts")
    g = g.replace(marker, signing_block + marker, 1)

old_sign = 'signingConfig = signingConfigs.getByName("debug")'
new_sign = 'signingConfig = signingConfigs.getByName("release")'
if old_sign in g:
    g = g.replace(old_sign, new_sign, 1)
elif new_sign not in g:
    raise SystemExit("Could not locate release signingConfig in android/app/build.gradle.kts")

gradle.write_text(g)
