# 집 MacBook Pro에서 이어서 개발하기

회사 Windows PC에서는 빌드까지만 확인했고, **Mac이 있으면 그 뒤는 Xcode로 직접** 하면 됩니다.
GitHub Actions·Sideloadly·AltStore는 더 이상 필요 없습니다.

```
지금 상태
  Gogs(원본)  http://ds.eamu.info:3000/kkw/ios_develop
  GitHub(미러) https://github.com/kkw83/ios_calcul   ← 집에서 여기서 clone
  Actions 빌드 2회 성공 (서명 없는 IPA 생성 확인 완료)
```

---

## 1. Xcode 설치

1. App Store에서 **Xcode** 설치 (용량 큼, 시간 걸림)
2. 설치 후 한 번 실행 → 라이선스 동의 → 컴포넌트 설치
3. 확인:

```bash
xcodebuild -version      # Xcode 16 이상이면 OK
sw_vers                  # macOS 버전 확인
```

> 이 프로젝트는 `objectVersion = 77` (Xcode 16 형식)이라 **Xcode 15 이하에서는 열리지 않습니다.**
> macOS가 오래됐다면 먼저 업데이트하세요.

---

## 2. 소스 받기

GitHub 미러는 공개 저장소라 인증 없이 clone 됩니다.

```bash
cd ~/Developer          # 없으면 mkdir -p ~/Developer
git clone https://github.com/kkw83/ios_calcul.git calculator
cd calculator
```

Gogs에서 받고 싶다면(사내망 필요):

```bash
git clone http://ds.eamu.info:3000/kkw/ios_develop.git calculator
```

---

## 3. Xcode에서 열고 실행

```bash
open Calculator.xcodeproj
```

1. 좌측 네비게이터에서 프로젝트 `Calculator` 선택 → **TARGETS: Calculator**
2. **Signing & Capabilities** 탭
   - `Automatically manage signing` 체크
   - **Team**: `Add an Account...` → 본인 Apple ID 로그인 후 선택
   - **Bundle Identifier**: `com.example.Calculator` → `com.<본인영문ID>.calculator` 처럼 고유하게 변경
     (무료 계정은 이미 등록된 ID를 재사용할 수 없어 충돌이 납니다)
3. 상단 실행 대상: `Calculator` + **시뮬레이터**(예: iPhone 17) → `⌘R`
   - 시뮬레이터는 Apple ID 서명이 필요 없어서 바로 됩니다.
4. 실기기 설치: iPhone을 USB로 연결
   - iPhone: **이 컴퓨터를 신뢰** → 암호 입력
   - iPhone: 설정 → 개인정보 보호 및 보안 → **개발자 모드** 켜기 → 재시동
   - Xcode 상단 대상에서 본인 iPhone 선택 → `⌘R`

설치 후 아이폰에서 앱이 안 열리면:
설정 → 일반 → **VPN 및 기기 관리** → 개발자 앱 → 본인 Apple ID → **신뢰**

---

## 4. 무료 계정 제약 (알아둘 것)

| 항목 | 무료 Apple ID | 유료 개발자 프로그램 (연 $99) |
|---|---|---|
| 앱 유효 기간 | **7일** (재설치 필요) | 1년 |
| 동시 설치 앱 | 3개 | 제한 없음 |
| 갱신 방법 | Mac에서 `⌘R` 다시 실행 | 만료 없음 |
| TestFlight / 서버 OTA 배포 | ❌ | ✅ |

계산기 앱은 **설치 후 네트워크가 필요 없습니다.** 회사 Wi-Fi가 막혀 있어도 실행·사용은 정상입니다.
PC/Mac이 필요한 건 설치와 7일 갱신 때뿐입니다.

7일마다 집에서 `⌘R` 한 번 다시 눌러주면 됩니다(같은 번들 ID면 기존 앱 위에 덮어씁니다).

유료 계정이 있으면 **서버에 IPA + 설치 링크(OTA)** 를 올려 아이폰에서 바로 설치/업데이트할 수 있습니다.
(자세한 내용은 [SIDELOAD.md](SIDELOAD.md) 참고)

---

## 5. Ollama는 빌드에 필요 없습니다

Xcode가 컴파일·서명·설치를 모두 하므로 **Ollama 없이도 개발이 이어집니다.**
Ollama는 "집에서 로컬 LLM으로 코딩 도우미를 쓰고 싶을 때"만 필요합니다.

로컬 모델을 코딩 에이전트에 붙이려면:

```bash
brew install ollama
ollama serve            # 백그라운드 서버 (11434)
ollama pull qwen2.5-coder:14b    # 16GB RAM 이상 권장 (8GB면 7b)
```

그 다음 VS Code의 Continue, 또는 `opencode` 같은 CLI 클라이언트에서
Ollama를 provider(`http://localhost:11434`)로 등록하면 됩니다.
다만 로컬 모델은 프로젝트 전체를 다루는 작업에서 클라우드 모델보다 약하니,
빌드·설치 확인은 Xcode로 직접 하는 편이 훨씬 빠릅니다.

---

## 6. 집에서 이어서 할 일 체크리스트

- [ ] Xcode 설치 및 `xcodebuild -version` 확인
- [ ] `git clone https://github.com/kkw83/ios_calcul.git`
- [ ] `open Calculator.xcodeproj` → Signing 팀 설정 + 번들 ID 변경
- [ ] 시뮬레이터에서 `⌘R` 실행 확인
- [ ] iPhone USB 연결 → 개발자 모드 → 실기기 `⌘R`
- [ ] 앱 실행 후 계산 기능 점검 (사칙연산, `%`, 공학용 `ƒ`, 기록)
- [ ] 수정 사항 커밋 후 양쪽 push:

```bash
git push origin main      # Gogs
git push github main      # GitHub (Actions 빌드도 자동 실행)
```
