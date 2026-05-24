#!/usr/bin/env bash
# 클러스터 전체 복구 부트스트랩 (idempotent)
#   bare k3s → ArgoCD(helm) → External Secrets Operator(helm) → edr ns
#   → SecretStore/ExternalSecret(SSM → supabase-secret) → Application 3개 → 초기 Sync
#
# 시크릿 실제 값은 AWS SSM(/edr/supabase/database_url, SecureString)에 있고 ESO가 클러스터로 동기화한다.
# Spot 회수로 클러스터가 초기화돼도 이 스크립트 한 번이면 시크릿 포함 전체 복구(수동 주입 0).
#   사용: ./scripts/bootstrap.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform/environments/dev"
APPS_DIR="$REPO_ROOT/argocd/apps"
ES_DIR="$REPO_ROOT/external-secrets"
VALUES="$REPO_ROOT/argocd/install/values.yaml"
EIP="43.200.40.173"   # 고정 EIP (terraform output ec2_public_ip)
export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/k3s-config}"

# --- 1. 클러스터 응답 없으면 terraform 재기동 (인스턴스 + k3s, IAM instance profile 자동 재부착) ---
if ! kubectl get nodes &>/dev/null; then
  echo "▶ 클러스터 응답 없음 → terraform 재기동 (instance + k3s 재설치)"
  ssh-keygen -R "$EIP" 2>/dev/null || true
  terraform -chdir="$TF_DIR" apply -auto-approve \
    -replace="module.k3s.null_resource.k3s_install" \
    -replace="module.k3s.null_resource.fetch_kubeconfig"
else
  echo "▶ 클러스터 응답 있음 → terraform 재기동 생략"
fi

echo "▶ 노드 Ready 대기"
kubectl wait --for=condition=Ready nodes --all --timeout=180s

# --- 2. ArgoCD (idempotent) ---
echo "▶ ArgoCD 설치/업그레이드"
helm repo add argo https://argoproj.github.io/argo-helm --force-update >/dev/null
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  -f "$VALUES" --wait --timeout 5m
echo "▶ ArgoCD admin 비밀번호 = admin (localhost port-forward 전용)"
HASH="$(htpasswd -nbBC 10 "" admin | tr -d ':\n')"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
kubectl -n argocd patch secret argocd-secret \
  -p "{\"stringData\":{\"admin.password\":\"$HASH\",\"admin.passwordMtime\":\"$NOW\"}}"
kubectl -n argocd rollout restart deploy/argocd-server
kubectl -n argocd rollout status deploy/argocd-server --timeout=120s

# --- 3. External Secrets Operator (idempotent) ---
echo "▶ External Secrets Operator 설치/업그레이드"
helm repo add external-secrets https://charts.external-secrets.io --force-update >/dev/null
helm repo update external-secrets >/dev/null
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --set installCRDs=true --wait --timeout 5m

# --- 4. edr 네임스페이스 + ExternalSecret (SSM → supabase-secret) ---
echo "▶ edr 네임스페이스 + ExternalSecret(SSM 동기화)"
kubectl create namespace edr --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$ES_DIR"
kubectl -n edr wait --for=condition=Ready externalsecret/supabase-secret --timeout=120s || true

# --- 5. ArgoCD Application 적용 ---
echo "▶ ArgoCD Application 적용"
kubectl apply -f "$APPS_DIR"

# --- 6. 초기 Sync 트리거 (수동 sync 앱을 1회 동기화) ---
echo "▶ 초기 Sync 트리거"
for app in event-collector recommender recommender-job; do
  kubectl -n argocd patch application "$app" --type merge \
    -p "{\"operation\":{\"initiatedBy\":{\"username\":\"bootstrap\"},\"sync\":{\"revision\":\"main\"}}}" 2>/dev/null || true
done

echo "✅ 복구 완료 (시크릿은 SSM→ESO로 자동 주입, 수동 입력 없음)"
echo "   UI: kubectl -n argocd port-forward svc/argocd-server 8080:443  →  https://localhost:8080 (admin/admin)"
echo "   상태: kubectl -n argocd get applications ; kubectl -n edr get pods"
