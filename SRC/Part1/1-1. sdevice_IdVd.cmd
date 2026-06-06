# =====================================================================
# 물리전자공학 II (Physical Electronics II)
# 담당 교수: 김시현 교수님 (Sogang University)
# 프로젝트: Short Channel MOSFET Analysis (단채널 MOSFET 분석)
# 파일 역할: Sentaurus Device (sdevice) Id-Vd 특성 시뮬레이션 스크립트
# 분석 항목: 1-1 채널 길이 변조 효과(CLM), 1-2 속도 포화 현상(Velocity Saturation)
# =====================================================================

# 1. 파일 입출력 정의 (File Section)
# 시뮬레이션 수행 과정에서 불러오거나 내보낼 물리 파일들의 경로를 정의합니다.
File {
    Grid      = "@tdr@"                 # sde(smesh) 부모 노드가 생성한 2D 메쉬/도핑 구조 파일(.tdr) 자동 참조
    Plot      = "@tdrdat@"              # 시뮬레이션 종료 후, 소자 내부의 2D 물리량(전위, 전계 등)을 저장할 공간 파일 (.tdr)
    Current   = "@plot@"                # 각 스윕 전압 단계별 전류-전압(I-V) 수치 데이터를 저장할 텍스트 파일 (.plt)
    Output    = "@log@"                 # 시뮬레이션 계산 과정의 수렴도 및 로그 메시지를 출력할 파일 (.log)
}

# 2. 전극 경계 조건 정의 (Electrode Section)
# sde_dvs.cmd에서 정의한 전극 이름을 정확히 매칭하고 초기 바이어스를 설정합니다.
Electrode {
    # TiN 게이트 전극의 물리적 일함수(Workfunction = 4.6 eV)를 설정합니다.
    { name="gate"   voltage=0.0 Workfunction=4.6 }
    { name="source" voltage=0.0 }
    { name="drain"  voltage=0.0 }
    { name="body"   voltage=0.0 }
}

# 3. 핵심 물리 현상 모델 활성화 (Physics Section)
# 반도체 내부에서 계산될 물리 수식 엔진(캐리어 통계, 이동도, 재결합 모델 등)을 명시합니다.
Physics {
    Fermi                                              # 페르미-디락(Fermi-Dirac) 통계 모델 적용: 고농도 도핑 영역(S/D)의 축퇴(Degeneracy)를 반영하기 위해 볼츠만 근사 대신 사용합니다.
    
    # [매우 중요 - 1-2 속도 포화(Velocity Saturation) 분석 지침]:
    # 1. 속도 포화 효과가 들어간 표준 특성을 볼 때는 아래처럼 'HighFieldSaturation'을 포함합니다.
    # 2. 속도 포화 효과를 끄고(비활성화) 비교 시뮬레이션을 돌릴 때는 아래 라인을 mobility (DopingDependence) 로만 수정해 줍니다.
    mobility (DopingDependence HighFieldSaturation)    # DopingDependence: 불순물 산란에 의한 이동도 저하 반영, HighFieldSaturation: 수평 강전계에 의한 이동도 포화 및 드리프트 속도 포화 현상 반영
    
    EffectiveIntrinsicDensity(NoBandGapNarrowing)      # 대역간 좁아짐(Band Gap Narrowing, BGN) 현상을 활성화하지 않은 유효 고유 캐리어 농도 설정 (가이드 매칭)
    Recombination( SRH(DopingDependence) Band2Band(E1) ) # SRH(Shockley-Read-Hall): 도핑 농도 의존적 결함 재결합 재현, Band2Band(E1): BTBT(대역간 터널링)을 켜서 드레인단 강전계로 인한 GIDL 특성 캡처 준비
}

# 4. 출력용 물리 분포 리스트 (Plot Section)
# 시뮬레이션 계산이 끝난 후, Sentaurus Visual을 통해 소자 내부에서 2D 맵으로 확인할 물리량 목록입니다.
Plot {
    eDensity hDensity                  # 전자 및 정공 농도 분포 (채널 반전층 형성 관찰용)
    eCurrent hCurrent                  # 전자 및 정공 전류 밀도 분포 (전류 경로 분석용)
    ElectricField                      # 전기장(Electric Field) 분포 (채널 방향 수평 전계 및 게이트 수직 전계 분석)
    Potential SpaceCharge              # 전위(Potential) 분포 및 공간전하 분포
    eMobility hMobility                # 이동도 분포
    eVelocity hVelocity                # 전자/정공의 표동 속도(Drift Velocity) 분포 (채널 내에서 전자 속도가 포화값에 수렴하는지 분석 가능)
    Band2BandGeneration                # GIDL 분석용 BTBT 터널링 발생율 분포
    ConductionBandEnergy ValenceBandEnergy # 전도대 및 가전자대 에너지 준위 분포 (에너지 밴드 다이어그램 플롯용)
}

# 4-2. 집계 데이터 정의 (CurrentPlot Section)
# 특정 적분 연산을 PLT 결과 파일에 저장하여 1D 스칼라 특성으로 쉽게 추출하도록 설정합니다.
currentplot {
    Band2BandGeneration( Integrate(Semiconductor) )
    eBand2BandGeneration( Integrate(Semiconductor) )
    hBand2BandGeneration( Integrate(Semiconductor) )
}

# 5. 수학적 계산 설정 (Math Section)
# 수치해석적 솔빙 알고리즘의 제한 및 가속화 매개변수입니다.
Math {
    Number_of_Threads=16               # 계산 시간 단축을 위한 CPU 멀티스레딩 할당 수 (윈도우 환경에 맞게 자동 조율됨)
    Extrapolate                        # 이전 전압 단계의 해를 바탕으로 다음 단계 예측을 수행하여 수렴성 개선
    RelErrControl                      # 상대 오차 제어 활성화
    Digits=5                           # 내부 계산 정밀도 자릿수 설정
    Iterations=50                      # 각 전압 루프당 최대 반복 계산 횟수
    Notdamped=50                       # 댐핑 없는 뉴턴-랩슨 계산 수 제한
    ExitOnFailure                      # 수렴 실패 시 시뮬레이션을 즉시 강제 종료하여 무한 루프 방지
}

# 6. 바이어스 시나리오 해석 (Solve Section)
# 초기 조건 설정부터 원하는 전압까지 물리 엔진을 솔빙해 나가는 핵심 실행 시나리오입니다.
Solve {
    # 6-1. 초기 열평형 상태(V=0) 해석
    # 가장 먼저 전하 중립성 및 푸아송 방정식(Poisson Equation)을 풀고, 전자 및 정공의 연속방정식과 결합하여 완전 평형 상태의 초기 해를 얻습니다.
    Poisson
    Coupled { Poisson Electron }
    Coupled { Poisson Electron Hole }
    save(FilePrefix="vd0_n@node@")
    plot(FilePrefix="vd0_n@node@")
    
    # 6-2. 게이트 전압(Vg)을 목표 전압까지 램핑(Ramping)
    # SWB에서 선언된 Goal 변수 @Vg@ (예: 1.0 V, 2.0 V, 3.0 V) 까지 게이트 전압을 단계적으로 상승시킵니다.
    # 초기 스텝 1e-3(0.001V)로 시작하여 수렴이 잘 되면 스케일을 키워나가며 계산합니다.
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="gate" voltage=@Vg@ }
    ) { Coupled { Poisson Electron Hole } }
    save(FilePrefix="vg_initial_n@node@")
    plot(FilePrefix="vg_initial_n@node@")
    Load(FilePrefix="vg_initial_n@node@")
    
    # 6-3. 드레인 전압(Vd)을 단계별로 0.0 V에서 3.0 V까지 스윕(Sweep)
    # 고정된 게이트 전압 상태에서, 드레인 바이어스를 0.5V 단위로 스윕하면서 중간 상태의 TDR 및 전위/전계/농도 공간 분포를 저장합니다.
    # NewCurrentPrefix="IdVd_L_"을 지정하여 자동 추출 라이브러리 및 Inspect 모듈이 I-V 플롯을 정확하게 로딩할 수 있게 맞춥니다.
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=0.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_0.0_n@node@") 
    plot(FilePrefix="Vd_0.0_n@node@") 
    NewCurrentPrefix="IdVd_L_"   

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=0.5 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_0.5_n@node@") 
    plot(FilePrefix="Vd_0.5_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=1.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_1.0_n@node@") 
    plot(FilePrefix="Vd_1.0_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=1.5 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_1.5_n@node@") 
    plot(FilePrefix="Vd_1.5_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=2.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_2.0_n@node@") 
    plot(FilePrefix="Vd_2.0_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=2.5 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_2.5_n@node@") 
    plot(FilePrefix="Vd_2.5_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=3.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_3.0_n@node@") 
    plot(FilePrefix="Vd_3.0_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=3.5 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_3.5_n@node@") 
    plot(FilePrefix="Vd_3.5_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=4.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_4.0_n@node@") 
    plot(FilePrefix="Vd_4.0_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=4.5 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_4.5_n@node@") 
    plot(FilePrefix="Vd_4.5_n@node@") 

    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=5.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vd_5.0_n@node@") 
    plot(FilePrefix="Vd_5.0_n@node@") 

}

