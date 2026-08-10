# Paint Mountain itch.io 브라우저·Windows 자동 배포

이 문서는 itch.io 페이지 안에서 바로 실행되는 Web 알파와 Windows 다운로드 알파를 GitHub Actions로 운영하는 방법을 설명한다.

## 현재 확인된 정보

- itch.io 페이지: <https://itchioprofile1351321.itch.io/paint-mountain>
- itch.io 사용자명: `itchioprofile1351321`
- 프로젝트 slug: `paint-mountain`
- 브라우저 배포 대상: `itchioprofile1351321/paint-mountain:html5`
- Windows 배포 대상: `itchioprofile1351321/paint-mountain:windows-alpha`
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
→ Godot 4.7.1 단일 스레드 Web 빌드와 Windows 빌드
→ itch.io html5 및 windows-alpha 채널 업로드
→ alpha.<GitHub 실행 번호>+<Git 커밋 7자리> 버전 생성
```

문서, 스크린샷 또는 에이전트 기록만 바뀐 커밋은 자동 배포하지 않는다. 짧은 시간에 여러 커밋이 push되면 진행 중인 이전 빌드는 취소하고 최신 빌드만 처리한다. 검증이나 테스트가 실패하면 itch.io에 올리지 않는다.

## 4. itch.io에서 브라우저 실행을 한 번 설정하기

Butler로 `html5` 채널을 처음 올린 뒤 다음 설정은 itch.io 페이지에서 한 번만 한다.

1. itch.io 대시보드에서 `Paint Mountain`의 `Edit game`을 연다.
2. `Kind of project`를 `HTML`로 선택한다.
3. `Uploads`에서 `html5` 채널 빌드의 `This file will be played in the browser`를 선택한다.
4. `Embed options`는 `Click to launch in fullscreen`을 선택한다. 이 게임은 브라우저 크기에 맞춰 캔버스를 조절한다.
5. 변경을 저장한다.

이 설정은 페이지 안에서 게임을 실행하게 만들지만 공개 상태를 바꾸지는 않는다. `Draft`에서는 소유자만 실행할 수 있다.

## 5. 배포 상태 확인

1. [paint-mountain Actions](https://github.com/simpleusername96/paint-mountain/actions)를 연다.
2. `Verify and deploy itch.io alpha` 워크플로를 선택한다.
3. 최신 실행이 녹색 체크로 끝났는지 확인한다.
4. 실행 요약에서 브라우저·Windows 채널, 버전, Git 커밋, Web PCK와 Windows 실행 파일 SHA-256을 확인한다.

필요하면 Actions 화면의 `Run workflow`에서 수동 검증을 실행할 수 있다. `publish`를 선택하지 않으면 검증과 두 빌드만 수행하며 itch.io에는 올리지 않는다. `publish`를 선택하면 검증된 빌드를 `html5`와 `windows-alpha`에 올린다.

첫 Web 실행은 약 1.28GB인 공식 Godot export template 묶음에서 단일 스레드 Web release와 Windows x86-64 release 파일만 추출하므로 평소보다 오래 걸린다. 이후 실행은 GitHub cache에 저장된 템플릿을 재사용한다.

## 6. 자동 배포 도구와 보안

- Godot는 공식 `godotengine/godot-builds`의 `4.7.1-stable`을 사용한다.
- Butler는 공식 `itchio/butler`의 `15.30.0`을 사용한다.
- GitHub Actions와 외부 도구는 고정 버전 또는 고정 커밋으로 실행한다.
- Godot와 Butler 다운로드는 공개된 체크섬과 대조한 뒤 실행한다.
- Web 결과물은 `index.html` 필수 파일, 파일 수, 경로 길이, 전체 500MB와 파일당 200MB 제한을 업로드 전에 검사한다.
- `BUTLER_API_KEY`는 publish 단계에만 전달하며 로그나 빌드 파일에 기록하지 않는다.
- 로컬 Butler 설치와 `butler login`은 필요하지 않다.

## 지금 하지 않아도 되는 작업

첫 브라우저 빌드가 정상적으로 실행될 때까지 다음 항목은 미뤄도 된다.

- itch.io 페이지 공개
- 가격 또는 결제 설정
- 커버 이미지 업로드
- 상세 설명과 태그 작성
- 스크린샷 업로드
- 로컬 Butler 설치 또는 `butler login`

자동 업로드가 확인될 때까지 itch.io 페이지는 `Draft` 상태로 유지한다.
