---
description: Git 변경사항을 분석해 프로젝트 규칙에 맞는 커밋 및 dev 반영 수행
allowed-tools: Bash(git:*)
---

## Context

- 현재 상태 확인: !`git status`
- 커밋 대상 변경사항: !`git diff --cached`
- 최근 커밋 스타일 참고: !`git log --oneline -5`

## Commit Rules

| 이모지 | 태그 | 설명 |
|--------|------|------|
| 🚀 | FEAT | 새로운 기능 추가 |
| 🐞 | FIX | 버그 수정 |
| ⚙️ | UPDATE | 코드 및 설정 수정 |
| 📚 | DOCS | 문서 변경 |
| 🎨 | STYLE | 코드 스타일 및 포맷 수정 |
| ♻️ | REFACTOR | 리팩토링 |
| 🧪 | TEST | 테스트 추가 및 수정 |
| 🔄 | CI | CI/CD 변경 |
| 🗑️ | REMOVE | 코드 및 파일 제거 |
| 📦 | DEPS | 의존성 변경 |

## Commit Format

```
<이모지> <TAG>: <제목>

[본문 - 선택]
```

## Message Rules

**제목**
- 반드시 한국어 사용
- 마침표 사용 금지
- 50자 이내 유지
- 짧고 명확하게 작성
- "추가", "수정", "개선", "변경" 표현 우선 사용

**본문** (필요한 경우만)
- 무엇을 변경했는지 설명
- 왜 변경했는지 간단히 작성
- 한 줄 최대 72자 유지

## Workflow

1. 변경사항을 분석해 가장 적절한 태그 선택
2. staged 변경사항이 없으면 자동으로 전체 스테이징: `git add -A`
3. 커밋 메시지 생성 후 `git commit` 실행
4. 현재 브랜치를 origin에 push
5. dev 브랜치로 전환 및 최신화
   ```
   git checkout dev
   git pull origin dev
   ```
6. 기존 작업 브랜치를 dev에 merge: `git merge <원래-작업-브랜치>`
7. `git push origin dev`
8. 원래 작업 브랜치로 복귀

## Branch Rules

- 모든 최종 반영은 `dev` 브랜치 기준으로 진행
- `main` 브랜치는 직접 push 및 merge 금지
- hotfix 상황이 아니면 `main` 작업 금지

## Important

- `Co-Authored-By` 절대 추가 금지
- 최근 커밋 스타일과 최대한 톤 맞추기
- merge conflict 발생 시 즉시 중단 후 현재 상태 설명
- `git push --force`, `git reset --hard` 사용 금지
