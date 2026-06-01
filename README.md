# 물리전자공학 II: Short Channel MOSFET Analysis & Design Project

[![Sogang University](https://img.shields.io/badge/Sogang-University-red.svg)](https://www.sogang.ac.kr/)
[![TCAD-Sentaurus](https://img.shields.io/badge/TCAD-Sentaurus-blue.svg)](#)
[![Academic-Project](https://img.shields.io/badge/Academic-Project-green.svg)](#)

본 저장소는 서강대학교 전자공학과 **물리전자공학 II (담당 교수: 김시현 교수님)** 과목의 설계 프로젝트 과제를 관리하는 리포지토리입니다. 

Sentaurus TCAD(sde, sdevice) 시뮬레이터를 활용하여 **단채널(Short Channel) MOSFET에서 발생하는 물리적 비이상 현상을 분석**하고, 이를 억제하기 위한 **최적의 MOSFET 소자 구조를 제안 및 설계**하는 것을 목표로 합니다.

---

## 📂 1. Directory Structure (디렉토리 구성)

본 프로젝트는 모듈화된 폴더 구조를 통해 시뮬레이션 소스 코드와 강의 자료, 결과 보고서를 나누어 체계적으로 관리하고 있습니다.

```text
PE2_MOSFET_Project/
├── SRC/                     # TCAD 시뮬레이션 원본 소스 코드 (.cmd)
│   ├── 1. sde_dvs.cmd       # Sentaurus Structure Editor (소자 구조 및 메쉬 정의)
│   ├── 2. sdevice_IdVd.cmd  # Sentaurus Device (Id-Vd 특성 추출 덱)
│   └── 3. sdevice_IdVg.cmd  # Sentaurus Device (Id-Vg 특성 추출 및 GIDL/SS용 덱)
├── Course_Reference/        # 수업 시간에 제공된 설계 템플릿 및 시뮬레이션 가이드
│   ├── 실습/                # 기본 예제 스크립트 및 튜토리얼 정리 파일
│   └── *.pdf, *.pptx        # 공식 강의 매뉴얼 및 보고서 템플릿 (.docx)
├── Reference/               # 학술 연구 및 물리적 타당성 검증용 데이터시트
│   └── Intel386TM SX Microprocessor_datasheet.pdf  # 1um 공정 기준점 자료
├── Report/                  # 최종 설계 결과 보고서 제출 및 작성 공간
└── README.md                # 본 안내서
```

---

## ⚡ 2. MOSFET Device Specification (표준 소자 파라미터)

시뮬레이션의 기준이 되는 2D MOSFET의 기본 구조와 도핑 사양은 아래와 같습니다.

### 2D MOSFET 소자 개요도
```text
         [Gate (TiN)] (Workfunction = 4.6 eV)
     ┌────────────────────────┐
     │    Gate Oxide (SiO2)   │ ↕ Tox = 20 nm (0.02 μm)
 ┌───┴────────────────────────┴───┐
 │ Source (Nsd) │   Body (Nbody)  │ │ Drain (Nsd)    │ ↕ Tsd = 0.3 μm
 └──────────────┤                 ├────────────────┘
                 │   Boron Doped   │ ↕ Tbody = 1.2 μm
                 └─────────────────┘
 ◀── Lsd = 0.5 ──▶◀─── Lg = 1 ────▶ (Unit: μm)
```

### 기본 물리 파라미터 구성
| 파라미터 | 의미 | Standard Value (기준값) |
| :--- | :--- | :--- |
| **$L_g$** | Gate Length (게이트 길이) | $1\ \mu\text{m}$ (점차 $0.35\ \mu\text{m}$까지 스케일링) |
| **$L_{sd}$** | Source / Drain Length | $0.5\ \mu\text{m}$ |
| **$T_{body}$** | Silicon Body Thickness | $1.2\ \mu\text{m}$ |
| **$T_{sd}$** | Junction Depth | $0.3\ \mu\text{m}$ |
| **$T_{ox}$** | Gate Oxide Thickness | $20\ \text{nm}$ ($0.02\ \mu\text{m}$) |
| **$N_{body}$** | P-type Body Doping (Boron) | $10^{17}\ \text{cm}^{-3}$ |
| **$N_{sd}$** | N-type S/D Doping (Arsenic) | $10^{20}\ \text{cm}^{-3}$ (Gaussian Junction, factor=0.35) |

---

## 🛠️ 3. Physical Models in TCAD (적용 물리 모델)

반도체 내부의 미시적 현상들을 정확하게 모사하기 위해 다음과 같은 물리 엔진/모델을 활성화하여 시뮬레이션을 수행합니다.

*   **Fermi-Dirac Statistics**: 고농도 도핑 영역(Source/Drain)에서의 캐리어 축퇴(Degeneracy) 모사.
*   **Mobility Models**: Doping Dependence 이동도와 강한 수평 전계 하에서의 속도 포화를 설명하기 위한 `HighFieldSaturation` 모델 동시 적용.
*   **Recombination**: Shockley-Read-Hall (SRH) 재결합 모델 및 드레인 끝단 접합 전계 누설을 모사하기 위한 **Band-to-Band Tunneling (BTBT)** 활성화.

---

## 📝 4. Core Simulation Phases (설계 및 분석 연구 과제)

본 프로젝트는 총 **4단계**의 핵심 분석 과정으로 이어집니다.

### Phase 1. Non-Ideal Effects (비이상적 효과)
*   **채널 길이 변조 효과 (Channel-Length Modulation, CLM)**: 게이트 전압($V_g = 1, 2, 3\text{ V}$)에 대한 $I_d-V_d$ 곡선을 도출하고, $L_g$ 축소에 따른 Early Voltage의 변화를 분석합니다.
*   **속도 포화 현상 (Velocity Saturation)**: `HighFieldSaturation` 물리 모델 적용 유무에 따른 $I_d-V_d$ 특성의 극적인 변화를 정량적으로 비교합니다.

### Phase 2. Short Channel Effects (단채널 효과)
*   $L_g$ 스케일링 ($1.0 \rightarrow 0.5 \rightarrow 0.35\ \mu\text{m}$)에 따른 $I_d-V_g$ 전달 특성(Transfer curves) 분석.
*   **Constant-Current Method** ($I_d = 10^{-7}\text{ A}/\mu\text{m} \times W/L$)를 이용한 **문턱 전압 ($V_{th}$)** 및 **Subthreshold Swing ($SS$)** 정밀 추출.
*   **DIBL (Drain-Induced Barrier Lowering)** 추출: $V_{ds} = 0.1\text{ V}$와 $5.0\text{ V}$에서의 문턱 전압 차이 분석.
*   **GIDL** (Band-to-Band 누설 전류) 분석 및 소자 파괴 상태인 **Punch-through** 현상 관찰.

### Phase 3. SCE Mitigation & Optimization (개선 및 최적 소자 설계)
*   **SCE 제어 기법 구현 (2개 이상)**: Halo Doping, LDD(Lightly Doped Drain), High-k 절연막 도입, 혹은 Gate Workfunction 제어 등의 솔루션을 스크립트에 탑재.
*   **통합 최적 소자 제안**: 개별 Suppression 기술들을 융합하여 단채널 효과를 효과적으로 방어하면서 동작 성능을 향상한 최종 최적화 소자 프로파일(도핑 & 구조)을 완성합니다.

### Phase 4. Conclusion (결론 및 고찰)
*   TCAD 시뮬레이션을 통해 물리적으로 검증된 트랜지스터 비이상 및 SCE 현상의 메커니즘을 요약하고 학문적 가치를 고찰합니다.

---

## 🚀 5. How to Run (시뮬레이션 실행 가이드)

Sentaurus Workbench (SWB) 환경 혹은 Linux Command Line에서 다음과 같은 순서로 실행할 수 있습니다.

### 1단계: 구조 생성 및 메쉬 빌드 (`sde`)
`sde_dvs.cmd` 파일을 Structure Editor에 입력하여 MOSFET 2D 메쉬와 도핑 프로파일을 생성합니다.
```bash
sde -e -l 1.sde_dvs.cmd
```
*결과 파일:* `n1_msh.tdr`, `n1_msh.cmd` 등 구조/격자 파일이 출력됩니다.

### 2단계: 소자 동작 특성 해석 (`sdevice`)
구조 파일이 완비되면 `sdevice`를 실행하여 원하는 전기적 특성 바이어스를 sweep 시킵니다.
```bash
# Id-Vd 특성 해석
sdevice 2.sdevice_IdVd.cmd

# Id-Vg 특성 해석
sdevice 3.sdevice_IdVg.cmd
```
*결과 파일:* 시뮬레이션 로그(`*.log`), 노드 특성 데이터(`*.plt`), 최종 전위/전계/농도 분포 비주얼 데이터(`*.tdr`)가 도출됩니다.

### 3단계: 플롯 가시화 및 분석 (`inspect` / `svisual`)
*   `inspect` 툴을 로드하여 `*.plt` 파일을 열고 $I_d-V_d$ 또는 $I_d-V_g$ 곡선을 획득하여 $V_{th}, SS, DIBL$ 등을 추출합니다.
*   `sentaurus visual`을 활용해 소자 내부의 Potential barrier, Electrostatic field, Band-to-Band generation rate 등을 2D 컬러 맵으로 캡처합니다.

---

## 👨‍💻 6. Contributor

*   **학부생**: kokyumin1 (서강대학교 전자공학과)
*   **담당 교과목**: 물리전자공학 II (EEE3121) - 서강대학교
