# event-driven-recommendation-infra TODO

## Terraform 인프라

### Supabase
- [x] Supabase 프로젝트 생성
- [x] events, recommendations 테이블 스키마 적용 (Alembic 마이그레이션)
- [x] Connection String 확인 (Session Pooler)

### Terraform 모듈
- [x] `terraform/versions.tf` — required_providers (aws, null)
- [x] `terraform/modules/aws-vpc/` — VPC, public subnet, IGW, route table
- [x] `terraform/modules/aws-sg/` — Security Group (22, 80, 443, 6443)
- [x] `terraform/modules/aws-ec2/` — t4g.large Spot, key pair, EIP
- [x] `terraform/modules/k3s-bootstrap/` — remote-exec k3s 설치 + kubeconfig fetch
- [x] `terraform/environments/dev/main.tf` — 모듈 호출 (vpc → sg → ec2 → k3s)
- [x] `terraform/environments/dev/terraform.tfvars.example` 작성
- [x] `terraform apply` 실행 → EC2 Spot 생성 확인
- [x] `kubectl get nodes` 확인 (Ready)

---

## K8s 매니페스트 + ArgoCD + CD

### K8s 매니페스트
- [x] `k8s/base/namespace.yaml`
- [x] DATABASE_URL Secret(supabase-secret) — git 미관리, `kubectl`로 클러스터에 직접 생성
- [x] `k8s/base/event-collector/` — deployment, service, configmap
- [x] `k8s/base/recommender/` — deployment, service, configmap
- [x] `k8s/base/recommender-job/cronjob.yaml` — schedule: "*/5 * * * *"
- [x] `k8s/overlays/prod/kustomization.yaml`

### ArgoCD
- [x] k3s에 ArgoCD 설치 (helm)
- [x] `argocd/install/values.yaml` — 컴포넌트별 memory limit(~768Mi) + dex/notifications/applicationSet 비활성
- [x] `argocd/apps/event-collector-app.yaml`
- [x] `argocd/apps/recommender-app.yaml`
- [x] `argocd/apps/recommender-job-app.yaml`
- [x] ArgoCD 대시보드 Synced + Healthy 확인 (3개 앱 모두 Healthy)

### CD (수동 sync 채택 — GitHub Actions 자동화 미진행)
- [x] 이미지 태그를 매니페스트에 고정 (`:sha-XXXX`)
- [x] ArgoCD Application 수동 sync 전환 (auto-sync 제거)
- 새 버전 배포: CI가 새 sha 빌드 → 매니페스트 태그 수정·commit → ArgoCD UI에서 Sync
- ~~`.github/workflows/cd-update-manifest.yaml` (repository_dispatch 자동화)~~ — 의도적 미진행

---

## 모니터링

### Prometheus + Grafana
- [ ] `monitoring/prometheus/values.yaml` — retention: 3d, memory limit: 400Mi
- [ ] helm으로 Prometheus 설치
- [ ] `monitoring/prometheus/rules/inference-alerts.yaml` — p99 > 500ms 알람
- [ ] ServiceMonitor — event-collector, recommender 등록
- [ ] helm으로 Grafana 설치
- [ ] `monitoring/grafana/dashboards/recommendation-pipeline.json`
  - [ ] predict_latency_seconds (p50/p95/p99)
  - [ ] event_collect_requests_total (rate)
  - [ ] recommender_job_duration_seconds

### 검증
- [ ] `kubectl top nodes` / `kubectl top pods -A` — 8GB 이내 확인
- [ ] Prometheus alert firing 확인
- [ ] end-to-end: app push → ghcr.io → infra 커밋 → ArgoCD sync → CronJob 실행

---

## 마무리

- [ ] README + Mermaid 아키텍처 다이어그램
- [ ] `terraform.tfvars.example` 최종 점검
- [ ] `terraform destroy` → `terraform apply` 재현성 확인
- [ ] 포트폴리오 스크린샷 (ArgoCD, Grafana 대시보드)

---

## 백로그 — Spot 자동 재기동 (나중에 작업)

배경: Spot 인스턴스가 자주 회수돼 클러스터가 down → 현재는 매번
`terraform apply -replace="module.k3s.null_resource.k3s_install" -replace="...fetch_kubeconfig"` 수동 복구.
참고: kubeconfig server 주소는 고정 EIP(43.200.40.173)라 IP는 안 바뀜 → EIP 자동 연결만 보장하면 됨.

- [ ] (권장) ASG + Launch Template 전환 — Spot 회수 시 ASG가 자동 인스턴스 교체
  - [ ] `aws-ec2` 모듈을 단일 `aws_instance` → Launch Template + Auto Scaling Group(desired=1, Spot)로 리팩터
  - [ ] k3s 설치를 remote-exec → Launch Template `user_data` 로 이전 (부팅 시 self-bootstrap)
  - [ ] EIP 자동 연결 — IAM instance profile + user_data 에서 `aws ec2 associate-address`
  - [ ] (선택) capacity-optimized 할당 전략 / 다중 인스턴스 타입 풀로 회수 빈도 완화
- [ ] (임시/간단) 워치독 스크립트 — 인스턴스 존재 polling 후 없으면 `terraform apply -replace` 자동 실행
  - 로컬 cron (맥 켜져 있을 때만 동작) 또는 EventBridge(Spot interruption warning) → Lambda/SSM Automation
- [ ] 재기동 후 워크로드 자동 복구 확인 (ArgoCD auto-sync 가 재배포 담당)
