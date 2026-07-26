# norville/dotfiles
- [ ] add script to config cachyos
  - edit `/etc/limine-snapper-sync.conf`
    - `MAX_SNAPSHOT_ENTRIES=10`
    - `SNAPSHOT_FORMAT_CHOICE=8`
- [ ] add script to install hypervisor on cachyos
  - install `qemu-full` `virt-manager`
  - `echo 'firewall_backend = "iptables"' | sudo tee -a /etc/libvirt/network.conf`
  - `sudo usermod -aG libvirt $USER`
  - `systemctl enable --now libvirtd.socket`
  - `sudo virsh net-autostart default`
  - `sudo ufw route allow from 192.168.122.0/24`
- [ ] tweak packages installation:

  | SCRIPT | WORKSTATION | TERMINAL | SERVER |
  | --- | --- | --- | --- |
  | 1password | DO NOT PROMPT | DO NOT RUN | DO NOT RUN |
  | vscode | PROMPT | DO NOT RUN | DO NOT RUN |
  | ansible | DO NOT PROMPT | PROMPT | DO NOT RUN |
  | docker | PROMPT | DO NOT RUN | DO NOT RUN |
  | sddm | DO NOT PROMPT | DO NOT RUN | DO NOT RUN |
  | darkman | DO NOT PROMPT | DO NOT RUN | DO NOT RUN |
  | ddcutil | DO NOT PROMPT | DO NOT RUN | DO NOT RUN |
  | syncthing | DO NOT PROMPT | PROMPT | DO NOT RUN |

  | SCRIPT | LINUX | DARWIN |
  | --- | --- | --- |
  | 1password | RUN | RUN |
  | vscode | RUN | RUN |
  | ansible | RUN | RUN |
  | docker | RUN | DO NOT RUN |
  | sddm | RUN | DO NOT RUN |
  | darkman | RUN | DO NOT RUN |
  | ddcutil | RUN | DO NOT RUN |
  | syncthing | RUN | RUN |

- [ ] clean OS references in output messages
- [ ] drop references to Manjaro in code/comments
- [ ] automate macos configuration via 'defaults'
