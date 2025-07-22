#!/bin/bash

set -e

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

echo "==> Installing minimal KDE Plasma (no bloat)..."
sudo pacman -S --noconfirm plasma-meta dolphin konsole kde-gtk-config sddm \
    xdg-desktop-portal xdg-desktop-portal-kde

echo "==> Enabling SDDM login manager..."
sudo systemctl enable sddm.service

echo "==> Installing AMD GPU + Vulkan + Wayland support..."
sudo pacman -S --noconfirm mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon xf86-video-amdgpu

echo "==> Installing gaming tools (Steam, Wine, Proton, etc)..."
sudo pacman -S --noconfirm steam steam-native-runtime gamemode mangohud lib32-mangohud \
    lutris wine-staging wine-gecko wine-mono winetricks

echo "==> Installing Flatpak + Heroic Games Launcher..."
sudo pacman -S --noconfirm flatpak
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install -y flathub com.heroicgameslauncher.hgl

echo "==> Installing yay AUR helper..."
if ! command -v yay >/dev/null; then
    sudo pacman -S --noconfirm --needed git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
fi

echo "==> Installing Sunshine (Moonlight-compatible game streaming)..."
yay -S --noconfirm sunshine-git

echo "==> Installing vkBasalt (post-processing filter)..."
yay -S --noconfirm vkbasalt lib32-vkbasalt

echo "==> Enabling performance services..."
sudo systemctl enable gamemoded.service

echo "==> Setting inverted scroll direction in KDE..."
mkdir -p ~/.config
kwriteconfig5 --file kcminputrc --group "Mouse" --key "ReverseScrollPolarity" "true"

echo "==> Cleaning up orphan packages..."
sudo pacman -Rns $(pacman -Qdtq) || true

echo "==> All done. Reboot to start KDE + Wayland with a clean gaming setup."
