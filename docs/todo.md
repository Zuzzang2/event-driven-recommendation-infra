# event-driven-recommendation-infra TODO

## Week 1 — Terraform 인프라

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

## Week 2 — K8s 매니페스트 + ArgoCD + CD

### K8s 매니페스트
- [ ] `k8s/base/namespace.yaml`
- [ ] `k8s/base/secrets/supabase-secret.yaml` (DATABASE_URL)
- [ ] `k8s/base/event-collector/` — deployment, service, configmap
- [ ] `k8s/base/recommender/` — deployment, service, configmap
- [ ] `k8s/base/recommender-job/cronjob.yaml` — schedule: "*/5 * * * *"
- [ ] `k8s/overlays/prod/kustomization.yaml`

### ArgoCD
- [ ] k3s에 ArgoCD 설치 (helm)
- [ ] `argocd/install/argocd-resource-limits.yaml` — 컴포넌트별 memory limit 적용
- [ ] `argocd/apps/event-collector-app.yaml`
- [ ] `argocd/apps/recommender-app.yaml`
- [ ] `argocd/apps/recommender-job-app.yaml`
- [ ] ArgoCD 대시보드 Synced + Healthy 확인

### GitHub Actions CD
- [ ] `.github/workflows/cd-update-manifest.yaml`
  - [ ] repository_dispatch 수신
  - [ ] deployment.yaml / cronjob.yaml image tag 교체
  - [ ] git commit & push

---

## Week 3 — 모니터링

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

## Week 4 — 마무리

- [ ] README + Mermaid 아키텍처 다이어그램
- [ ] `terraform.tfvars.example` 최종 점검
- [ ] `terraform destroy` → `terraform apply` 재현성 확인
- [ ] 포트폴리오 스크린샷 (ArgoCD, Grafana 대시보드)
