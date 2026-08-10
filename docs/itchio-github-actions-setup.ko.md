# Paint Mountain itch.io 자동 배포 준비

이 문서는 itch.io의 `Paint Mountain` 페이지를 GitHub Actions 자동 배포에 연결하기 위해 사용자가 한 번만 해야 할 작업을 설명한다.

## 현재 확인된 정보

- itch.io 페이지: <https://itchioprofile1351321.itch.io/paint-mountain>
- itch.io 사용자명: `itchioprofile1351321`
- 프로젝트 slug: `paint-mountain`
- 자동 배포 대상: `itchioprofile1351321/paint-mountain:windows-alpha`
- 현재 공개 상태: `Draft` 유지
- GitHub 저장소: <https://github.com/simpleusername96/paint-mountain>

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

## 3. Codex에 완료 알리기

등록이 끝나면 다음 문장을 보낸다.

```text
BUTLER_API_KEY 등록 완료. master push 자동 알파 배포를 구현해줘.
```

그러면 다음 자동 배포 흐름을 저장소에 추가할 수 있다.

```text
master에 게임 변경 push
→ GitHub Actions 검증
→ Godot 4.7.1 Windows 빌드
→ itch.io windows-alpha 채널 업로드
→ 실행 번호와 Git 커밋 기반 버전 생성
```

## 지금 하지 않아도 되는 작업

첫 자동 빌드가 정상적으로 업로드될 때까지 다음 항목은 미뤄도 된다.

- itch.io 페이지 공개
- 가격 또는 결제 설정
- 커버 이미지 업로드
- 상세 설명과 태그 작성
- 스크린샷 업로드
- 로컬 Butler 설치 또는 `butler login`

자동 업로드가 확인될 때까지 itch.io 페이지는 `Draft` 상태로 유지한다.
