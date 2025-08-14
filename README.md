# opsys
Install script for new system.
=======
# OPSYS 🛠️ (Yes I took it from Typecraft)

## Prerequisites
- A fresh Arch Linux installation
- A fresh bare Omarchy installation ( wget -qO- https://omarchy.org/install-bare | bash )
- Git and wget installed.
- Internet connection
- sudo privileges

## Installation

1. Install Omarchy bare. Make sure you use btrfs:

```bash
wget -qO- https://omarchy.org/install-bare | bash 
```
2. Clone this repository:

```bash

git clone https://github.com/martinshields/opsys.git
```

3. Run the setup script:

```bash
./run.sh
```
4. After the setup is complete, you can reboot your system to see the changes.

5. Check out Typecrafts video to setup timeshift and btrfs backups.
   [Typecrafts btrfs setup ](https://www.youtube.com/watch?v=V1wxgWU0j0E&t=190s)
