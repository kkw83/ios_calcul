# 계산기 (Calculator for iPhone)

SwiftUI로 만든 iPhone용 계산기 앱입니다. iOS 기본 계산기와 비슷한 조작감에
공학용 키패드, 계산 기록, 다크 모드, 햅틱 피드백을 더했습니다.

## 요구 사항

- macOS + Xcode 16 이상
- iPhone 17 시뮬레이터를 쓰려면 Xcode 26 이상
- 배포 대상: iOS 17.0+
- iPhone 전용 (세로 모드)

## 실행 방법

1. `Calculator.xcodeproj`를 Xcode에서 연다.
2. 상단 실행 대상에서 `Calculator` 스킴과 iPhone 시뮬레이터(예: iPhone 17)를 고른다.
3. `⌘R`로 실행한다.
4. 실기기에서 실행하려면 `Signing & Capabilities`에서 팀을 선택하고
   `PRODUCT_BUNDLE_IDENTIFIER`를 본인 것으로 바꾼다.

## Mac 없이 아이폰에서 테스트하기

이 프로젝트의 원본 저장소는 Gogs(`http://ds.eamu.info:3000/kkw/ios_develop`)이며,
Gogs에는 CI가 없습니다. GitHub 미러(`https://github.com/kkw83/ios_calcul`)에
Actions 워크플로가 있어 push하면 서명 없는 IPA를 만들어 줍니다.
Windows에서 AltStore/Sideloadly로 설치하는 방법은 **[SIDELOAD.md](SIDELOAD.md)**,
Mac에서 이어서 개발하는 방법은 **[MAC.md](MAC.md)** 를 참고하세요.

## 기능

- 사칙연산, 퍼센트, 부호 변경, 소수점, 연속 계산(즉시 실행 방식)
- `AC`/`C` 자동 전환, 0으로 나누면 `Error` 표시
- 상단 `ƒ` 버튼으로 공학용 키패드 토글
  - `sin`, `cos`, `tan`, `ln`, `log`, `√`, `x²`, `1/x`, `xʸ`, `π`, `e`
  - `Deg`/`Rad` 각도 단위 전환
- 천 단위 구분자 표시, 자릿수에 따른 글자 크기 자동 조절
- 디스플레이 길게 눌러 결과 복사
- 계산 기록(최근 100개) 저장 및 탭해서 결과 재사용
- 라이트/다크 모드 자동 대응, 버튼 햅틱

## 프로젝트 구조

```
Calculator.xcodeproj
Calculator/
├── CalculatorApp.swift      # 앱 진입점
├── CalculatorView.swift     # 화면 레이아웃, 키패드 구성
├── CalculatorModel.swift    # 계산 엔진 (순수 로직)
├── CalculatorButton.swift   # 공용 버튼 스타일
├── DisplayView.swift        # 수식/결과 디스플레이
├── HistoryView.swift        # 계산 기록 시트
├── CalcNumber.swift         # 숫자 포매팅 유틸리티
├── Theme.swift              # 라이트/다크 색상
├── Haptics.swift            # 햅틱 피드백
└── Assets.xcassets          # 앱 아이콘, 강조 색
```

계산 엔진(`CalculatorModel`)은 UIKit에 의존하지 않으므로 단위 테스트를
추가하기 쉽습니다.

## 커스터마이즈

- 앱 이름: `project.pbxproj`의 `INFOPLIST_KEY_CFBundleDisplayName`
- 번들 ID: 같은 파일의 `PRODUCT_BUNDLE_IDENTIFIER`
- 강조 색: `Assets.xcassets/AccentColor.colorset`
- 키패드 색: `Theme.swift`

## 참고

Xcode 빌드는 GitHub Actions(macos-15)에서 확인되었습니다(성공).
로컬 Windows 환경에는 Swift/Xcode가 없어 실행 검증은 하지 못했으므로,
`MAC.md`의 절차대로 Xcode에서 한 번 실행해 보세요.
