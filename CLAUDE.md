# event-driven-recommendation-infra

유저 행동 기반 추천 시스템 — 인프라 및 배포 설정 레포

## 프로젝트 개요

app 레포에서 빌드된 이미지를 받아 AWS EC2(k3s) 위에 배포하는 GitOps 인프라 레포.
ArgoCD가 이 레포를 감시하며 변경 감지 시 자동 배포.

## 기술 스택

| 영역 | 기술 |
|------|------|
| IaC | Terraform (AWS 모듈화) |
| 클러스터 | AWS EC2 t4g.large Spot + k3s |
| GitOps | ArgoCD (resource limits 적용) |
| 모니터링 | Prometheus + Grafana (Loki 미사용) |
| CD | GitHub Actions (image tag 업데이트 → commit) |

## 레포 역할

```
app 레포 CI → ghcr.io 이미지 push
  → repository_dispatch 수신
    → cd-update-manifest.yaml
      → k8s/base/{service}/deployment.yaml image tag 교체
      → git commit & push → main
        → ArgoCD 감지 → k3s auto-sync
```

## 디렉토리 구조

```
terraform/
  modules/
    aws-vpc/        # VPC, subnet, IGW, route table
    aws-sg/         # Security Group (22, 80, 443, 6443)
    aws-ec2/        # t4g.large Spot 인스턴스, EIP
    k3s-bootstrap/  # remote-exec k3s 설치 + kubeconfig fetch
  environments/dev/ # 모듈 호출 진입점

k8s/base/
  event-collector/  # deployment, service, configmap
  recommender/      # deployment, service, configmap
  recommender-job/  # cronjob (schedule: "*/5 * * * *")
  secrets/          # supabase-secret (DATABASE_URL)

argocd/
  apps/             # ArgoCD Application 매니페스트
  install/          # resource limits 설정

monitoring/
  prometheus/       # values.yaml (retention: 3d, memory: 400Mi), alert rules
  grafana/          # 대시보드 JSON
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
- Spot 인터럽트 발생 시 k3s 자동 재시작됨 (dev/포트폴리오 환경 허용)
- `max_price`는 On-demand($0.0672/hr) 이하로 설정

## RAM 예산 (8GB 기준)

| 컴포넌트 | 목표 |
|---------|------|
| k3s | ~500MB |
| ArgoCD | ~800MB (limits 적용) |
| Prometheus | ~400MB (retention 3d) |
| Grafana | ~150MB |
| FastAPI 3개 | ~400MB |
| 여유 | ~5.7GB |

## ArgoCD 앱 설정 원칙

```yaml
syncPolicy:
  automated:
    prune: true
    selfHeal: true
```

- `targetRevision: main` 고정
- in-cluster DB 없음 — Supabase 외부 연결 (DATABASE_URL Secret)

## 주요 규칙

- `terraform.tfvars`는 절대 커밋하지 않음 (AWS 자격증명 포함)
- `k8s/base/*/deployment.yaml`의 image tag는 CD 워크플로우가 자동 업데이트 — 직접 수정 금지
- `main` 브랜치 직접 push 금지, PR 또는 CD 워크플로우 경유
- `Co-Authored-By` 커밋 라인 추가 금지

## 작업 완료 규칙

**어떤 작업을 완료했다면 반드시 `todo.md`의 해당 항목을 `[x]`로 체크한 뒤 다음 작업으로 넘어간다.**
