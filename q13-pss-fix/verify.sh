#!/bin/bash
# ============================================================================
# CKS Q13: Pod Security Standards — Verify Solution
# ============================================================================

PASS=0; FAIL=0
check() {
  if eval "$2" &>/dev/null; then
    echo "✅ PASS: $1"; ((PASS++))
  else
    echo "❌ FAIL: $1"; ((FAIL++))
  fi
}

echo "=================================================================="
echo "  VERIFYING Q13: POD SECURITY STANDARDS (PSS)"
echo "=================================================================="
echo ""

# Check namespace has PSS restricted enforcement
check "'restricted' namespace has PSS enforce=restricted label" \
  'kubectl get ns restricted -o jsonpath="{.metadata.labels}" 2>/dev/null | grep -q "pod-security.kubernetes.io/enforce.*restricted"'

# Check deployment exists and pods are running
check "Deployment exists in 'restricted' namespace" \
  'kubectl get deploy -n restricted --no-headers 2>/dev/null | grep -q "."'

check "Pods are running in 'restricted' namespace" \
  'kubectl get pods -n restricted --no-headers 2>/dev/null | grep -q "Running"'

# Check security context fixes
# Read the actual field values with jsonpath instead of grepping formatted JSON,
# which never matched: kubectl prints "allowPrivilegeEscalation": false (quoted key + space).
jp() { kubectl get deploy -n restricted -o jsonpath="$1" 2>/dev/null; }
CTR=".items[*].spec.template.spec.containers[*].securityContext"
POD=".items[*].spec.template.spec.securityContext"

CTR_APE=$(jp "{$CTR.allowPrivilegeEscalation}")
CTR_RANR=$(jp "{$CTR.runAsNonRoot}")
POD_RANR=$(jp "{$POD.runAsNonRoot}")
CTR_DROP=$(jp "{$CTR.capabilities.drop}")
CTR_PRIV=$(jp "{$CTR.privileged}")
CTR_RAU=$(jp "{$CTR.runAsUser}")
POD_RAU=$(jp "{$POD.runAsUser}")
SECCOMP=$(jp "{$CTR.seccompProfile.type} {$POD.seccompProfile.type}")

check "Container has allowPrivilegeEscalation: false" \
'[ -n "$CTR_APE" ] && ! echo "$CTR_APE" | grep -qw "true"'

check "runAsNonRoot: true (container or pod level)" \
'echo "$CTR_RANR $POD_RANR" | grep -qw "true"'

check "Container drops ALL capabilities" \
'echo "$CTR_DROP" | grep -q "ALL"'

check "Container does NOT have privileged: true" \
'! echo "$CTR_PRIV" | grep -qw "true"'

check "Container does NOT run as user 0 (root)" \
'! echo "$CTR_RAU $POD_RAU" | grep -qw "0"'

check "seccompProfile is set (RuntimeDefault or Localhost)" \
'echo "$SECCOMP" | grep -Eq "RuntimeDefault|Localhost"'

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] && echo "🎉 All checks passed!" || exit 1
