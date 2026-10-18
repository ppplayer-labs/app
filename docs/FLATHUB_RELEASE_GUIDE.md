# Flathub Publishing Guide for PPPlayer

This guide details the complete process for publishing and maintaining PPPlayer on [Flathub](https://flathub.org), the central app store and repository for Flatpak Linux applications.

---

## 1. Requirements & Architecture Overview

### App ID Naming Convention
* **Flathub App ID:** `com.ppplayer.PPPlayer`
* **Why not `com.ppplayer.app`?** Flathub's application guidelines strictly prohibit Application IDs that end in generic terms like `.app`, `.desktop`, or `.linux`. Therefore, `com.ppplayer.PPPlayer` is the official App ID used for Flathub.
* **Alternative:** If domain ownership of `ppplayer.com` is unavailable, `io.github.ppplayer_labs.PPPlayer` can be used instead and automatically verified through GitHub organization credentials.

### Flathub Build Strategy
Because Flathub builds execute in a sandboxed network-isolated environment, live downloads during compilation (e.g. `flutter pub get` or dynamic CEF tarball fetches) are prohibited. 
PPPlayer uses the proven Flatpak packaging model (used by apps like Spotube and FluffyChat):
1. PPPlayer's GitHub Release pipeline builds and releases `PPPlayer-Linux-x86_64.tar.gz`.
2. The Flatpak manifest fetches the release tarball as a declared offline source using its SHA-256 hash.
3. The manifest compiles `libmpv` (with `libplacebo` and `libass`) and mounts the `org.freedesktop.Platform.ffmpeg-full` runtime extension for codec support.
4. Flathub's automated checker (`flatpak-external-data-checker`) automatically tracks new GitHub releases and opens update pull requests.

---

## 2. Flatpak Packaging Assets

The required packaging files are located in `packaging/linux/flatpak/`:

| File | Purpose |
| :--- | :--- |
| `com.ppplayer.PPPlayer.yml` | Official Flathub Flatpak manifest. |
| `com.ppplayer.PPPlayer.metainfo.xml` | AppStream metadata (descriptions, categories, OARS 1.1 rating, screenshots, developer details). |
| `com.ppplayer.PPPlayer.desktop` | XDG desktop entry for Linux app launchers. |
| `com.ppplayer.PPPlayer.png` | 256x256 high-resolution application icon. |

---

## 3. Step-by-Step Flathub Submission Process

### Step 1: Ensure GitHub Release Tarball is Live
Flathub builds require the release archive to be publicly downloadable.
1. When a new version (e.g., `v4.0.2`) is released on GitHub, verify that `PPPlayer-Linux-x86_64.tar.gz` is present in the release assets:
   ```
   https://github.com/ppplayer-labs/app/releases/download/v4.0.2/PPPlayer-Linux-x86_64.tar.gz
   ```
2. Compute the SHA-256 checksum of the tarball:
   ```bash
   sha256sum PPPlayer-Linux-x86_64.tar.gz
   ```
3. In `packaging/linux/flatpak/com.ppplayer.PPPlayer.yml`, update the `url` version tag and replace the `sha256:` placeholder with the actual computed hash.

---

### Step 2: Fork and Clone the Flathub Repository
Flathub manages new app submissions via pull requests against the central `flathub/flathub` repository.

1. Go to [https://github.com/flathub/flathub](https://github.com/flathub/flathub) and click **Fork**.
2. Clone your fork locally:
   ```bash
   git clone https://github.com/<your-github-username>/flathub.git
   cd flathub
   ```
3. Create a new branch named after your App ID:
   ```bash
   git checkout -b new-pr-com.ppplayer.PPPlayer
   ```

---

### Step 3: Add Manifest and Files to the Branch
Copy the four files from PPPlayer's `packaging/linux/flatpak/` directory directly into the root of the cloned `flathub` repository branch:

```bash
cp /path/to/app/packaging/linux/flatpak/com.ppplayer.PPPlayer.yml .
cp /path/to/app/packaging/linux/flatpak/com.ppplayer.PPPlayer.metainfo.xml .
cp /path/to/app/packaging/linux/flatpak/com.ppplayer.PPPlayer.desktop .
cp /path/to/app/packaging/linux/flatpak/com.ppplayer.PPPlayer.png .
```

Commit the files:
```bash
git add com.ppplayer.PPPlayer.yml com.ppplayer.PPPlayer.metainfo.xml com.ppplayer.PPPlayer.desktop com.ppplayer.PPPlayer.png
git commit -m "Add com.ppplayer.PPPlayer"
git push origin new-pr-com.ppplayer.PPPlayer
```

---

### Step 4: Validate Locally (Recommended)
Before opening the pull request, you can test building and linting the manifest locally on a Linux system or CI runner.

1. **Install Flatpak and flatpak-builder:**
   ```bash
   sudo apt install flatpak flatpak-builder
   flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
   ```

2. **Install Runtimes:**
   ```bash
   flatpak install --user flathub org.gnome.Platform//46 org.gnome.Sdk//46
   ```

3. **Run the Flathub Linter:**
   ```bash
   flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest com.ppplayer.PPPlayer.yml
   ```

4. **Build the Flatpak:**
   ```bash
   flatpak-builder --force-clean --user --install-deps-from=flathub build-dir com.ppplayer.PPPlayer.yml
   ```

5. **Test Launch:**
   ```bash
   flatpak-builder --run build-dir com.ppplayer.PPPlayer.yml ppplayer
   ```

---

### Step 5: Open the Pull Request on Flathub
> [!IMPORTANT]
> **Base Branch:** Flathub requires all new application submission pull requests to target the **`new-pr`** base branch of `flathub/flathub` (NOT `master`).

1. Navigate to your fork on GitHub: `https://github.com/<your-github-username>/flathub`.
2. Click **Compare & pull request**.
3. Select **base repository: `flathub/flathub`**, **base branch: `new-pr`**, and compare with your branch `new-pr-com.ppplayer.PPPlayer`.
4. Paste the pre-filled submission checklist below into your pull request description:

```markdown
### Please confirm your submission meets all the criteria

- [X] Please describe the application briefly.
PPPlayer is a modern media player built with Flutter, bringing music discovery, local audio/video playback, network stream imports (M3U, PLS, XSPF, ASX), and audio output switching together in a polished desktop experience.

- [X] The Flatpak ID follows all the rules listed in the Application ID requirements.
- [X] I have read and followed all the Submission requirements and the Submission guide and I agree to them.
  - [X] The application has a meaningful development history, evidence of real-world use, and a clear commitment to ongoing maintenance.
  - [X] I have disclosed any AI-generated material included in the application or its Flathub packaging, as required by the Generative AI policy. **Affected parts and approximate extent:** None
  - [X] I have not used AI tools or agents to generate or automate this submission pull request or its review interactions.
- [X] I am an author/developer/upstream contributor to the project.
```

5. Flathub's automated Buildbot will comment on the PR and compile your manifest across `x86_64` (and `aarch64`).
6. Once the build finishes and human reviewers give approval, the PR is merged!

---

### Step 6: Post-Merge & Domain Verification
Once your pull request is approved and merged:
1. Flathub will automatically create a standalone repository at:
   `https://github.com/flathub/com.ppplayer.PPPlayer`
2. **Log into Flathub Developer Portal:**
   - Go to [https://flathub.org](https://flathub.org) and log in using your GitHub account (`ppplayer-labs`).
   - Navigate to the **Developer Portal** and select `com.ppplayer.PPPlayer`.
3. **Verify Domain Ownership (`ppplayer.com`):**
   - Click **Verification**.
   - Choose either:
     - **Well-Known URI:** Upload the verification token to:
       `https://ppplayer.com/.well-known/org.flathub.VerifiedApps.txt`
     - **DNS TXT Record:** Add a TXT record to `ppplayer.com`:
       `_flathub.ppplayer.com` with the token value.
   - Click **Verify**. Once verified, your app receives the official blue verified developer checkmark on Flathub.

---

## 4. Automated Packaging & Tooling in PPPlayer

To make updates effortless, PPPlayer includes automated packaging tooling:

1. **Integrated in `build_linux.sh`:**
   Running `./packaging/linux/scripts/build_linux.sh` automatically:
   - Computes the SHA-256 of `dist/PPPlayer-Linux-x86_64.tar.gz`.
   - Populates `dist/flatpak/` with `com.ppplayer.PPPlayer.yml` referencing the exact hash and version.
   - Builds a local `.flatpak` bundle if `flatpak-builder` is installed.
   - Hashes all artifacts into `dist/SHA256SUMS`.

2. **One-Command Flathub Preparation Script:**
   ```bash
   python packaging/linux/scripts/submit_flathub.py
   ```
   This validates the AppStream metadata, reads the local release tarball hash, and generates the exact files ready to push to Flathub in `dist/flathub-submission/`.

3. **Continuous Maintenance via Flathub Bot:**
   The manifest includes `x-checker-data`:
   ```yaml
   x-checker-data:
     type: json
     url: https://api.github.com/repos/ppplayer-labs/app/releases/latest
     version-query: .tag_name | sub("v";"")
     url-query: .assets[] | select(.name=="PPPlayer-Linux-x86_64.tar.gz") | .browser_download_url
   ```
   Flathub's automated bot checks GitHub releases daily. When a new version is tagged on GitHub, the bot automatically opens a pull request in `flathub/com.ppplayer.PPPlayer` to update the version and SHA-256 checksum.

