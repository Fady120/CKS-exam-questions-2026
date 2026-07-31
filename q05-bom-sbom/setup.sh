#!/bin/bash
# ============================================================================
# CKS EXAM PRACTICE — Q05: BOM/SBOM Analysis
# ============================================================================

set -e

echo "=================================================================="
echo "  CKS PRACTICE Q05: BOM/SBOM — SUPPLY CHAIN SECURITY"
echo "=================================================================="
echo ""
echo "CONTEXT:"
echo "  A deployment 'alpine-multi' is running in the namespace 'apps'."
echo "  It has 3 containers based on alpine 3.20.0, 3.19.6 and 3.16.1."
echo "  One of them ships a vulnerable version of the libcrypto3 package."
echo ""
echo "TASK:"
echo "  1. Inspect the libcrypto3 package version inside each of the 3"
echo "     containers and identify the vulnerable one (alpine:3.16.1)."
echo "  2. Edit the deployment YAML to REMOVE the container that has"
echo "     the vulnerable libcrypto3 version, then redeploy."
echo "  3. Generate an SPDX SBOM report for the image alpine:3.16.1"
echo "     and save it to /root/sbom-report.spdx"
echo ""
echo "=================================================================="
echo "  Setting up environment..."
echo "=================================================================="

kubectl create namespace apps --dry-run=client -o yaml | kubectl apply -f -

cat <<'EOF' > /tmp/alpine-multi-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: alpine-multi
  namespace: apps
spec:
  replicas: 1
  selector:
    matchLabels:
      app: alpine-multi
  template:
    metadata:
      labels:
        app: alpine-multi
    spec:
      containers:
      - name: container-a
        image: alpine:3.20.0
        command: ["sh", "-c", "sleep 3600"]
      - name: container-b
        image: alpine:3.19.6
        command: ["sh", "-c", "sleep 3600"]
      - name: container-c
        image: alpine:3.16.1
        command: ["sh", "-c", "sleep 3600"]
EOF

kubectl apply -f /tmp/alpine-multi-deploy.yaml

echo ""
echo "Waiting for pods to be ready..."
kubectl wait --for=condition=available deployment/alpine-multi -n apps --timeout=120s 2>/dev/null || true
echo ""

# Check if bom is installed for SBOM generation
if command -v bom &>/dev/null; then
  echo "✅ bom is installed for SBOM generation"
else
  echo "⚠️  bom not installed. Installing..."
  BOM_VER="v0.6.0"
  curl -fsSL "https://github.com/kubernetes-sigs/bom/releases/download/${BOM_VER}/bom-amd64-linux" -o /usr/local/bin/bom 2>/dev/null \
    && chmod +x /usr/local/bin/bom \
    && echo "✅ bom ${BOM_VER} installed" \
    || echo "⚠️  bom install failed — run 'bash install-prereqs.sh' from project root"
fi

echo ""
echo "✅ Environment ready!"
echo ""
echo "Deployment file: /tmp/alpine-multi-deploy.yaml"
echo ""
echo "HINTS:"
echo "  - To check package versions: kubectl exec <pod> -n apps -c <container> -- apk list libcrypto3"
echo "  - To generate SBOM: bom generate --image <image> --output /root/sbom-report.spdx"
echo "  - Save SPDX output to /root/sbom-report.spdx"
echo ""
echo "Run 'bash verify.sh' after solving to check your answer."
