# =====================================================================
# 물리전자공학 II (Physical Electronics II)
# 담당 교수: 김시현 교수님 (Sogang University)
# 프로젝트: Short Channel MOSFET Analysis
# 파일 역할: Sentaurus Device (sdevice) Id-Vg 특성 시뮬레이션 스크립트
# 분석 항목: 2-1 Id-Vg 전달특성, 2-2 Vth 및 SS 추출, 2-3 DIBL 분석, 2-4 GIDL/펀치스루 누설전류
# =====================================================================

File {
    Grid      = "@tdr@"                 # sde(smesh) 부모 노드가 생성한 메쉬 파일을 자동으로 참조
    Plot      = "@tdrdat@"              # 해당 node 고유의 공간적 물리량 데이터 파일 생성 (.tdr)
    Current   = "@plot@"                # 해당 node 고유의 I-V 특성 곡선 데이터 파일 생성 (.plt)
    Output    = "@log@"                 # 시뮬레이션 로그 파일 자동 생성 (.log)
}

Electrode {
    # sde_dvs.cmd 전극명 및 일함수 설정(TiN=4.6 eV)과 매칭
    { name="gate"   voltage=0.0 Workfunction=4.6 }
    { name="source" voltage=0.0 }
    { name="drain"  voltage=0.0 }
    { name="body"   voltage=0.0 }
}

Physics {
    Fermi                                              # 페르미-디락 통계 적용
    mobility (DopingDependence HighFieldSaturation)    # 도핑 의존성 및 강전계 포화 이동도 모델 적용
    EffectiveIntrinsicDensity(NoBandGapNarrowing)      # BGN 비활성화
    Recombination( SRH(DopingDependence) Band2Band(E1) ) # SRH 및 GIDL 재현용 BTBT 터널링 활성화
}

Plot {
    eDensity hDensity                  # 전자/정공 농도
    eCurrent hCurrent                  # 전자/정공 전류 밀도
    ElectricField                      # 전기장 분포 (GIDL 전계 분석용)
    Potential SpaceCharge              # 포텐셜 및 공간전하 분포 (DIBL 에너지 장벽 분석용)
    eMobility hMobility                # 이동도 분포
    Band2BandGeneration                # GIDL 누설 전류 캡처용 BTBT 생성률
    ConductionBandEnergy ValenceBandEnergy # 밴드 다이어그램 (DIBL & BTBT 분석 핵심)
}

Math {
    Number_of_Threads=16               # 계산 가속화 스레드 수
    Extrapolate
    RelErrControl
    Digits=5
    Iterations=50
    Notdamped=50
    ExitOnFailure
}

Solve {
    # 1. 초기 평형 상태(Zero Bias) 솔빙
    Poisson
    Coupled { Poisson Electron }
    Coupled { Poisson Electron Hole }
    
    # 2. Gate 전압을 스윕 시작점인 -1.0 V로 램핑
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="gate" voltage=-1.0 }
    ) { Coupled { Poisson Electron Hole } }
    
    # 3. Drain 전압을 분석 목표 전압(Vds = 0.1 V 또는 5.0 V)으로 램핑
    # 이 부분은 SWB 연동 시 Goal { name="drain" voltage=@Vd@ } 로 파라미터화할 수 있습니다.
    # 아래 예시는 Vds = 5.0 V (DIBL 고전압 및 펀치스루 분석용) 조건 설정입니다.
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=@Vd@ }
    ) { Coupled { Poisson Electron Hole } }
    
    # 4. Gate 전압을 -1.0 V에서 3.0 V까지 스윕하여 Id-Vg 곡선 획득
    # (Vth roll-off, Subthreshold Swing, DIBL, GIDL 분석용 전압 스윕)
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.05 MinStep=1e-8
        Goal { name="gate" voltage=3.0 }
    ) { Coupled { Poisson Electron Hole } }
}
