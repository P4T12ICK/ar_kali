# Ansible Role: Attack Range Kali Linux

This role configures TigerVNC server on Kali Linux systems for use with [Attack Range](https://github.com/splunk/attack_range). TigerVNC provides remote desktop access that can be accessed via Apache Guacamole or directly via VNC clients.

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```
ar_kali_password: Pl3ase-k1Ll-me:p
ar_kali_vnc_display: "1"
ar_kali_vnc_resolution: "1920x1080"
```

- `ar_kali_password`: Password used for VNC authentication
- `ar_kali_vnc_display`: VNC display number (default "1" = port 5901)
- `ar_kali_vnc_resolution`: Screen resolution for the VNC session (default "1920x1080")

## Dependencies

None.

## Example Playbook

```yaml
- hosts: kali_linux
  roles:
    - P4T12ICK.ar_kali
```

## What This Role Does

This role performs the following tasks:

1. **Updates package cache**: Refreshes the apt package cache
2. **Installs TigerVNC**: Installs `tigervnc-standalone-server` and `tigervnc-common` packages
3. **Creates VNC directory**: Sets up the `.vnc` directory in the user's home directory
4. **Sets VNC password**: Configures the VNC password using the `ar_kali_password` variable
5. **Creates xstartup script**: Configures the VNC startup script to launch a desktop environment (XFCE, GNOME, or LXDE)
6. **Deploys VNC server manager script**: Installs a script that ensures VNC server stays running
7. **Starts VNC server**: Launches the TigerVNC server on the specified display with the configured resolution and allows external connections
8. **Sets up systemd service**: Creates a systemd service and timer to automatically restart VNC if it stops

## Connecting via Apache Guacamole

To connect to the Kali Linux VNC server via Apache Guacamole, configure a VNC connection with:

- **Protocol**: `vnc`
- **Hostname**: IP address or hostname of the Kali Linux server
- **Port**: `5901` (for display :1, or 5900 + display number)
- **Password**: The value from `ar_kali_password` variable

Example Guacamole connection configuration:
```xml
<connection name="kali_linux">
    <protocol>vnc</protocol>
    <param name="hostname">10.0.1.10</param>
    <param name="port">5901</param>
    <param name="password">Pl3ase-k1Ll-me:p</param>
</connection>
```

## Manual VNC Server Management

To manually start the VNC server (with external connections allowed):
```bash
vncserver :1 -geometry 1920x1080 -depth 24 -localhost no
```

To stop the VNC server:
```bash
vncserver -kill :1
```

To change the VNC password:
```bash
vncpasswd
```

### Using the VNC Server Manager Script

The role installs a VNC server manager script at `/usr/local/bin/vnc-server-manager.sh` that ensures the VNC server is running:

```bash
# Check and start VNC server if needed
/usr/local/bin/vnc-server-manager.sh <username> <display> <resolution>

# Example:
/usr/local/bin/vnc-server-manager.sh kali 1 1920x1080
```

The script automatically:
- Checks if VNC is already running
- Kills stale processes if needed
- Starts VNC with external connections enabled (`-localhost no`)

### Systemd Service Management

The role also sets up a systemd service and timer:

```bash
# Check VNC server status
systemctl status vnc-server.service

# Manually start VNC server
systemctl start vnc-server.service

# Check timer status (runs every 5 minutes to ensure VNC stays running)
systemctl status vnc-server-monitor.timer
```

## License

Apache License 2.0

## Author Information

This role was created by [P4T12ICK](https://github.com/P4T12ICK)
