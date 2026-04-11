#!/bin/bash
# ============================================================
# bootstrap.sh — Installation des prerequis
# A lancer une seule fois sur la VM Vagrant
#
# Installe si absent (skip si deja present) :
#   - Terraform
#   - AWS CLI
#   - jq
#   - Ansible + collection community.docker
#
# Utilisation :
#   bash bootstrap.sh
# ============================================================

set -e

echo "============================================================"
echo " Bootstrap — Installation des prerequis"
echo "============================================================"

# --------------------------------------------------------
# Mise a jour des paquets
# --------------------------------------------------------
echo ""
echo "[1/5] Mise a jour des paquets..."
sudo apt update -y
echo "✅ Paquets mis a jour"

# --------------------------------------------------------
# Installation de jq
# --------------------------------------------------------
echo ""
echo "[2/5] jq..."
if command -v jq &>/dev/null; then
    echo "⏭️  jq deja installe : $(jq --version)"
else
    sudo apt install -y jq
    echo "✅ jq $(jq --version) installe"
fi

# --------------------------------------------------------
# Installation de Terraform
# --------------------------------------------------------
echo ""
echo "[3/5] Terraform..."
if command -v terraform &>/dev/null; then
    echo "⏭️  Terraform deja installe : $(terraform --version | head -1)"
else
    sudo apt install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update -y
    sudo apt install -y terraform
    echo "✅ $(terraform --version | head -1) installe"
fi

# --------------------------------------------------------
# Installation de AWS CLI
# --------------------------------------------------------
echo ""
echo "[4/5] AWS CLI..."
if command -v aws &>/dev/null; then
    echo "⏭️  AWS CLI deja installe : $(aws --version)"
else
    sudo apt install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
    unzip -q /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/awscliv2.zip /tmp/aws
    echo "✅ $(aws --version) installe"
fi

# --------------------------------------------------------
# Installation de Ansible
# --------------------------------------------------------
echo ""
echo "[5/5] Ansible..."
if command -v ansible &>/dev/null; then
    echo "⏭️  Ansible deja installe : $(ansible --version | head -1)"
else
    sudo apt install -y ansible
    echo "✅ $(ansible --version | head -1) installe"
fi

# Collection community.docker — verifiee separement
if ansible-galaxy collection list | grep -q "community.docker"; then
    echo "⏭️  Collection community.docker deja presente"
else
    ansible-galaxy collection install community.docker --upgrade
    echo "✅ Collection community.docker installee"
fi

# --------------------------------------------------------
# Recapitulatif
# --------------------------------------------------------
echo ""
echo "============================================================"
echo " Bootstrap termine !"
echo "============================================================"
echo ""
echo " Versions disponibles :"
echo "   Terraform : $(terraform --version | head -1)"
echo "   AWS CLI   : $(aws --version)"
echo "   jq        : $(jq --version)"
echo "   Ansible   : $(ansible --version | head -1)"
echo ""
echo " Prochaine etape :"
echo "   aws configure              # Configurer les credentials AWS"
echo "   cp projet-fil-rouge-key.pem ~/.ssh/"
echo "   bash reproduce_infra.sh    # Partie 2 - Provisioning AWS"
echo "============================================================"
