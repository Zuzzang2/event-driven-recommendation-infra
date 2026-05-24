# event-driven-recommendation-infra

유저 행동 기반 추천 시스템 — 인프라 및 배포 설정 레포

## 프로젝트 개요

app 레포에서 빌드된 이미지를 받아 AWS EC2(k3s) 위에 배포하는 GitOps 인프라 레포.
ArgoCD가 이 레포를 감시하며, 변경 감지(OutOfSync) 시 **수동 Sync**로 배포(auto-sync 미사용).

## 기술 스택

| 영역 | 기술 |
|------|------|
| IaC | Terraform (AWS 모듈화) |
| 클러스터 | AWS EC2 t4g.large Spot + k3s |
| GitOps | ArgoCD (resource limits 적용, 수동 Sync) |
| 시크릿 | External Secrets Operator + AWS SSM Parameter Store |
| 모니터링 | Prometheus + Grafana (Loki 미사용, 예정) |
| CD | 수동 Sync (이미지 태그를 매니페스트에 :sha 고정) |

## 레포 역할

```
app 레포 CI → ghcr.io 이미지 push (:sha, :latest)
  → (수동) infra k8s 매니페스트의 image tag 를 새 :sha 로 수정 & commit → main
    → ArgoCD 가 OutOfSync 감지 → UI 에서 수동 Sync → k3s 배포
```
(GitHub Actions CD 자동화/ repository_dispatch 는 의도적으로 미사용 — 수동 Sync 채택)

## 디렉토리 구조

```
terraform/
  modules/
    aws-vpc/        # VPC, subnet, IGW, route table
    aws-sg/         # Security Group (22, 80, 443, 6443)
    aws-ec2/        # t4g.large Spot 인스턴스, EIP
    k3s-bootstrap/  # remote-exec k3s 설치 + kubeconfig fetch
  environments/dev/ # 모듈 호출 진입점

k8s/
  base/<svc>/         # 서비스별 kustomization + (deployment·service·configmap | cronjob)
  overlays/prod/<svc> # 서비스별 오버레이 (ArgoCD Application 이 감시하는 경로)
  base/namespace.yaml # edr ns (수동 ns 생성용; secret 은 ESO 가 관리)

external-secrets/   # SecretStore(aws-ssm) + ExternalSecret(supabase-secret ← SSM)

argocd/
  apps/             # ArgoCD Application 매니페스트 (서비스별 3개, 수동 sync)
  install/values.yaml # ArgoCD helm 리소스 제한

scripts/
  bootstrap.sh      # 클러스터 전체 복구(1커맨드): k3s→ArgoCD→ESO→앱

monitoring/         # (예정) prometheus / grafana
```

## Terraform 사용법

```bash
cd terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars  # AWS 자격증명 입력
terraform init
terraform apply
# 출력된 public_ip로 SSH 접속 확인
ssh -i <key.pem> ubuntu@<public_ip>
kubectl get nodes
```

## EC2 Spot 인스턴스 주의사항

- t4g.large: 2vCPU, 8GB RAM, ARM(Graviton2)
- **Spot 인터럽트 시 인스턴스가 회수되어 클러스터 상태 전체 소실** (자동 재시작 아님)
  → `scripts/bootstrap.sh` 1커맨드로 재기동 (`terraform apply -replace=...k3s_install,...fetch_kubeconfig` + ArgoCD/ESO/앱 재구성). EIP 고정이라 IP 유지
- `max_price`는 On-demand($0.0672/hr) 이하로 설정

## RAM 예산 (8GB 기준)

| 컴포넌트 | 목표 |
|---------|------|
| k3s | ~500MB |
| ArgoCD | limits ~768Mi (실사용 ~180Mi) |
| ESO | ~100Mi |
| Prometheus | ~400MB (retention 3d) |
| Grafana | ~150MB |
| FastAPI 3개 | ~400MB |
| 여유 | ~5.7GB |

## ArgoCD 앱 설정 원칙

```yaml
syncPolicy:
  syncOptions:
    - CreateNamespace=true
  # automated(auto-sync/selfHeal) 미사용 — OutOfSync 시 UI 에서 수동 Sync
```

- `targetRevision: main` 고정, 서비스별 Application 3개
- in-cluster DB 없음 — Supabase 외부 연결
- 시크릿(DATABASE_URL): **ESO 가 AWS SSM 에서 동기화** → `supabase-secret` (git 에 값 없음)

## 주요 규칙

- `terraform.tfvars`는 절대 커밋하지 않음 (AWS 자격증명 포함)
- 시크릿 값은 절대 git 에 넣지 않음 — AWS SSM(`/edr/*`)에 두고 ESO 로 주입
- 이미지 태그는 매니페스트에 `:sha` 로 고정, 새 버전은 수동으로 태그 갱신 & commit
- `main` 브랜치 직접 push 금지, PR 경유
- `Co-Authored-By` 커밋 라인 추가 금지

## 작업 완료 규칙

**어떤 작업을 완료했다면 반드시 `todo.md`의 해당 항목을 `[x]`로 체크한 뒤 다음 작업으로 넘어간다.**
