# AudioTX Control — Installer

This repo hosts the install script via GitHub Pages for a short URL.

## Install (latest version)

```bash
curl -fsSL https://brianwynne.github.io/audiotxcontrol-install/install.sh \
  | sudo bash -s -- --token github_pat_xxxxx
```

## Install (specific version)

```bash
curl -fsSL https://brianwynne.github.io/audiotxcontrol-install/install.sh \
  | sudo bash -s -- --tag v1.2.0 --token github_pat_xxxxx
```

## Using GITHUB_TOKEN env var

Set once in your shell profile — no need to pass `--token` every time:

```bash
export GITHUB_TOKEN=github_pat_xxxxx
curl -fsSL https://brianwynne.github.io/audiotxcontrol-install/install.sh | sudo -E bash
```

## Uninstall

```bash
sudo bash install-audiotxcontrol.sh --uninstall
```

## Upgrade

Same as install — the installer auto-detects existing installations and preserves config, databases, and logs.
