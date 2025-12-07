# Building LabStream for Windows

This guide provides detailed instructions for building LabStream as a Windows desktop application.

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0+)
   ```bash
   # Verify installation
   flutter --version
   flutter doctor -v
   ```

2. **Visual Studio 2022** (or 2019)
   - Required workload: "Desktop development with C++"
   - Download: https://visualstudio.microsoft.com/downloads/

3. **Windows 10 SDK** (included with Visual Studio)

4. **Git for Windows**
   ```bash
   git --version
   ```

---

## Build Methods

### Method 1: MSIX Package (Recommended for Distribution)

MSIX is the modern Windows app package format, similar to MSI installers.

#### Step 1: Configure MSIX

The MSIX configuration is already in `pubspec.yaml`:

```yaml
msix_config:
  display_name: LabStream
  publisher_display_name: LabStream Team
  identity_name: com.labstream.app
  msix_version: 1.0.0.0
  logo_path: assets/icons/app_icon.png
  capabilities: internetClient, microphone, webcam
```

#### Step 2: Create App Icon

Create a 512x512 PNG icon and save it as:
```
assets/icons/app_icon.png
```

For a quick placeholder:
```bash
# Create assets directories
mkdir -p assets/icons

# You'll need to add your actual icon here
# For testing, you can use any 512x512 PNG image
```

#### Step 3: Build MSIX Package

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build Windows release
flutter build windows --release

# Create MSIX package
flutter pub run msix:create
```

#### Step 4: Locate the Package

The MSIX package will be created in:
```
build/windows/runner/Release/labstream.msix
```

#### Step 5: Install on Windows

Double-click the `.msix` file to install, or use PowerShell:

```powershell
Add-AppxPackage -Path "build\windows\runner\Release\labstream.msix"
```

---

### Method 2: Portable EXE (No Installation Required)

This creates a standalone executable that can run without installation.

#### Step 1: Build Release Version

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build for Windows
flutter build windows --release
```

#### Step 2: Locate Build Output

The executable and dependencies are in:
```
build/windows/runner/Release/
```

Files created:
- `labstream.exe` - Main executable
- `flutter_windows.dll` - Flutter engine
- `*.dll` - Required DLL files
- `data/` - Flutter assets and resources

#### Step 3: Create Portable Package

Create a distributable folder:

```bash
# Create distribution folder
mkdir labstream-portable

# Copy all files from Release folder
xcopy /E /I build\windows\runner\Release labstream-portable

# Create ZIP archive (optional)
powershell Compress-Archive -Path labstream-portable -DestinationPath labstream-portable-v1.0.0.zip
```

#### Step 4: Test the Portable Version

```bash
cd labstream-portable
labstream.exe
```

**Note:** All files in the Release folder are required. Don't distribute just the EXE alone.

---

### Method 3: Custom Installer with Inno Setup

For a traditional installer experience.

#### Step 1: Install Inno Setup

Download and install: https://jrsoftware.org/isinfo.php

#### Step 2: Create Installer Script

Create `installer.iss` in the project root:

```ini
[Setup]
AppName=LabStream
AppVersion=1.0.0
DefaultDirName={autopf}\LabStream
DefaultGroupName=LabStream
OutputDir=installers
OutputBaseFilename=LabStream-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=admin

[Files]
Source: "build\windows\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

[Icons]
Name: "{group}\LabStream"; Filename: "{app}\labstream.exe"
Name: "{autodesktop}\LabStream"; Filename: "{app}\labstream.exe"

[Run]
Filename: "{app}\labstream.exe"; Description: "Launch LabStream"; Flags: postinstall nowait skipifsilent
```

#### Step 3: Build Installer

```bash
# Build Flutter app first
flutter build windows --release

# Compile installer (from Inno Setup GUI or command line)
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
```

The installer will be created in `installers/LabStream-Setup-1.0.0.exe`

---

## Build Configuration

### Release vs Debug Builds

**Debug Build:**
```bash
flutter run -d windows
```
- Includes debugging symbols
- Larger file size
- Hot reload enabled
- Performance not optimized

**Release Build:**
```bash
flutter build windows --release
```
- Optimized performance
- Smaller file size
- No debugging symbols
- Production-ready

### Build with Custom Branding

Edit `windows/runner/Runner.rc` to customize:
- Application name
- Version information
- Copyright information
- Company name

### Optimization Flags

For maximum performance, add to `windows/runner/CMakeLists.txt`:

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /O2")
endif()
```

---

## Code Signing (Optional but Recommended)

For production distribution, sign your executable:

### Step 1: Obtain Code Signing Certificate

Purchase from a Certificate Authority (CA) like:
- DigiCert
- Sectigo
- GlobalSign

### Step 2: Sign the Executable

```powershell
# Using signtool (included with Windows SDK)
signtool sign /f "certificate.pfx" /p "password" /t http://timestamp.digicert.com "build\windows\runner\Release\labstream.exe"
```

### Step 3: Verify Signature

```powershell
signtool verify /pa "build\windows\runner\Release\labstream.exe"
```

---

## Troubleshooting

### Issue: "Visual Studio not found"

**Solution:**
1. Install Visual Studio 2022 or 2019
2. Install "Desktop development with C++" workload
3. Restart terminal/IDE
4. Run `flutter doctor` to verify

### Issue: "Build failed with CMake error"

**Solution:**
```bash
# Clean build cache
flutter clean
rm -rf build/

# Rebuild
flutter pub get
flutter build windows --release
```

### Issue: "Missing DLL errors when running"

**Solution:**
Ensure all files from `build/windows/runner/Release/` are distributed together.

### Issue: "MSIX creation fails"

**Solution:**
1. Verify `msix_version` in `pubspec.yaml` is in format `X.X.X.X`
2. Ensure app icon exists at specified path
3. Check for valid publisher name

---

## Distribution Checklist

Before distributing your application:

- [ ] Test on a clean Windows machine
- [ ] Verify all features work in release mode
- [ ] Include README or user guide
- [ ] Sign the executable (for production)
- [ ] Create installer or package
- [ ] Test installation process
- [ ] Verify network connectivity features
- [ ] Check antivirus compatibility
- [ ] Prepare uninstall instructions
- [ ] Document system requirements

---

## System Requirements for End Users

**Minimum:**
- Windows 10 (1809 or later)
- 4 GB RAM
- 500 MB disk space
- Internet connection
- Microphone (for audio)
- Camera (for video, optional)

**Recommended:**
- Windows 10/11 (latest version)
- 8 GB RAM
- 1 GB disk space
- Broadband internet (10+ Mbps)
- HD webcam
- Quality microphone

---

## File Size Optimization

Typical build sizes:
- Debug build: ~100-150 MB
- Release build: ~50-80 MB
- MSIX package: ~40-60 MB (compressed)

To reduce size:
1. Remove unused assets
2. Use release mode
3. Enable tree-shaking
4. Compress with UPX (advanced)

---

## Automated Builds

### GitHub Actions Example

Create `.github/workflows/build-windows.yml`:

```yaml
name: Build Windows

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v3

    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'
        channel: 'stable'

    - name: Install dependencies
      run: flutter pub get

    - name: Build Windows
      run: flutter build windows --release

    - name: Create MSIX
      run: flutter pub run msix:create

    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      with:
        name: windows-build
        path: build/windows/runner/Release/
```

---

## Additional Resources

- [Flutter Desktop Documentation](https://docs.flutter.dev/desktop)
- [Windows App Development](https://docs.microsoft.com/windows/apps/)
- [MSIX Packaging](https://docs.microsoft.com/windows/msix/)
- [Code Signing Best Practices](https://docs.microsoft.com/windows/win32/seccrypto/cryptography-tools)
