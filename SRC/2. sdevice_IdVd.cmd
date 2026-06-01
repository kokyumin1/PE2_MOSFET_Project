# =====================================================================
# 물리전자공학 II (Physical Electronics II)
# 담당 교수: 김시현 교수님 (Sogang University)
# 프로젝트: Short Channel MOSFET Analysis
# 파일 역할: Sentaurus Device (sdevice) Id-Vd 특성 시뮬레이션 스크립트
# 분석 항목: 1-1 채널 길이 변조 효과(CLM), 1-2 속도 포화 현상(Velocity Saturation)
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
    
    # [주의] 1-2 속도 포화 비활성 비교 시, 아래 라인에서 HighFieldSaturation을 삭제
    # 예: mobility (DopingDependence)
    mobility (DopingDependence HighFieldSaturation)    
    
    EffectiveIntrinsicDensity(NoBandGapNarrowing)      # BGN 비활성화
    Recombination( SRH(DopingDependence) Band2Band(E1) ) # SRH 및 GIDL용 BTBT 터널링 활성화
}

Plot {
    eDensity hDensity                  # 전자/정공 농도
    eCurrent hCurrent                  # 전자/정공 전류 밀도
    ElectricField                      # 전기장 분포
    Potential SpaceCharge              # 포텐셜 및 공간전하 분포
    eMobility hMobility                # 이동도 분포
    eVelocity hVelocity                # 캐리어 표동 속도 분포 (속도 포화 분석용)
    Band2BandGeneration                # GIDL 분석용 BTBT 생성률
    ConductionBandEnergy ValenceBandEnergy # 에너지 밴드 다이어그램
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
    
    # 2. Gate 전압을 목적 전압(예: Vg = 1.0, 2.0, 3.0 V)으로 램핑
    # 이 부분은 SWB 연동 시 Goal { name="gate" voltage=@Vg@ } 로 파라미터화할 수 있습니다.
    # 아래 예시는 Vg = 2.0 V 조건에서의 Id-Vd 곡선 추출 설정입니다.
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="gate" voltage=@Vg@ }
    ) { Coupled { Poisson Electron Hole } }
    
    # 3. Drain 전압을 0.0V 에서 3.0V까지 스윕하여 Id-Vd 곡선 획득
    # (PDF p.17-18 CLM 및 Velocity Saturation 전압 범위 매칭: 0.0 ~ 3.0 V)
    Quasistationary (
        InitialStep=1e-3 Maxstep=0.1 MinStep=1e-7
        Goal { name="drain" voltage=3.0 }
    ) { Coupled { Poisson Electron Hole } }
}
