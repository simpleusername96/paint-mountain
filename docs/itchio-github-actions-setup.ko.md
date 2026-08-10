# Paint Mountain itch.io 자동 배포 준비

이 문서는 itch.io의 `Paint Mountain` 페이지와 GitHub Actions 자동 알파 배포를 운영하는 방법을 설명한다.

## 현재 확인된 정보

- itch.io 페이지: <https://itchioprofile1351321.itch.io/paint-mountain>
- itch.io 사용자명: `itchioprofile1351321`
- 프로젝트 slug: `paint-mountain`
- 자동 배포 대상: `itchioprofile1351321/paint-mountain:windows-alpha`
- 현재 공개 상태: `Draft` 유지
- GitHub 저장소: <https://github.com/simpleusername96/paint-mountain>
- GitHub Actions Secret: `BUTLER_API_KEY` 등록 완료

## 1. itch.io API 키 만들기

1. itch.io에 로그인한다.
2. [itch.io API Keys 설정](https://itch.io/user/settings/api-keys)을 연다.
3. `Generate new API key`를 누른다.
4. 이름을 입력할 수 있다면 다음 이름을 사용한다.

   ```text
   github-actions-paint-mountain
   ```

5. 생성된 API 키를 복사한다.

> API 키는 비밀번호와 같은 비밀 정보다. 채팅, 문서, 코드 또는 Git 커밋에 붙여 넣지 않는다.

## 2. GitHub Actions Secret으로 저장하기

1. [paint-mountain Actions Secrets](https://github.com/simpleusername96/paint-mountain/settings/secrets/actions)를 연다.
2. `New repository secret`을 누른다.
3. 다음과 같이 입력한다.

   ```text
   Name: BUTLER_API_KEY
   Secret: 방금 복사한 itch.io API 키
   ```

4. `Add secret`을 누른다.
5. Secret 목록에 `BUTLER_API_KEY`라는 이름이 표시되는지 확인한다.

저장된 Secret의 실제 값이 다시 표시되지 않는 것은 정상이다.

## 3. 자동 배포 활성화

자동 배포 워크플로는 `.github/workflows/itch-alpha.yml`에 있다. 이 파일이 `master`에 병합된 뒤 게임 코드나 에셋이 포함된 커밋을 `master`에 push하면 다음 흐름이 자동으로 실행된다.

```text
master에 게임 변경 push
→ Godot 4.7.1 프로젝트 검증과 전체 headless 테스트
→ Godot 4.7.1 Windows 빌드
→ itch.io windows-alpha 채널 업로드
→ alpha.<GitHub 실행 번호>+<Git 커밋 7자리> 버전 생성
```

문서, 스크린샷 또는 에이전트 기록만 바뀐 커밋은 자동 배포하지 않는다. 짧은 시간에 여러 커밋이 push되면 진행 중인 이전 빌드는 취소하고 최신 빌드만 처리한다. 검증이나 테스트가 실패하면 itch.io에 올리지 않는다.

## 4. 배포 상태 확인

1. [paint-mountain Actions](https://github.com/simpleusername96/paint-mountain/actions)를 연다.
2. `Verify and deploy itch.io alpha` 워크플로를 선택한다.
3. 최신 실행이 녹색 체크로 끝났는지 확인한다.
4. 실행 요약에서 itch.io 채널, 버전, Git 커밋, Windows 실행 파일 SHA-256을 확인한다.

필요하면 Actions 화면의 `Run workflow`에서 수동 검증을 실행할 수 있다. `publish`를 선택하지 않으면 검증과 빌드만 수행하며 itch.io에는 올리지 않는다. `publish`를 선택하면 검증된 빌드를 `windows-alpha`에 올린다.

첫 실행은 약 1.28GB인 공식 Godot export template 묶음을 받아 Windows용 파일만 추출하므로 평소보다 오래 걸린다. 이후 실행은 GitHub cache에 저장된 Windows 템플릿을 재사용한다.

## 5. 자동 배포 도구와 보안

- Godot는 공식 `godotengine/godot-builds`의 `4.7.1-stable`을 사용한다.
- Butler는 공식 `itchio/butler`의 `15.30.0`을 사용한다.
- GitHub Actions와 외부 도구는 고정 버전 또는 고정 커밋으로 실행한다.
- Godot와 Butler 다운로드는 공개된 체크섬과 대조한 뒤 실행한다.
- `BUTLER_API_KEY`는 publish 단계에만 전달하며 로그나 빌드 파일에 기록하지 않는다.
- 로컬 Butler 설치와 `butler login`은 필요하지 않다.

## 지금 하지 않아도 되는 작업

첫 자동 빌드가 정상적으로 업로드될 때까지 다음 항목은 미뤄도 된다.

- itch.io 페이지 공개
- 가격 또는 결제 설정
- 커버 이미지 업로드
- 상세 설명과 태그 작성
- 스크린샷 업로드
- 로컬 Butler 설치 또는 `butler login`

자동 업로드가 확인될 때까지 itch.io 페이지는 `Draft` 상태로 유지한다.
