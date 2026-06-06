# =====================================================================
# 물리전자공학 II (Physical Electronics II)
# 담당 교수: 김시현 교수님 (Sogang University)
# 프로젝트: Short Channel MOSFET Analysis (단채널 MOSFET 분석)
# 파일 역할: Sentaurus Device (sdevice) Id-Vg 특성 시뮬레이션 스크립트 (2-1장)
# 분석 항목: 2-1 Id-Vg 전달특성, 2-2 Vth 및 SS 추출, 2-3 DIBL 분석, 2-4 GIDL/펀치스루 누설전류
# =====================================================================

# 1. 파일 입출력 정의 (File Section)
File {
    Grid      = "@tdr@"                 # sde(smesh) 부모 노드가 생성한 2D 메쉬/도핑 구조 파일(.tdr) 자동 참조
    Plot      = "@tdrdat@"              # 시뮬레이션 종료 후, 소자 내부의 2D 물리 분포량을 저장할 파일 (.tdr)
    Current   = "@plot@"                # 각 게이트 전압 스윕 단계별 I-V 수치 데이터를 저장할 텍스트 파일 (.plt)
    Output    = "@log@"                 # 시뮬레이션 계산 과정의 수렴도 및 로그 메시지를 출력할 파일 (.log)
}

# 2. 전극 경계 조건 정의 (Electrode Section)
Electrode {
    # TiN 게이트 전극의 물리적 일함수(Workfunction = 4.6 eV)를 설정합니다.
    { name="gate"   voltage=0.0 Workfunction=4.6 }
    { name="source" voltage=0.0 }
    { name="drain"  voltage=0.0 }
    { name="body"   voltage=0.0 }       # 기판 바이어스를 0.0V로 고정 (SWB 테이블 Vbody 부재 대응)
}

# 3. 핵심 물리 현상 모델 활성화 (Physics Section)
Physics {
    Fermi                                              # 페르미-디락(Fermi-Dirac) 통계 모델 적용 (S/D의 퇴화 조건 반영)
    mobility (DopingDependence HighFieldSaturation)    # DopingDependence: 격자/불순물 산란 반영, HighFieldSaturation: 수평 전계 하에서의 속도 포화 현상 모사
    EffectiveIntrinsicDensity(NoBandGapNarrowing)      # BGN 비활성화 (가이드라인 매칭)
    Recombination( SRH(DopingDependence) Band2Band(E1) ) # SRH 재결합 모델 및 드레인 끝단 BTBT(Band-to-Band 터널링)을 켜서 GIDL 누설 전류 현상 모사
}

# 4. 출력용 물리 분포 리스트 (Plot Section)
# Id-Vg 시뮬레이션 분석에 중요한 에너지 밴드 다이어그램 및 전위 분포 출력을 추가 설정합니다.
Plot {
    eDensity hDensity                  # 전자 및 정공 농도 분포 (게이트 전압에 따른 채널 반전/축적 상태 관찰)
    eCurrent hCurrent                  # 전자 및 정공 전류 밀도 분포
    ElectricField                      # 전기장(Electric Field) 분포 (드레인 접합부의 전계 집중 및 GIDL 전계 분석용)
    Potential SpaceCharge              # 전위(Potential) 분포 및 공간전하 분포 (DIBL에 의한 포텐셜 장벽 변화 관찰 핵심)
    eMobility hMobility                # 이동도 분포
    Band2BandGeneration                # GIDL 분석용 BTBT 터널링 발생율 분포 (BTBT가 어느 위치에서 강력하게 생기는지 확인)
    ConductionBandEnergy ValenceBandEnergy # 전도대 및 가전자대 에너지 분포 (DIBL 장벽 저하 분석 및 BTBT 에너지 밴드 벤딩 분석 핵심)
}

# 5. 수학적 계산 설정 (Math Section)
Math {
    Number_of_Threads=16               # 계산 시간 단축을 위한 CPU 멀티스레딩 할당 수
    Extrapolate                        # 수렴성 향상을 위한 보외법 활성화
    RelErrControl                      # 상대 오차 제어 활성화
    Digits=5                           # 내부 수치 계산의 정밀도 자릿수 설정
    Iterations=50                      # 각 스텝당 최대 반복 계산 횟수
    Notdamped=50                       # 댐핑 제어 임계값 설정
    ExitOnFailure                      # 계산 수렴 실패 시 프로세스 안전 종료
}

# 6. 바이어스 시나리오 해석 (Solve Section)
# Id-Vg 곡선을 정확하게 뽑아내기 위해 게이트 전압을 마이너스 영역(-1.0 V)부터 스윕 시작합니다.
# 교수님 템플릿과 동일하게 드레인을 먼저 인가한 후 게이트를 스윕하는 순서로 배치하며, 중간 상태를 모두 개별 저장합니다.
Solve {
    # 6-1. 초기 열평형 상태(V=0) 해석
    Poisson
    Coupled { Poisson Electron }
    Coupled { Poisson Electron Hole }
    save(FilePrefix="vd0_n@node@")
    plot(FilePrefix="vd0_n@node@")
    
    # 6-2. 드레인 전압(Vd)을 분석 대상 전압(@Vd@)으로 램핑
    # SWB에서 지정한 목표 전압(선형 영역: 0.1 V, 포화 영역: 5.0 V)까지 드레인 바이어스를 인가합니다.
    # [DIBL 분석 핵심]: 동일한 게이트 스윕 하에서 Vd=0.1 V와 Vd=5.0 V 두 곡선 간의 Vth 차이를 비교해야 합니다.
    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="drain" voltage=@Vd@ }
    ) { Coupled { Poisson Electron Hole } }
    save(FilePrefix="vd_initial_n@node@")
    plot(FilePrefix="vd_initial_n@node@")
    Load(FilePrefix="vd_initial_n@node@")

    # 6-3. 게이트 전압(Vg)을 스윕 시작점인 -1.0 V로 이동
    # GIDL 및 오프(Off) 상태의 누설 전류 특성을 제대로 관찰하기 위해 게이트를 -1.0 V까지 먼저 램핑시킵니다.
    # NewCurrentPrefix="IdVg_L_"를 선언하여 Inspect 라이브러리 연동 시 필요한 결과 곡선 접두사를 지정합니다.
    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=-1.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_n1.0_n@node@") 
    plot(FilePrefix="Vg_n1.0_n@node@") 
    NewCurrentPrefix="IdVg_L_"   
    
    # 6-4. 게이트 전압(Vg)을 -1.0 V에서 3.0 V까지 단계별로 스윕(Sweep)
    # 보고서 2D profile 시각화 및 에너지 밴드 추출(DIBL 장벽 저하 증명)을 위해 각 단계별 구조 파일을 저장합니다.
    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=-0.4 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_n0.4_n@node@") 
    plot(FilePrefix="Vg_n0.4_n@node@")

    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=0.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_0.0_n@node@") 
    plot(FilePrefix="Vg_0.0_n@node@")     

    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=0.6 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_0.6_n@node@") 
    plot(FilePrefix="Vg_0.6_n@node@") 

    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=1.3 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_1.3_n@node@") 
    plot(FilePrefix="Vg_1.3_n@node@") 

    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=1.6 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_1.6_n@node@") 
    plot(FilePrefix="Vg_1.6_n@node@") 

    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=2.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_2.0_n@node@") 
    plot(FilePrefix="Vg_2.0_n@node@") 

    Quasistationary (
        InitialStep=1e-4 Maxstep=1e-1 MinStep=1e-7
        Goal { name="gate" voltage=3.0 }
    ) { Coupled { Poisson Electron Hole } }   
    save(FilePrefix="Vg_3.0_n@node@") 
    plot(FilePrefix="Vg_3.0_n@node@") 
}
