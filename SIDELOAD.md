# Windows에서 아이폰에 설치하기 (Gogs + GitHub Actions + AltStore)

Mac 없이 Windows만으로 아이폰에 설치하는 방법입니다.

```
내 PC ──push──▶ Gogs (원본, ds.eamu.info:3000)
   └──push──▶ GitHub (미러) ──Actions(macOS 러너)──▶ 서명 없는 IPA
                                                        │
                              AltStore(Windows)가 내 Apple ID로 재서명
                                                        │
                                                     아이폰 설치
```

> **중요:** Gogs에는 CI(Actions) 기능이 없습니다. 그래서 소스는 Gogs에 두고,
> 빌드용 **GitHub 미러 저장소**를 하나 만들어 Actions를 실행합니다.
> GitHub 저장소는 Private으로 만들어도 됩니다.

**현재 연결된 저장소**

| 용도 | 주소 |
|---|---|
| 원본 (Gogs) | http://ds.eamu.info:3000/kkw/ios_develop.git |
| 빌드 미러 (GitHub) | https://github.com/kkw83/ios_calcul |
| 빌드 결과물 | Actions 실행 → Artifacts → `Calculator-ipa` |

무료 Apple ID로도 설치할 수 있지만 **7일마다 다시 서명(Refresh)** 해야 합니다.
(유료 개발자 계정이면 1년 + TestFlight 사용 가능)

---

## 1. 저장소 준비

### 1-A. Gogs (원본) — 현재 상태

로컬 저장소는 이미 초기 커밋과 remote 설정이 끝난 상태입니다.

```powershell
cd C:\Users\user\AI\ios
git push -u origin main
```

- Gogs(`kkw`) 아이디/비밀번호를 입력하면 Windows 자격 증명 관리자에 저장되어
  이후에는 `git push origin main` 만으로 푸시됩니다.
- 이 서버는 **HTTP** 주소이므로 자격 증명이 암호화되지 않습니다.
  가능하면 HTTPS를 쓰거나 Gogs의 액세스 토큰을 사용하세요.
- 이미 push 했다면 이후 수정 사항은:

```powershell
git add .
git commit -m "변경 내용"
git push origin main
```

### 1-B. GitHub 미러 (빌드용) — 설정 완료

`github` remote 가 아래 주소로 등록되어 있습니다.

```powershell
cd C:\Users\user\AI\ios
git remote add github https://github.com/kkw83/ios_calcul.git   # 이미 등록됨
git push -u github main
```

2. 이후 수정 사항은 양쪽에 push:

```powershell
git push origin main
git push github main
```

> GitHub Desktop을 쓰는 경우: `Add local repository` → 이 폴더 선택 →
> `Publish repository` 로 미러를 만들 수 있습니다.

> GitHub를 쓰지 않으려면 Codemagic, Bitrise 같은 외부 macOS CI에
> Gogs의 공개 저장소 URL을 연결하는 방법도 있지만 설정이 더 복잡합니다.

---

## 2. GitHub Actions로 IPA 빌드

1. **GitHub 미러 저장소** → **Actions** 탭
2. `Build unsigned IPA` 워크플로 선택
3. **Run workflow** → `main` 브랜치 → 실행
   (`main`에 push하면 자동으로도 실행됩니다)
4. 1~3분 후 초록 체크가 뜨면 실행 화면 아래 **Artifacts**에서
   `Calculator-ipa` 다운로드
5. 압축을 풀면 **`Calculator-unsigned.ipa`** 가 나옵니다.

> 빌드가 실패하면 같은 화면의 로그 또는 `build-log` 아티팩트를 확인하세요.

CLI로 받는 방법 (GitHub CLI 로그인 상태):

```powershell
gh run download -R kkw83/ios_calcul -n Calculator-ipa -D .\dist
```

---

## 3. Windows에 AltServer 설치

1. **iTunes와 iCloud를 Apple 공식 웹사이트 버전으로 설치**
   - https://www.apple.com/itunes/ , https://support.apple.com/downloads/icloud
   - ⚠️ Microsoft Store 버전은 AltServer가 인식하지 못합니다.
   - Microsoft Store의 **Apple Devices** 앱이 설치되어 있다면 제거하세요.
2. https://altstore.io → **Download AltServer for Windows** → 설치
3. iPhone을 USB로 연결하고, 아이폰에서 **"이 컴퓨터를 신뢰"** 선택
4. Windows 작업 표시줄 트레이의 AltServer 아이콘 클릭
   → **Install AltStore** → 연결된 iPhone 선택 → **Apple ID / 비밀번호** 입력
5. 아이폰: 설정 → 일반 → **VPN 및 기기 관리** → 개발자 앱 → 본인 Apple ID → **신뢰**
6. 아이폰: 설정 → 개인정보 보호 및 보안 → **개발자 모드** 켜기 → 재시동

> AltServer와 아이폰은 **같은 Wi-Fi**에 있어야 합니다.

---

## 4. IPA 설치

1. `Calculator-unsigned.ipa`를 아이폰에서 열 수 있는 위치에 둡니다.
   (iCloud Drive, 이메일 첨부, 파일 앱 등)
2. 아이폰에서 **AltStore** 앱 실행
3. 상단 **My Apps** 탭 → 좌측 상단 **+** → 다운로드한 `.ipa` 선택
4. 설치가 끝나면 홈 화면에 **계산기** 앱이 생깁니다.

### 대안: Sideloadly (Windows에서 바로 설치)

AltStore 대신 [Sideloadly](https://sideloadly.io/)를 쓰면 PC에서 IPA를
아이폰으로 직접 밀어 넣을 수 있습니다. iTunes(웹 버전)만 있으면 되고,
사용법은 `IPA 선택 → Apple ID 입력 → Start` 입니다. 무료 계정 7일 제한은 동일합니다.

---

## 5. 7일마다 갱신

무료 Apple ID 서명은 **7일 후 만료**됩니다.

- PC에서 **AltServer 실행** + 아이폰과 같은 Wi-Fi
- 아이폰 AltStore → **My Apps** → **Refresh All**
- 만료 전에 자동 갱신되도록 AltStore 설정에서 Background Refresh 켜기

무료 계정 제한:
- 동시에 설치 가능한 앱 3개
- 7일마다 App ID 10개까지 등록
- 푸시 알림 등 일부 기능 사용 불가 (이 계산기 앱에는 영향 없음)

---

## 문제 해결

| 증상 | 해결 |
|---|---|
| `git push`에서 아이디/비밀번호 요구 | Gogs 계정으로 로그인. 한 번 저장되면 이후 자동 인증 |
| Gogs push가 401/403 | 저장소 쓰기 권한 확인, Gogs 로그인 상태 확인 |
| AltServer가 아이폰을 못 찾음 | iTunes/iCloud를 Apple 웹 버전으로 재설치, Microsoft Store의 Apple Devices 삭제, USB 케이블/포트 변경, 같은 Wi-Fi 확인 |
| "Unable to install" | iOS 개발자 모드 켜짐 확인, 아이폰 재부팅 후 재시도 |
| 앱이 7일 후 실행 안 됨 | AltStore에서 Refresh (AltServer 실행 필요) |
| 설치 중 bundle ID 충돌 | `project.pbxproj`의 `PRODUCT_BUNDLE_IDENTIFIER`를 `com.<본인ID>.calculator`처럼 고유하게 변경 후 다시 빌드 |
| Actions 빌드 실패 | 실행 로그의 `error:` 부분 또는 `build-log` 아티팩트 확인 |
| "maximum number of apps ... reached" | 기존 무료 서명 앱 삭제 후 재시도, 또는 유료 계정 |

---

## 참고

- 이 워크플로는 **서명하지 않은 IPA**를 만듭니다. 서명은 AltStore/Sideloadly가
  본인 Apple ID로 수행합니다.
- TestFlight처럼 케이블 없이 장기간 쓰려면 Apple Developer Program(연 $99)이 필요합니다.
- CI 러너는 `macos-15`(Xcode 16 이상)를 사용합니다. 프로젝트의 배포 대상은 iOS 17+입니다.
