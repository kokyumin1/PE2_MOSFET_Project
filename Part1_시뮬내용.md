# 1장. 비이상적 효과 (Non-Ideal Effects) 시뮬레이션 및 데이터 추출 가이드

본 문서는 물리전자공학 II 프로젝트 보고서 1장(Non-Ideal Effects) 작성을 위해 Sentaurus TCAD에서 실행할 수 있는 시뮬레이션 설정법과 데이터 분석 지침을 정리한 가이드라인입니다.

---

## 📑 PDF 템플릿 Part 1 요구사항 원문 및 번역

### 1-1. 채널 길이 변조 효과 (Channel-Length Modulation, CLM)
*   **원문**: `Analyze the channel-length modulation as a function of Lg (=1 μm, 0.5 μm, 0.35 μm) (when Vg = 1 V, 2 V, 3 V).`
*   **번역**: 게이트 길이 $L_g$ ($1\ \mu\text{m}, 0.5\ \mu\text{m}, 0.35\ \mu\text{m}$)에 따른 채널 길이 변조 효과(CLM)를 분석하십시오. (게이트 전압 $V_g = 1\text{ V}, 2\text{ V}, 3\text{ V}$ 조건에서 수행)
*   **작성 가이드**: 각 조건별 $I_d-V_d$ 곡선, 핀치오프(Pinch-off) 및 유효 채널 길이 감소 분석을 위한 적절한 그림/그래프(2D 공핍층 영역 맵 등)와 이론값($\lambda$, $g_d$) 비교를 포함하여 서술합니다. (제출 시 가이드 안내 문구는 삭제)

### 1-2. 속도 포화 현상 (Velocity Saturation)
*   **원문**: `Analyze the velocity saturation phenomenon with and without applying the "HighFieldSaturation" model (when Vg = 1 V, 2 V, 3 V).`
*   **번역**: "HighFieldSaturation" 모델의 적용 유무에 따른 속도 포화 현상을 분석하십시오. (게이트 전압 $V_g = 1\text{ V}, 2\text{ V}, 3\text{ V}$ 조건에서 수행)
*   **작성 가이드**: 두 가지 물리 모델(속도 포화 켬 vs 끔)의 $I_d-V_d$ 곡선을 겹쳐서 비교 제시하고, 채널 내부의 캐리어 표동 속도(Drift Velocity) 및 전계(Electric Field) 분포 그래프를 추출하여 물리적 타당성을 고찰합니다. (제출 시 가이드 안내 문구는 삭제)

---

## 💡 1-1. 채널 길이 변조 효과 (CLM) 시뮬레이션 및 분석

### 1) SWB 시뮬레이션 방법
*   **실행 파일**: `SRC/Part1/1-2. sdevice_IdVd .cmd` (혹은 프로젝트 내 $I_d-V_d$ 용 sdevice 노드)
*   **시뮬레이션 조건**:
    *   게이트 전압 $V_g$를 **$1.0\text{ V}, 2.0\text{ V}, 3.0\text{ V}$**로 각각 고정합니다. (SWB 변수 `@Vg@`로 파라미터화 설정 가능)
    *   드레인 전압 $V_{ds}$를 **$0\text{ V} \rightarrow 5.0\text{ V}$**까지 스윕합니다.
    *   게이트 길이 $L_g$를 **$1.0\ \mu\text{m}, 0.5\ \mu\text{m}, 0.35\ \mu\text{m}$**로 스윕하여 각각 실행합니다.

### 2) Svisual 및 데이터 추출 가이드
1.  **$I_d-V_d$ 특성 플롯**:
    *   각 $L_g$ 노드의 결과 파일(`.plt`)을 엽니다.
    *   X축을 `drain OuterVoltage`, Y축을 `drain TotalCurrent`로 설정하고 게이트 전압별 곡선(총 3개 라인)을 플롯합니다.
    *   **관찰 포인트**: 장채널($1.0\ \mu\text{m}$) 소자는 saturation 영역에서 전류가 비교적 수평을 이루지만, 단채널($0.35\ \mu\text{m}$)로 갈수록 우상향하는 기울기가 가팔라집니다.
2.  **출력 컨덕턴스 ($g_d$) 및 CLM 파라미터 ($\lambda$) 추출**:
    *   포화 영역(예: $V_{ds} = 3.0\text{ V} \sim 5.0\text{ V}$ 구간)에서의 전류 기울기를 읽어 채널 길이 변조 계수 $\lambda$를 역산합니다.
    *   수식: $I_d \approx I_{d,\text{sat}}(1 + \lambda V_{ds}) \implies \lambda = \frac{1}{I_{d,\text{sat}}} \frac{\partial I_d}{\partial V_{ds}}$
3.  **2D 공핍 영역 (Depletion Region) 시각화**:
    *   Svisual에서 구조 파일(`.tdr`)을 엽니다. (드레인 전압이 높은 $V_{ds} = 5.0\text{ V}$ 상태의 프레임 선택)
    *   **`SpaceCharge`** 분포나 **`ElectricField`** 분포를 2D 컬러 맵으로 띄웁니다.
    *   드레인 접합부 근처에서 핀치오프(Pinch-off)가 발생하고 드레인 측 공핍 영역이 채널 중심부 쪽으로 확장되어 들어옴에 따라, 실제 캐리어가 지나다니는 유효 채널 길이($L_{eff} = L_g - \Delta L$)가 짧아지는 모습을 캡처하여 첨부합니다.

---

## ⚡ 1-2. 속도 포화 (Velocity Saturation) 모델 온/오프 분석

### 1) 시뮬레이션 비교 설정
*   **비교군 A (속도 포화 모델 적용)**:
    ```tcl
    Physics {
        mobility (DopingDependence HighFieldSaturation)
    }
    ```
*   **비교군 B (속도 포화 모델 미적용 - CLM 효과 극대화 조건)**:
    ```tcl
    Physics {
        mobility (DopingDependence) # HighFieldSaturation을 삭제
    }
    ```

### 2) Svisual 및 데이터 추출 가이드
1.  **$I_d-V_d$ 곡선 중첩 비교**:
    *   동일 $L_g$ (예: $0.35\ \mu\text{m}$), 동일 $V_g$ 바이어스 조건에서 모델을 켰을 때와 껐을 때의 두 `.plt` 데이터를 Svisual에 한꺼번에 로드하여 겹쳐서 플롯합니다.
    *   **관찰 포인트**: 속도 포화 모델을 끄면(비교군 B) 전자의 속도가 전기장 비례로 무한히 빨라지므로, Saturation 영역이 거의 보이지 않고 전류가 수 밀리암페어($\text{mA}$) 대역까지 비물리적으로 끝없이 치솟는 모순이 발생합니다.
2.  **1D 채널 표면 속도 및 전계 분포 플롯 (핵심 고찰 데이터)**:
    *   Svisual에서 $V_{ds} = 5.0\text{ V}$ 상태의 `.tdr` 구조 파일을 엽니다.
    *   **1D Cut-line 그리기**: 실리콘 표면(채널 계면, $Y = 1.2\ \mu\text{m}$ 라인 바로 아래 약 $Y = 1.199\ \mu\text{m}$ 수평 라인)을 가로지르는 수평 Cut-line을 그립니다.
    *   이 Cut-line 상의 **`eVelocity` (전자 표동 속도)** 및 **`ElectricField` (수평 전계)**를 X축(채널 위치)에 따라 플롯합니다.
    *   **관찰 포인트**:
        *   **모델 적용 시**: 드레인 접합부 근처에서 수평 전계가 급격히 증가함에도 불구하고, 전자의 속도는 물리적 한계 속도인 **$v_{sat} \approx 10^7\text{ cm/s}$** 부근에서 더 이상 증가하지 않고 평탄(Saturation)해집니다.
        *   **모델 미적용 시**: 전자의 속도가 전계에 비례하여 $10^8\text{ cm/s}$ 이상으로 끝도 없이 솟구치는 비현실적인 현상이 나타납니다.

---

## 📘 보고서 서술용 물리 이론 요약

### 1. 채널 길이 변조 효과 (CLM)
*   **물리적 배경**: 포화 영역($V_{ds} > V_{ds,\text{sat}}$)에서 드레인 접합부 전위차 상승으로 공핍 영역이 넓어지며 핀치오프(Pinch-off) 점이 소스 쪽으로 이동합니다. 이에 따라 유효 채널 길이($L_{eff} = L_g - \Delta L$)가 짧아져 채널 저항이 감소하고 드레인 전류가 완만하게 증가하게 됩니다.
*   **수식 관계**:
    $$I_D = \frac{1}{2}\mu_n C_{ox} \frac{W}{L_g - \Delta L}(V_{gs}-V_{th})^2 \approx I_{D,\text{sat}}(1 + \lambda V_{ds})$$
    이때 $\lambda \propto 1/L_g$ 이므로, 게이트 길이 $L_g$가 축소될수록 분모의 $L_g$ 대비 공핍 영역 변동폭($\Delta L$)의 비중이 비대해져 $\lambda$(출력 컨덕턴스 기울기)가 훨씬 크게 나타납니다.

### 2. 속도 포화 현상 (Velocity Saturation)
*   **물리적 배경**: 채널 내부 수평 전기장이 매우 강해지면 캐리어가 높은 운동 에너지를 얻게 되며, 이 과잉 에너지를 격자 진동(Optical Phonon Emission)을 통해 방출하면서 충돌 산란이 지배적이 됩니다. 이로 인해 전기장을 더 가해도 전자의 드리프트 속도는 한계 속도 $v_{sat}$에 포화됩니다.
*   **전류 특성식 변화**:
    *   장채널 소자: $I_{d,\text{sat}} \propto (V_{gs} - V_{th})^2$ (제곱 법칙 준수)
    *   단채널 소자: $I_{d,\text{sat}} \approx W C_{ox} v_{sat} (V_{gs} - V_{th})$ (게이트 오버드라이브 전압에 **1승(Linear) 비례**하며, 드레인 전류의 최대치가 억제됨)
