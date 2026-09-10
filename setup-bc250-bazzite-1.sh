#!/bin/bash
set -euo pipefail

# https://elektricm.github.io/amd-bc250-docs/bios/flashing/#post-flash-configuration

# memcfg
git clone https://github.com/fanoush/bc250_memcfg
cd bc250_memcfg
make
sudo ./bc250memcfg UMA_SIZE 512

# amd iommu off
rpm-ostree kargs --append-if-missing=amd_iommu=off
rpm-ostree kargs --append-if-missing=quiet

# kernel parameters for maximum GPU memory access (16GB / full physical pool)
rpm-ostree kargs \
  --delete-if-present="amdgpu.gttsize=14750" \
  --delete-if-present="ttm.pages_limit=3959290" \
  --delete-if-present="ttm.page_pool_size=3959290" \
  --append="ttm.pages_limit=4194304" \
  --append="ttm.page_pool_size=4194304"

# gpu governor & radeontop
sudo dnf copr enable filippor/bazzite -y
rpm-ostree install cyan-skillfish-governor-smu radeontop

# acpi fix (C-states only, P-states doesn't work per upstream README)
[ -d bc250-acpi-fix-updated-8c ] || git clone https://github.com/mendesrr/bc250-acpi-fix-updated-8c
sudo mkdir -p /etc/dracut.conf.d/acpi/
sudo cp bc250-acpi-fix-updated-8c/SSDT-CST.aml /etc/dracut.conf.d/acpi/
cat <<EOF | sudo tee /etc/dracut.conf.d/99-acpi-override.conf
acpi_override="yes"
acpi_table_dir="/etc/dracut.conf.d/acpi"
EOF
if rpm-ostree initramfs | grep -q "enabled"; then
  sudo rpm-ostree initramfs-etc --force-sync
else
  sudo rpm-ostree initramfs --enable
fi

echo ""
echo "Done. Please reboot."
