# Disable the volume keys with keyd

This project installs **keyd** and configures it to ignore the keyboard's
**Volume Up** and **Volume Down** keys. It is intended for people who want a
single copy-and-paste command rather than having to edit Linux configuration
files themselves.

## Install

Open the Terminal app, copy the one command for your Linux version, paste it
into the terminal, and press **Enter**. The command asks GitHub for the
installer; the installer will ask for your password when it needs administrator
permission. Your password is entered in the terminal and usually will not show
as you type.

### Fedora Workstation (standard Fedora with DNF)

```bash
curl -fsSL https://raw.githubusercontent.com/sumit-official/keyd-volume-keys/main/setup-keyd-volume-keys-fedora.sh | bash
```

The Fedora installer uses the community-maintained
[`alternateved/keyd` COPR](https://copr.fedorainfracloud.org/coprs/alternateved/keyd/)
if keyd is not already installed. It does not currently support Fedora Atomic
desktops such as Silverblue or Kinoite.

### Arch Linux and Arch-based systems (including Omarchy)

```bash
curl -fsSL https://raw.githubusercontent.com/sumit-official/keyd-volume-keys/main/setup-keyd-volume-keys.sh | bash
```

## What the installer changes

The installer installs keyd if it is missing and puts this configuration in
`/etc/keyd/default.conf`:

```ini
[ids]
*

[main]
volumeup = noop
volumedown = noop
```

It checks that keyd accepts the configuration, enables keyd to start whenever
the computer starts, and starts or restarts the service now. If a different
`/etc/keyd/default.conf` already exists, it saves a timestamped backup before
replacing it. This replaces that file's contents, so custom keyd mappings in
that file will not remain active; the backup lets you recover them.

The wildcard (`*`) applies the rule to all keyboards that keyd can handle.
Some unusual keyboards or devices may report their volume buttons in a way
keyd cannot intercept.

## If something goes wrong

Run these commands in Terminal to check the configuration and service:

```bash
sudo keyd check /etc/keyd/default.conf
sudo systemctl status keyd --no-pager
```

If the service shows an error, show its recent log with:

```bash
sudo journalctl -u keyd -b --no-pager -n 50
```

Common fixes:

- **`curl: command not found`** — install curl first. On Fedora, run
  `sudo dnf install curl`; on Arch/Omarchy, run `sudo pacman -S curl`. Then
  retry the install command above.
- **`sudo: command not found` or permission denied** — the installer needs an
  administrator account. Use a normal desktop account that is allowed to use
  `sudo`, then retry. If you are using a managed computer, ask its administrator.
- **Fedora reports that `copr` is an unknown command** — install the DNF
  plugins and retry the Fedora command:
  `sudo dnf install dnf5-plugins` (newer Fedora) or
  `sudo dnf install dnf-plugins-core` (older Fedora).
- **A download, package, or COPR error** — check that the computer is online,
  then retry. The Fedora package comes from a community COPR repository; if
  that repository does not provide a package for your Fedora release, the
  installer cannot install keyd through this method.
- **`keyd` is inactive or the volume keys still work** — run the three
  diagnostic commands above. If the configuration check reports a problem,
  run the install command again. If the check passes but keyd will not start,
  the service status and journal commands show the reason. Some keyboards
  expose volume buttons outside the keyboard events keyd can remap.

To turn keyd off and restore normal key behavior immediately, run:

```bash
sudo systemctl disable --now keyd
```

To restore a previous keyd configuration, first find its backup:

```bash
ls -lt /etc/keyd/default.conf.backup.*
```

Then copy the desired backup over the active config (replace the example
timestamp with the one shown by the command) and restart keyd:

```bash
sudo cp -a /etc/keyd/default.conf.backup.YYYYMMDD-HHMMSS /etc/keyd/default.conf
sudo systemctl restart keyd
```
