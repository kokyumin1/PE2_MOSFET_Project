# 물리전자공학 II (Physical Electronics II) 프로젝트 분석 보고서
> **교과목명**: 물리전자공학 II (EEE3121)  
> **담당 교수**: 김시현 교수님 (Sogang University)  
> **프로젝트 주제**: Short Channel MOSFET Analysis (단채널 MOSFET 분석 및 최적화 설계)  

본 문서는 현재 프로젝트 디렉토리 내의 파일들과 가이드라인을 분석하여, 프로젝트의 목표, 요구사항, TCAD 시뮬레이션 구조 및 레퍼런스 데이터를 깔끔하게 정리한 종합 보고서입니다.

---

## 1. 디렉토리 및 파일 구성 분석

프로젝트 폴더는 설계 파일(SRC), 보고서(Report), 강의 제공 자료(Course_Reference), 외부 참고 자료(Reference)로 나누어져 협업 및 관리에 용이하게 구성되어 있습니다.

```
Project/
├── Course_Reference/          # 강의실 제공 템플릿 및 시뮬레이션 가이드
│   ├── 26-1_PE_Project_Report_1분반_(OO조).docx
│   ├── 26-1_PE_Project_Report_1분반_(OO조).pdf
│   ├── 26-1_SE_MOSFET simulation.pdf
│   ├── 26-1_SE_MOSFET simulation.pptx
│   └── w_velocitysaturation_IdVd.txt
├── Reference/                 # 역사적 배경 및 소자 스펙용 자료
│   └── Intel386TM SX Microprocessor_datasheet.pdf
├── SRC/                       # TCAD 시뮬레이션 소스 코드 (현재 비어 있음)
└── Report/                    # 최종 보고서 제출본 및 작성 공간 (현재 비어 있음)
```

### 각 파일별 상세 역할
*   **`26-1_PE_Project_Report_1분반_(OO조).pdf / .docx`**: 
    최종 제출할 보고서의 목차와 채점 기준, 그리고 반드시 포함해야 할 분석 항목들이 명시된 **보고서 템플릿**입니다.
*   **`26-1_SE_MOSFET simulation.pdf / .pptx`**: 
    TCAD 시뮬레이션 가이드 자료입니다. MOSFET의 동작 영역 분석 방법, Body Effect 추출법, Non-ideal Effect, Short Channel Effect(SCE)의 경향성과 레퍼런스 시뮬레이션 수치가 정리되어 있습니다.
*   **`w_velocitysaturation_IdVd.txt`**: 
    **Sentaurus Device (sdevice)** 시뮬레이터에서 속도 포화(Velocity Saturation) 조건 하에 $I_d-V_d$ 곡선을 솔빙하기 위한 **커맨드(`.cmd`) 스크립트 예제**입니다.
*   **`Intel386TM SX Microprocessor_datasheet.pdf`**: 
    1980년대 상용화된 Intel 386 SX 프로세서의 데이터시트입니다. 이 공정이 $1\ \mu\text{m}$ CMOS 기술을 기반으로 하고 동작 전압이 **5.0 V**임을 보여주며, 시뮬레이션의 기본 전압 및 공정 기준 설정의 물리적 타당성을 뒷받침합니다.

---

## 2. 시뮬레이션 대상 MOSFET의 구조 및 파라미터

가이드라인에 제공된 표준 MOSFET의 물리적 파라미터와 구조는 다음과 같습니다. 이 수치들을 기준으로 시뮬레이션을 구성해야 합니다.

### 소자 구조도 (Device Structure)
```
         [Gate (TiN)] (Workfunction = 4.6 eV)
     ┌────────────────────────┐
     │    Gate Oxide (SiO2)   │ ↕ Tox = 0.02 μm (20 nm)
 ┌───┴────────────────────────┴───┐
 │ Source (Nsd) │   Body (Nbody)  │ │ Drain (Nsd)    │ ↕ Tsd = 0.3 μm
 └──────────────┤                 ├────────────────┘
                │   Boron Doped   │ ↕ Tbody = 1.2 μm
                └─────────────────┘
 ◀── Lsd = 0.5 ──▶◀─── Lg = 1 ────▶
```

### 표준 물리 파라미터 (Table 1)
| 파라미터 | 의미 | 기준값 (Standard Value) |
| :--- | :--- | :--- |
| **$L_g$** | Gate Length (게이트 길이) | $1\ \mu\text{m}$ (시뮬레이션에서 점차 축소) |
| **$L_{sd}$** | Source / Drain Length | $0.5\ \mu\text{m}$ |
| **$T_{body}$** | Silicon Body Thickness | $1.2\ \mu\text{m}$ |
| **$T_{sd}$** | Source / Drain Junction Depth | $0.3\ \mu\text{m}$ |
| **$T_{ox}$** | Gate Oxide Thickness | $0.02\ \mu\text{m}$ ($20\ \text{nm}$) |
| **$N_{body}$** | Body Doping Concentration (P-type, Boron) | $10^{17}\ \text{cm}^{-3}$ |
| **$N_{sd}$** | Source/Drain Doping (N-type, Arsenic) | $10^{20}\ \text{cm}^{-3}$ |
| **Gaussian factor** | S/D Junction Gaussian factor | $0.35$ |

---

## 3. 핵심 분석 및 설계 요구사항 (4단계 구성)

보고서 템플릿에 따라 프로젝트는 크게 **4개 섹션**으로 나누어 분석 및 설계를 수행해야 합니다.

### 1단계: 비이상적 효과 (Non-Ideal Effects)
*   **1-1. 채널 길이 변조 효과 (Channel-Length Modulation, CLM)**
    *   $L_g = 1\ \mu\text{m}, 0.5\ \mu\text{m}, 0.35\ \mu\text{m}$ 세 가지 조건에 대해, 게이트 전압 $V_g = 1\text{ V}, 2\text{ V}, 3\text{ V}$ 일 때의 $I_d-V_d$ 곡선을 플롯하고 CLM 현상을 분석합니다.
*   **1-2. 속도 포화 현상 (Velocity Saturation)**
    *   이동도 모델 중 `HighFieldSaturation` 적용 유무에 따른 $I_d-V_d$ 특성 변화를 시뮬레이션하여 비교하고, 물리적 메커니즘을 분석합니다.

### 2단계: 단채널 효과 (Short Channel Effects, SCEs)
게이트 길이가 축소됨에 따라 발생하는 대표적인 비이상적 소자 특성 저하 현상들을 정량적으로 분석합니다.
*   **2-1. Transfer Characteristics ($I_d-V_g$)**
    *   $L_g = 1\ \mu\text{m}, 0.5\ \mu\text{m}, 0.35\ \mu\text{m}$에 대해 각각 $V_{ds} = 0.1\text{ V}$ (Linear region) 및 $5.0\text{ V}$ (Saturation region) 조건에서의 전달 특성 곡선을 도출합니다.
*   **2-2. 문턱 전압 ($V_{th}$) 및 서브문턱 스윙 ($SS$) 추출**
    *   **정전류법 (Constant-Current Method)** 적용: $I_d = 10^{-7}\text{ A}/\mu\text{m} \times (W/L)$을 만족하는 $V_g$ 지점을 $V_{th}$로 정의합니다.
    *   해당 $V_{th}$ 매칭 포인트 근방에서 $SS$ (Subthreshold Swing)를 추출합니다.
    *   $L_g$ 스케일 다운에 따른 **$V_{th}$ Roll-off** 현상과 **$SS$ Degradation** 경향성을 물리적으로 논의합니다.
*   **2-3. DIBL (Drain-Induced Barrier Lowering) 추출**
    *   $V_{ds,\text{high}} = 5.0\text{ V}$와 $V_{ds,\text{low}} = 0.1\text{ V}$에서의 문턱 전압 차이를 이용하여 $L_g$에 따른 DIBL 값($\text{mV/V}$)을 계산하고 경향성을 분석합니다.
    *   $\text{DIBL} = \frac{V_{th}(V_{ds,\text{low}}) - V_{th}(V_{ds,\text{high}})}{V_{ds,\text{high}} - V_{ds,\text{low}}}$
*   **2-4. GIDL 및 Punch-Through 분석**
    *   $L_g$와 $V_{ds}$에 따른 GIDL(Gate-Induced Drain Leakage) 전류 및 펀치스루(Punch-through) 현상을 분석합니다.
    *   GIDL은 Band-to-Band Tunneling (BTBT) 모델 활성화를 통해 재현합니다.

### 3단계: 단채널 효과 개선 전략 (Mitigation Strategies)
*   **3-1. SCE 제어 기법 제안 (2개 이상)**
    *   소자 구조 변경(예: Halo Doping, LDD, Double-Gate/FinFET 등), 물리 크기 조정, 도핑 프로파일 최적화, 혹은 High-k/Metal Gate 등 신소재 도입 전략을 제시하고 각각의 개별 개선 효과를 시뮬레이션 플롯으로 증명합니다.
*   **3-2. 통합 최적화 설계 소자 제안 (Propose Optimized MOSFET)**
    *   3-1에서 제안한 핵심 Suppression 전략들을 유기적으로 통합하여 성능이 최적화된 MOSFET 구조를 설계하고, 기존 기본 소자(Table 1)와 비교 분석(I-V 특성, $V_{th}$, $SS$, DIBL 등)을 완벽하게 수행합니다.

### 4단계: 결론 (Conclusion)
*   프로젝트 진행을 통해 관찰한 MOSFET의 Non-ideal 효과 및 단채널 효과(SCE)에 대한 학문적/실무적 고찰을 논리적으로 정리합니다.

---

## 4. TCAD 시뮬레이션 설정 및 물리 모델 분석
제공된 `w_velocitysaturation_IdVd.txt` 스크립트를 기반으로 한 시뮬레이션 핵심 모델 및 구성 분석입니다.

### 핵심 물리 모델 설정 (sdevice cmd)
```node
physics 
{
  Fermi                                              # 페르미-디락 통계 모델 적용 (고농도 도핑 영역 고려)
  mobility (DopingDependence HighFieldSaturation)    # 도핑 농도 의존성 이동도 모델 및 강전계 포화 이동도 모델 적용
  EffectiveIntrinsicDensity(NoBandGapNarrowing)      # 대역간 좁아짐 효과(BGN)를 적용하지 않는 유효 고유 캐리어 농도 설정
  Recombination( SRH(DopingDependence) Band2Band(E1))# SRH 재결합 모델 및 Band-to-Band 터널링(BTBT) 재생성 모델 활성화
}
```

*   **Fermi**: 채널 및 S/D 영역의 캐리어 축퇴(Degeneracy)를 설명하기 위해 필수적입니다.
*   **HighFieldSaturation**: 채널 내 수평 전계가 강해짐에 따라 캐리어의 드리프트 속도가 포화되는 현상(1-2 요구사항)을 모사합니다.
*   **Band2Band(E1)**: 드레인 단 접합 부근의 강한 전계로 인해 발생하는 대역간 터널링 누설 전류인 **GIDL** 현상(2-4 요구사항)을 모델링하기 위해 활성화되었습니다.

---

## 5. 가이드 제공 레퍼런스 시뮬레이션 데이터 정리

강의 가이드 PPT 자료에 수록되어 있는 기본 소자의 시뮬레이션 결과 데이터입니다. 본인이 직접 수행할 시뮬레이션 값의 **유효성을 검증하는 앵커 기준**으로 활용해야 합니다.

### $L_g$ 스케일링에 따른 전기적 특성 변화 레퍼런스
*   **시뮬레이션 조건**: $V_{ds} = 5.0\text{ V}$, 문턱 전압 기준 전류 $I_d = 10^{-7}\text{ A}/\mu\text{m} \times (W/L)$

| Gate Length ($L_g$) | 문턱 전압 ($V_{th}$) | Subthreshold Swing ($SS$) | DIBL 수치 | 특이 현상 / 이슈 |
| :---: | :---: | :---: | :---: | :---: |
| **$1.00\ \mu\text{m}$** | $1.37\text{ V}$ | $111.63\text{ mV/dec}$ | $4.49\text{ mV/V}$ | 안정적인 장채널(Long channel) 거동 |
| **$0.57\ \mu\text{m}$** | $1.04\text{ V}$ | $108.99\text{ mV/dec}$ | $53.27\text{ mV/V}$ | 단채널 효과(SCE) 시작 단계 |
| **$0.48\ \mu\text{m}$** | $0.58\text{ V}$ | $131.83\text{ mV/dec}$ | $124.29\text{ mV/V}$ | $V_{th}$ 급감 및 $SS$ 급증 발생 |
| **$0.45\ \mu\text{m}$** | $0.13\text{ V}$ | $337.94\text{ mV/dec}$ | $202.86\text{ mV/V}$ | **Punch-through** 및 심각한 제어력 상실 |

> **분석 Insights**:
> *   $L_g$가 $0.5\ \mu\text{m}$ 미만으로 내려가면 $V_{th}$가 급격히 떨어지는 **$V_{th}$ Roll-off**가 관찰됩니다.
> *   $L_g = 0.45\ \mu\text{m}$에서는 게이트 전압이 음수($-1\text{ V}$)인 상태에서도 드레인 전류가 거의 차단되지 못하는 극심한 **Punch-through 누설 전류**가 발생합니다.

---

## 6. 성공적인 프로젝트 수행을 위한 로드맵 제안

앞으로 시뮬레이션을 진행하고 소스코드를 빌드해 나갈 방향에 대한 권장 설계 로드맵입니다.

1.  **Sentaurus Structure Editor (`sde`) 스크립트 작성**:
    *   Table 1의 치수를 반영한 2D MOSFET 구조 메쉬 파일을 생성합니다.
    *   $L_g$를 매개변수화하여 스크립트 기반으로 $1.0\ \mu\text{m}$, $0.5\ \mu\text{m}$, $0.35\ \mu\text{m}$가 동적으로 빌드되도록 작성합니다.
2.  **`sdevice` 시뮬레이션 덱 구축**:
    *   `w_velocitysaturation_IdVd.txt` 구조를 차용하여 $I_d-V_g$ 및 $I_d-V_d$ 특성을 저장하는 `.cmd` 스크립트를 작성합니다.
    *   `Band2Band(E1)` 모델을 반드시 포함시켜 GIDL 영역을 정확히 캡처합니다.
3.  **데이터 가시화 및 분석 (`inspect` / `sentaurus visual` 활용)**:
    *   추출된 전류-전압 원시 데이터를 파일로 정리하고, 엑셀 또는 Python(Matplotlib) 등을 활용해 깔끔한 플롯 그래프로 시각화합니다.
4.  **Suppression 소자 설계**:
    *   단채널 효과를 억제하기 위한 구조 개선(예: Gate Workfunction 조정, Halo Doping 영역 추가)을 구현하여 $SS < 80\text{ mV/dec}$ 에 가까운 상용 수준의 최적 소자를 목표로 설계합니다.
