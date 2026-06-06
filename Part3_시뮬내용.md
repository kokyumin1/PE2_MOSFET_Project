# 3장. 단채널 효과 개선 (Mitigating Short Channel Effects) 시뮬레이션 및 데이터 추출 가이드

본 문서는 물리전자공학 II 프로젝트 보고서 3장(Mitigating Short Channel Effects) 작성을 위해 Sentaurus TCAD에서 실행할 수 있는 개선 시뮬레이션 설정법과 데이터 분석 지침을 정리한 가이드라인입니다.

---

## 📑 PDF 템플릿 Part 3 요구사항 원문 및 번역

### 3-1. 단채널 효과 개선 전략 제안 (Mitigation Strategies)
*   **원문**: `Suggest (two or more) strategies to mitigate the SCEs analyzed in section 2. One can modify MOSFET’s structure, dimensions, doping concentration and material. Describe each method and their individual effects using appropriate analysis methods and plots.`
*   **번역**: 2장에서 분석한 단채널 효과(SCE)를 완화하기 위한 두 가지 이상의 전략을 제안하십시오. MOSFET의 구조, 치수(Dimensions), 도핑 농도 및 재료를 변경할 수 있습니다. 적절한 분석 방법과 그래프/그림을 사용하여 각 방법의 메커니즘과 그 효과를 서술하십시오.
*   **작성 가이드**: 각 개선 전략에 대한 $I-V$ plot, 내부 물리량 분석(에너지 밴드, 전계 등) 및 물리적 원리 논의를 적절한 그림과 함께 기술합니다. (제출 시 가이드 안내 문구는 삭제)

### 3-2. 통합 최적화 소자 제안 및 비교 분석 (Optimized MOSFET)
*   **원문**: `By Integrating the individual SCE suppression strategies suggested in Section 3-1, propose an optimized MOSFET, and perform a comprehensive comparison of its characteristics with those of the original MOSFET (Table 1).`
*   **번역**: 3-1에서 제안한 개별 단채널 효과 억제 전략들을 통합하여 최적화된 MOSFET을 제안하고, 이 최적화 소자의 특성을 기존 원본 소자(Table 1 사양)와 종합적으로 비교 분석하십시오.
*   **작성 가이드**: 원본 소스 대비 개선된 최적화 소자의 전달 특성 및 출력 특성 그래프를 비교 제시하고, 물리량이 개선된 정량적 데이터 표와 2D 물리 분포 맵을 함께 첨부하여 서술합니다.

---

## 💡 1. 단채널 효과 개선 전략 (SWB 파라미터 튜닝 기법)

구조 코드를 새로 짤 필요 없이, 기존 `sde_dvs.cmd`가 변수화하여 제공하는 **SWB 파라미터 컬럼 값**들을 조절함으로써 단채널 효과를 극적으로 개선할 수 있습니다. 아래의 3가지 핵심 전략 중 **2가지 이상**을 선정하여 시뮬레이션을 진행합니다.

### 1) 전략 A: 게이트 산화막 두께 ($T_{ox}$) 축소 (Gate Control 강화)
*   **원리**: 게이트 산화막 두께 $T_{ox}$를 얇게 하면 게이트 커패시턴스 $C_{ox} = \epsilon_{ox}/T_{ox}$가 급격히 증가합니다. 이에 따라 게이트가 채널의 전하를 제어하는 능력이 드레인 전계에 비해 압도적으로 우세해져 단채널 효과를 억제합니다.
*   **SWB 설정**: `Tox` 변수 컬럼의 값을 기존 **`0.02` ($20\text{ nm}$)**에서 **`0.003` ($3\text{ nm}$)** 또는 **`0.005` ($5\text{ nm}$)**로 변경합니다. (0.35 um 공정 수준에 부합하는 두께)
*   **예상 효과**: DIBL 장벽 낮아짐 현상이 크게 억제되어 문턱 전압 롤오프가 방지되며, 서브문턱 스윙($SS$)이 이론적 한계치($60\text{ mV/dec}$)에 가까운 $70 \sim 85\text{ mV/dec}$ 수준으로 대폭 개선됩니다.

### 2) 전략 B: 기판(바디) 도핑 농도 ($N_{body}$) 증가 (공핍 영역 확장 억제)
*   **원리**: 채널 및 기판 영역의 P형 도핑 농도 $N_{body}$를 높이면, 소스와 드레인 접합부에서 생성되는 공핍 영역의 폭($W_{dep} \propto 1/\sqrt{N_{body}}$)이 크게 감소합니다. 소스/드레인 공핍층이 서로 겹쳐서 발생하는 펀치스루 전류를 차단하고 Charge Sharing 비율을 낮춥니다.
*   **SWB 설정**: `Nbody` 변수 컬럼의 값을 기존 **`1e17`**에서 **`5e17`** 또는 **`1e18`**로 증가시킵니다.
*   **예상 효과**: 벌크 전류 경로(Sub-surface leakage)가 완전히 차단되어 펀치스루가 억제되고, 오프 상태 누설 전류($I_{off}$)가 격감합니다. 다만, 문턱 전압($V_{th}$) 자체는 다소 상승하므로 이를 감안해야 합니다.

### 3) 전략 C: 소스/드레인 접합 깊이 ($T_{sd}$) 축소 (Shallow Junction 형성)
*   **원리**: 소스/드레인의 접합 깊이 $T_{sd}$를 얕게 만들면, 드레인 바이어스 전계가 게이트 채널 하부 벌크 영역 깊숙이 침투하는 물리적 경로가 차단되어 Charge Sharing 효과가 감소합니다.
*   **SWB 설정**: `Tsd` 변수 컬럼의 값을 기존 **`0.3` ($\mu\text{m}$)**에서 **`0.1` ($\mu\text{m}$)** 또는 **`0.15` ($\mu\text{m}$)**로 감소시킵니다.
*   **예상 효과**: 게이트 제어 범위 밖의 벌크 공핍 영역 매칭이 최소화되어 DIBL과 펀치스루가 억제됩니다.

---

## 🏆 2. 최적 소자 (Optimized MOSFET) 설계 및 비교 분석 (3-2)

위의 개별 전략들을 **동시에 적용한 최종 최적화 소자**를 SWB 상에서 추가 노드로 구성하여 시뮬레이션을 수행하고 원본 소자와 비교 분석합니다.

### 1) 추천 최적화 소자 파라미터 세트
*   `Tox` = **`0.003`** ($3\text{ nm}$)
*   `Nbody` = **`5e17`** ($5 \times 10^{17}\text{ cm}^{-3}$)
*   `Tsd` = **`0.1`** ($0.1\ \mu\text{m}$)
*   (나머지 파라미터는 Table 1과 동일)

### 2) 분석용 그림 및 그래프 구성 (Svisual 활용)
1.  **$I_d-V_g$ 비교 그래프 (Log & Linear Scale)**: 
    *   $L_g = 0.35\ \mu\text{m}$ 단채널 소자에서 기존 원본 사양(Table 1)의 곡선과 최적화 사양의 곡선을 겹쳐서 그립니다.
    *   최적화 소자에서 오프 누설 전류($I_{off}$)가 수십 억 배 이상 감소하고, 문턱 전압이 양의 값으로 정상 복구되는 현상을 증명합니다.
2.  **1D 전도대 에너지 장벽 비교**:
    *   $V_{ds} = 5.0\text{ V}$ 상태에서 원본 소자와 최적화 소자의 Conduction Band 장벽 높이를 비교하여 소스 단 장벽이 강건하게 유지됨(DIBL 개선)을 증명합니다.
3.  **2D 전자 전류 밀도(eCurrent) 비교 맵**:
    *   오프 상태에서 원본 소자는 벌크 깊은 곳으로 전류가 누설(Punch-through)되는 반면, 최적화 소자는 벌크 누설 전류가 완전히 차단되어 전류 밀도가 극히 낮아진 깨끗한 프로파일을 캡처하여 첨부합니다.

---

## 📊 3. 보고서용 성능 비교 템플릿 표

보고서 3-2절 작성 시 아래와 같은 정량적 비교 분석 표를 구성하여 수치적 개선 효과를 한눈에 보여주는 것이 매우 중요합니다.

| 분석 항목 (at $L_g = 0.35\ \mu\text{m}$) | 원본 소자 (Table 1 사양) | 최적화 적용 소자 (Optimized) | 개선 효과 및 물리적 의의 |
| :--- | :---: | :---: | :--- |
| **선형 문턱 전압 ($V_{th}$ at $V_{ds}=0.1\text{ V}$)** | $-0.28\text{ V}$ (음수 도달) | $\approx 0.5 \sim 0.7\text{ V}$ | 정상적인 Enhancemement 모드로 복구 |
| **포화 문턱 전압 ($V_{th}$ at $V_{ds}=5.0\text{ V}$)** | 측정 불가 (Punch-through) | $\approx 0.4 \sim 0.6\text{ V}$ | 단채널 영역에서도 강건한 문턱 전압 유지 |
| **서브문턱 스윙 ($SS$ at $V_{ds}=0.1\text{ V}$)** | $683.5\text{ mV/dec}$ | $\approx 70 \sim 85\text{ mV/dec}$ | 게이트의 채널 스위칭 속도 극적 개선 |
| **DIBL 성능 ($V_{th}$ 차이값)** | 측정 불가 (소자 파괴) | $\approx 50 \sim 100\text{ mV/V}$ | 드레인 전압에 의한 장벽 강하 억제 증명 |
| **오프 전류 ($I_{off}$ at $V_{gs}=0\text{ V}, V_{ds}=5.0\text{ V}$)** | $\approx 10^{-6}\text{ A}$ (심각한 누설) | $\approx 10^{-14} \sim 10^{-15}\text{ A}$ | 대기 전력 소모량을 수억 배 이상 감축 |
| **온오프 전류비 ($I_{on}/I_{off}$)** | $\approx 3.6 \times 10^2$배 | $\approx 10^9 \sim 10^{10}$배 | 디지털 스위치로서의 동작 신뢰성 완벽 복구 |
