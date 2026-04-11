#!/bin/bash
# ============================================================
# generate_inventory.sh
# Génère automatiquement l'inventaire Ansible (hosts.yml)
#
# Deux modes de fonctionnement :
#   1. Fichier terraform_ips.json présent → lecture directe
#   2. Sinon → appel terraform output depuis terraform/app
#
# Prérequis :
#   - reproduce_infra.sh exécuté avec succès
#   - jq installé (sudo apt install jq)
#
# Utilisation :
#   bash inventaire/generate_inventory.sh
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_FILE="$SCRIPT_DIR/hosts.yml"
IPS_FILE="$SCRIPT_DIR/terraform_ips.json"
SSH_USER="ubuntu"
# Clé SSH attendue dans ~/.ssh/
SSH_KEY="$HOME/.ssh/projet-fil-rouge-key.pem"

echo "🔍 Environnement : Vagrant Linux"

# --------------------------------------------------------
# Récupération des IPs
# Mode 1 : fichier JSON pré-généré par reproduce_infra.sh
# Mode 2 : appel direct terraform
# --------------------------------------------------------
if [ -f "$IPS_FILE" ]; then
    echo "📄 Lecture depuis terraform_ips.json..."
    TF_OUTPUT=$(cat "$IPS_FILE")
else
    echo "⚙️  Appel terraform output..."
    TERRAFORM_DIR="$REPO_DIR/terraform/app"
    cd "$TERRAFORM_DIR" || { echo "❌ Dossier Terraform introuvable : $TERRAFORM_DIR"; exit 1; }
    TF_OUTPUT=$(terraform output -json public_ips 2>/dev/null)
fi

if [ -z "$TF_OUTPUT" ] || [ "$TF_OUTPUT" = "null" ]; then
    echo "❌ Aucune IP trouvée."
    echo "   → Lancer d'abord : bash reproduce_infra.sh"
    exit 1
fi

JENKINS_IP=$(echo "$TF_OUTPUT" | jq -r '.jenkins')
WEBAPP_IP=$(echo "$TF_OUTPUT"  | jq -r '.webapp')
ODOO_IP=$(echo "$TF_OUTPUT"    | jq -r '.odoo')

echo "✅ IPs récupérées :"
echo "   jenkins : $JENKINS_IP"
echo "   webapp  : $WEBAPP_IP"
echo "   odoo    : $ODOO_IP"

cat > "$OUTPUT_FILE" << YAML
---
# ============================================================
# Inventaire Ansible — généré automatiquement
# Source : terraform output public_ips
# Ne pas modifier manuellement, relancer generate_inventory.sh
# ============================================================

all:
  vars:
    ansible_user: $SSH_USER
    ansible_ssh_private_key_file: $SSH_KEY
    ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

  children:
    jenkins:
      hosts:
        jenkins_server:
          ansible_host: $JENKINS_IP

    webapp:
      hosts:
        webapp_server:
          ansible_host: $WEBAPP_IP

    odoo:
      hosts:
        odoo_server:
          ansible_host: $ODOO_IP
YAML

echo "✅ Inventaire généré : $OUTPUT_FILE"
