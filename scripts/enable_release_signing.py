#!/usr/bin/env python3
"""Adds release signing to android/app/build.gradle.kts. Safe to run twice."""
import pathlib
import re
import shutil
import sys

path = pathlib.Path("android/app/build.gradle.kts")
if not path.exists():
    print("android/app/build.gradle.kts not found.")
    print("If your project has android/app/build.gradle (Groovy), paste it to Claude.")
    sys.exit(1)

text = path.read_text()
if "stillscreen-release-signing" in text:
    print("Already patched. Nothing to do.")
    sys.exit(0)

android_block = re.compile(r"^android\s*\{\s*$", re.M)
if not android_block.search(text):
    print("Could not find the 'android {' block. Paste the file to Claude.")
    sys.exit(1)

imports = "import java.io.FileInputStream\nimport java.util.Properties\n\n"

props = """// stillscreen-release-signing
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

"""

signing = """
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }
"""

debug_line = re.compile(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)')
release_line = (
    'signingConfig = if (keystorePropertiesFile.exists()) '
    'signingConfigs.getByName("release") else signingConfigs.getByName("debug")'
)

shutil.copy(path, path.with_suffix(".kts.bak"))

# 1. load key.properties just before the android block
m = android_block.search(text)
text = text[: m.start()] + props + text[m.start():]

# 2. add signingConfigs right after "android {"
m = android_block.search(text)
text = text[: m.end()] + signing + text[m.end():]

# 3. use it for release builds
if debug_line.search(text):
    text = debug_line.sub(release_line, text, count=1)
    note = "Release builds now use your upload key."
else:
    note = ("WARNING: could not find the debug signingConfig line in buildTypes.\n"
            "Paste android/app/build.gradle.kts to Claude so it can be wired by hand.")

path.write_text(imports + text)
print("Patched android/app/build.gradle.kts (backup: build.gradle.kts.bak).")
print(note)
