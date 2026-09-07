<!--editorconfig-checker-disable-->
<!--markdownlint-disable-next-line first-line-h1-->
[![current version](https://img.shields.io/github/v/release/mas-cli/mas.svg?style=for-the-badge)](https://github.com/mas-cli/mas/releases/latest)
[![supported OS: macOS 15+](https://img.shields.io/badge/Supported_OS-macOS_15%2B-teal?style=for-the-badge)](Package.swift)
[![license: MIT](https://img.shields.io/badge/license-MIT-750014.svg?style=for-the-badge)](LICENSE)
[![language: Swift 6.3](https://img.shields.io/badge/language-Swift_6.3-F05138.svg?style=for-the-badge)](https://www.swift.org)
[![build, test & lint status](https://img.shields.io/github/actions/workflow/status/mas-cli/mas/build-test.yaml?label=build,%20test%20%26%20lint&style=for-the-badge)](
  https://github.com/mas-cli/mas/actions/workflows/build-test.yaml?query=branch%3Amain
)
[![dependencies status](https://img.shields.io/librariesio/github/mas-cli/mas?style=for-the-badge)](Package.swift)
<!--editorconfig-checker-enable-->

<h1 align="center">

![mas](mas.png)

</h1>

mas is a command-line interface for the Mac App Store designed for scripting &
automation.

## Installation

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Provider                                                                    | Package                                                                                                                                     | mas Versions                                                                                         | Method                            |
|:----------------------------------------------------------------------------|:--------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------|:----------------------------------|
| [Aqua](https://aquaproj.github.io)                                          | [mas-cli/mas](https://github.com/aquaproj/aqua-registry/tree/main/pkgs/mas-cli/mas)                                                         | Various                                                                                              | `aqua g -i mas-cli/mas && aqua i` |
| [GitHub Releases](https://github.com/mas-cli/mas/releases)                  | [latest](https://github.com/mas-cli/mas/releases/latest)                                                                                    | All                                                                                                  | Installers & source archives      |
| [Homebrew](https://brew.sh)                                                 | [Core](https://github.com/Homebrew/homebrew-core) [mas](https://formulae.brew.sh/formula/mas)                                               | ![Homebrew Core](https://repology.org/badge/version-for-repo/homebrew/mas-mac-app-store.svg?header=) | `brew install mas`                |
| [Homebrew](https://brew.sh)                                                 | [mas-cli tap](https://github.com/mas-cli/homebrew-tap) [mas](https://github.com/mas-cli/homebrew-tap/blob/main/Formula/mas.rb)              | Latest per macOS                                                                                     | `brew install mas-cli/tap/mas`    |
| [MacPorts](https://www.macports.org/install.php)                            | [mas](https://ports.macports.org/port/mas/details/)                                                                                         | ![MacPorts](https://repology.org/badge/version-for-repo/macports/mas-mac-app-store.svg?header=)      | `sudo port install mas`           |
| [mise](https://mise.jdx.dev)                                                | [mas](https://github.com/jdx/mise/blob/main/registry/mas.toml)                                                                              | Various                                                                                              | `mise use mas`                    |
| [Nix](https://nixos.org) [Darwin](https://github.com/nix-darwin/nix-darwin) | [Nixpkgs unstable](https://nixos.org/manual/nixpkgs/unstable/) [mas](https://search.nixos.org/packages?channel=unstable&query=mas#show=mas) | Various                                                                                              | `nix profile add nixpkgs#mas`     |
| [Nix](https://nixos.org) [Darwin](https://github.com/nix-darwin/nix-darwin) | [Nixpkgs stable](https://nixos.org/manual/nixpkgs/stable/) [mas](https://search.nixos.org/packages?query=mas#show=mas)                      | Various                                                                                              | `nix profile add nixpkgs#mas`     |
| [pkgx](https://pkgx.dev)                                                    | [mas](https://pkgx.dev/pkgs/github.com/mas-cli/mas/)                                                                                        | ≥ 1.8.7                                                                                              | `pkgm install mas`                |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Many other tools wrap the above providers; e.g., Ansible can install mas via
Homebrew or MacPorts.

## Commands

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Command                       | Functionality                             | Notes                                                                                                       | Aliases    |
|:------------------------------|:------------------------------------------|:------------------------------------------------------------------------------------------------------------|:-----------|
| `search <term>…`              | Search for App Store apps                 | [formats](#output-formats)                                                                                  |            |
| `lookup <id>…`                | Output App Store app info                 | [formats](#output-formats)                                                                                  | `info`     |
| `list [<id>…]`                | Output installed apps                     | [spotlight](#spotlight), [formats](#output-formats)                                                         |            |
| `outdated [<id>…]`            | Output outdated apps                      | [spotlight](#spotlight), [formats](#output-formats)                                                         |            |
| `outdated --accurate [<id>…]` | Output outdated apps                      | [spotlight](#spotlight), [account](#app-store-apple-account-requirements), [formats](#output-formats)       |            |
| `get <id>…`                   | [Get free apps](#paid-apps), install apps | [spotlight](#spotlight), [root](#root-privileges), [account](#app-store-apple-account-requirements-for-get) | `purchase` |
| `install <id>…`               | Install already owned apps                | [spotlight](#spotlight), [root](#root-privileges), [account](#app-store-apple-account-requirements)         |            |
| `lucky <term>…`               | Install first matching app                | [spotlight](#spotlight), [root](#root-privileges), [account](#app-store-apple-account-requirements)         |            |
| `update [<id>…]`              | Update outdated apps                      | [spotlight](#spotlight), [root](#root-privileges), [account](#app-store-apple-account-requirements)         | `upgrade`  |
| `update --accurate [<id>…]`   | Update outdated apps                      | [spotlight](#spotlight), [root](#root-privileges), [account](#app-store-apple-account-requirements)         | `upgrade`  |
| `uninstall (<id>…\|--all)`    | Uninstall apps                            | [spotlight](#spotlight), [root](#root-privileges)                                                           |            |
| `signout`                     | Sign out from App Store                   |                                                                                                             |            |
| `open [<id>]`                 | Open app App Store page                   |                                                                                                             |            |
| `home <id>…`                  | Open app web pages                        |                                                                                                             |            |
| `seller <id>…`                | Open seller app web pages                 |                                                                                                             | `vendor`   |
| `reset`                       | Reset App Store processes                 |                                                                                                             |            |
| `config`                      | Output config                             | [formats](#output-formats)                                                                                  |            |
| `version`                     | Output version                            |                                                                                                             |            |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

Detailed documentation is available via `man mas` & `mas --help`.

## Integrations

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Tool                                                                        | Module                                                                                                                  | Interface | Functionality                                                               |
|:----------------------------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------|:----------|:----------------------------------------------------------------------------|
| [Ansible](https://ansible.com)                                              | [community.general.mas](https://docs.ansible.com/projects/ansible/latest/collections/community/general/mas_module.html) | CLI       | Get, install & update apps listed in a config file                          |
| [Bold Brew](https://bold-brew.com)                                          | -                                                                                                                       | TUI       | Manage `Brewfile` apps                                                      |
| [Homebrew](https://brew.sh)                                                 | [Bundle](https://docs.brew.sh/Brew-Bundle-and-Brewfile)                                                                 | CLI       | Include installed apps in `Brewfile`; get, install & update `Brewfile` apps |
| [mise](https://mise.jdx.dev)                                                | [Mac App Store bootstrap.packages](https://mise.jdx.dev/bootstrap/packages/mas.html)                                    | CLI       | Get, install & update apps listed in a config file                          |
| [mpm](https://mpm.run)                                                      | [Mac App Store manager](https://mpm.run/managers/mas/)                                                                  | CLI       | List, list outdated, search, install, update & uninstall apps               |
| [Nix](https://nixos.org) [Darwin](https://github.com/nix-darwin/nix-darwin) | [homebrew.masApps](https://nix-darwin.github.io/nix-darwin/manual/index.html#opt-homebrew.masApps)                      | CLI       | Get, install & update apps listed in a config file                          |
| [Taphouse](https://taphouse.multimodalsolutions.gr)                         | -                                                                                                                       | GUI       | Search, get, install & update apps; manage `Brewfile`s                      |
| [Topgrade](https://github.com/topgrade-rs/topgrade)                         | -                                                                                                                       | CLI       | Update apps                                                                 |
| [Updatest](https://updatest.app)                                            | -                                                                                                                       | GUI       | Update apps                                                                 |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Known Issues

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Issue                                                                          | Solution                                                                                                                                                                    |
|:-------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Manage system software (macOS, Safari…)                                        | Use [`softwareupdate`](https://www.unix.com/man-page/osx/8/softwareupdate)                                                                                                  |
| [Inconsistent app data](https://github.com/mas-cli/mas/issues/387)             | Wait hours – days (the App Store uses eventual consistency)                                                                                                                 |
| [Cannot purchase paid apps](https://github.com/mas-cli/mas/issues/558)         | <a id="paid-apps"></a>Purchase paid apps directly in the App Store; submit a PR                                                                                             |
| [iOS & iPadOS apps are unsupported](https://github.com/mas-cli/mas/issues/321) | Submit a PR                                                                                                                                                                 |
| [Hangs](https://github.com/mas-cli/mas/issues/1222)                            | [Index apps in Spotlight](#spotlight); [open a bug report](https://github.com/mas-cli/mas/issues/new?template=01-bug-report.yaml) if hangs persist                          |
| Undetected installed apps                                                      | [Index apps in Spotlight](#spotlight)                                                                                                                                       |
| `This redownload is not available for this Apple Account…` error               | Sign in the correct Apple Account to the App Store, or&nbsp;uninstall&nbsp;the&nbsp;app&nbsp;&amp;&nbsp;get&nbsp;it&nbsp;with&nbsp;the&nbsp;current&nbsp;Apple&nbsp;Account |
| Other bugs                                                                     | [Subscribe to an existing](https://github.com/mas-cli/mas/issues), or [open a new](https://github.com/mas-cli/mas/issues/new?template=01-bug-report.yaml), bug report       |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Development

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Action                                                                  | Command                        |
|:------------------------------------------------------------------------|:-------------------------------|
| Build                                                                   | `Scripts/build` or Xcode 26.4+ |
| Test ([Swift Testing](https://developer.apple.com/xcode/swift-testing)) | `Scripts/test`                 |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## App IDs

App Store apps each have 2 unique IDs:

| Type      | Format  | Example (for Xcode) |
|:----------|:--------|:--------------------|
| ADAM ID   | Integer | 497799835           |
| Bundle ID | String  | com.apple.dt.Xcode  |

mas commands accept both types of app IDs as arguments.

By default, all-digit app IDs are considered ADAM IDs; other app IDs are
considered bundle IDs.

`--bundle` forces all-digit app IDs to also be considered bundle IDs.

ADAM IDs can be found via:

- `mas search <term>…`
- `mas list`
- The App Store:
  1. Open an app's App Store page.
  2. Open the page's Share Sheet.
  3. Choose `Copy`.
  4. Extract the ADAM ID from the URL in the copied text. e.g., `497799835` from
     `https://apps.apple.com/us/app/xcode/id497799835?mt=12`.

## Output Formats

Commands whose primary purpose is to output information to stdout support 3
output formats, each selectable via a flag (note: an item is normally an app):

- **Table** (`--table`): Row per item, column per selected field (if an item has
  multiple values for a field, the last value is used). Default for:
  - `list`
  - `outdated`
  - `search`
- **Key-Value** (`--key-value`): Key-value pair on its own row per selected
  field, blank line between items (if an item has multiple values for a field,
  the last value is used). Default for:
  - `config`
  - `lookup`
- **JSON** (`--json`): Streamed JSON object per item, key-value pair per each
  field (if an item has multiple values for a field, all values are output with
  their relative input order preserved in the output). Key-value pairs are
  sorted by key.

Many fields provided by Apple are poorly named, so they are renamed by an
algorithm. If Apple renames or adds fields, suboptimal field names might be
output until the algorithm is updated.

## Spotlight

`list`, `outdated`, `get`, `install`, `lucky`, `update` & `uninstall` obtain
data for installed apps from the Spotlight Metadata Service (MDS).

Spotlight indexing thus must be enabled & valid for folders containing App Store
apps.

Check if an app is properly indexed in Spotlight via:

```console
## General format:
$ mdls -rn kMDItemAppStoreAdamID <path-to-app>
## Outputs the ADAM ID if the app is indexed.
## Outputs nothing if the app is not indexed.

## Example:
$ mdls -rn kMDItemAppStoreAdamID /Applications/Xcode.app
497799835
```

If an app is indexed in Spotlight, find the path to the app from its ADAM ID
via:

```shell
mdfind 'kMDItemAppStoreAdamID = <adam-id>'
```

If any App Store apps are not properly indexed, index via:

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
```shell
# Individual app (if the omitted apps are known). e.g., for Xcode:
mdimport /Applications/Xcode.app

# All apps:
vol="$(/usr/libexec/PlistBuddy -c "Print :PreferredVolume:name" ~/Library/Preferences/com.apple.appstored.plist 2>/dev/null)"
mdimport /Applications ${vol:+"/Volumes/${vol}/Applications"}

# All volumes:
sudo mdutil -Eai on
```
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

## Root Privileges

`get`, `install`, `lucky`, `update` & `uninstall` require root privileges.

If run without root privileges, mas requests them as necessary.

mas uses existing valid sudo credentials, falling back to prompting for the
macOS user password, which is piped directly to a sudo process; the password is
never visible to, nor stored by, mas.

Any sudo credentials used or established by mas remain valid after mas finishes,
pursuant to the user-configured sudo timeout.

## App Store Apple Account Requirements

`get`, `install`, `lucky`, `update` & `outdated --accurate` require an Apple
Account signed in to the App Store.

## App Store Apple Account Requirements for `get`

`get` requires an Apple Account signed in to the App Store.

Even when an Apple Account is already signed in to the App Store, the system
security settings might require authenticating the Apple Account for each app
being gotten.

If `System Settings` > `Touch ID & Password` > `Use Touch ID for purchases in
iTunes Store, App Store and Apple Books` is:

- `Enabled`: You must authenticate (via Touch ID or Apple Account password) for
  each app being gotten.
- `Disabled`: If `System Settings` > `Apple Account` > `Media & Purchases` >
  `Free Downloads` is:
  - `Always Require`: You must authenticate (via Apple Account password) for
    each app being gotten.
  - `Never Require`: Apps are gotten without additional authentication.

**Note:** App Store authentication is separate from any macOS user
authentication required to grant root privileges to get apps.

## Outdated-App Detection

In `outdated` & `update`, the determination of whether an app is outdated is
configurable via 2 settings:

- [Minimum macOS Check](#minimum-macos-check)
- [Accuracy](#accuracy)

### Concepts & Constraints

A **release** is a build of an app distributed to users.

A **version** is a label that orders a release relative to all other releases of
the same app.

The [iTunes Search API](https://performance-partners.apple.com/search-api)
reports app data only for the latest release of which it is aware; eventual
consistency delays can prevent the API from knowing about the latest release
available from the App Store.

### Minimum macOS Check

- `--check-min-os` (default): Filters outdated apps to include only those for
  which the release reported by the
  [iTunes Search API](https://performance-partners.apple.com/search-api) is
  compatible with your current macOS.
- `--no-check-min-os`: Does not filter outdated apps. This is useful only when
  multiple newer releases are available, with some compatible with your current
  macOS, but the latest incompatible. With this setting, an app whose latest
  release is newer than the installed release but incompatible with your current
  macOS will:
  - `outdated`: Be reported as outdated, which avoids false negatives, but could
    cause false positives.
  - `update`: Display a dialog offering to install the newest release compatible
    with your current macOS, which might be the installed, or a newer (but not
    the latest), release.

### Accuracy

The 2 outdated-app-detection modes are selectable via mutually exclusive flags:

<!--editorconfig-checker-disable-->
<!--markdownlint-disable line-length-->
| Feature          | `--inaccurate` (default)                                                         | `--accurate`                                 |
|:-----------------|:---------------------------------------------------------------------------------|:---------------------------------------------|
| **Method**       | Query the [iTunes Search API](https://performance-partners.apple.com/search-api) | Initiate App Store download to read metadata |
| **Accuracy**     | Potential false positives or negatives                                           | No false positives or negatives              |
| **Speed**        | Fast (~7ms per app)                                                              | Slow (~175ms per app)                        |
| **Requirements** | [iTunes Search API](https://performance-partners.apple.com/search-api)           | Apple Account signed in to the App Store     |
| **Dialogs**      | Only if `--no-check-min-os`                                                      | Various potential dialogs                    |
| **Hangs**        | None                                                                             | If checking 100+ apps in quick succession    |
<!--markdownlint-enable line-length-->
<!--editorconfig-checker-enable-->

#### `--inaccurate` (default)

The inaccurate mode is optimized to:

- Be fast.
- Avoid hangs.
- Avoid dialogs (as long as `--no-check-min-os` is not supplied).
- Report outdated apps owned by any Apple Account without requiring an Apple
  Account signed in to the App Store (apps can be updated, however, only for an
  Apple Account signed in to the App Store).

It compares an installed app's version with the version reported by the
[iTunes Search API](https://performance-partners.apple.com/search-api) as
[Semantic Versions](https://semver.org), with build metadata adjudicating ties.

This mode suffers from potential false positives & negatives:

- **Inconsistent versions:** For certain apps, the iTunes Search API
  consistently reports a different version for the same release than is reported
  by all other App Store systems & by installed apps, causing false positives or
  negatives.
- **Eventual consistency delays:** Lags between the App Store & the iTunes
  Search API can cause false negatives.

#### `--accurate`

The accurate mode is optimized to avoid false positives & negatives at the
expense of speed, potential hangs & potential dialogs.

It initiates a download of an installed app's latest release from the App Store
to obtain the correct latest version from the download metadata. Subsequent
behavior depends on the command:

- `outdated`: Each download is immediately cancelled; an app is reported as
  outdated if its version differs from the download metadata version.
- `update`: The download is cancelled iff the installed version is the same as
  the download metadata version. Otherwise, the update is allowed to complete.

This mode:

- Connects to the
  [iTunes Search API](https://performance-partners.apple.com/search-api) iff
  `--no-check-min-os` is not supplied.
- Requires an Apple Account signed in to the App Store.
- Opens a dialog:
  - If no Apple Account is signed in to the App Store.
  - For each app owned by a different Apple Account.
  - For each app no longer available from the App Store.
  - If `--no-check-min-os` is supplied, for each app for which the release
    reported by the iTunes Search API is incompatible with your current macOS.
- Can hang: Initiating downloads for dozens of apps is safe, but for hundreds of
  apps can cause the App Store to stop responding. This is likely due to Apple
  rate limiting, for which the exact thresholds, durations & ramifications are
  currently unknown.

## License

Licensed under the [MIT license](LICENSE).

Originally created by Andrew Naylor
([@argon on GitHub](https://github.com/argon) |
[@argon on X](https://x.com/argon)).
