(sde:clear) ; 이전 구조 설정을 모두 초기화하고 메모리를 비웁니다.

; ---------------------------------------------------------------------
; 1. 파라미터 (Parameters) 정의
; ---------------------------------------------------------------------
; Sentaurus Workbench(SWB)에서 @기호@로 둘러싸인 값은 테이블의 변수값으로 동적 치환됩니다.
(define Lg @Lg@)                ; [um] 게이트 길이 (Gate Length) - 단채널 효과 분석을 위해 1.0에서 0.35까지 축소시킬 핵심 변수
(define Lsd @Lsd@)              ; [um] 소스 및 드레인 영역의 가로 길이 (Source/Drain Length, 0.5 um)
(define Tbody @Tbody@)          ; [um] 실리콘 바디(기판)의 전체 두께 (Body Thickness, 1.2 um)
(define Tsd @Tsd@)              ; [um] 소스/드레인 접합 깊이 (Junction Depth, 0.3 um)
(define Tox @Tox@)              ; [um] 게이트 산화막(SiO2)의 두께 (Oxide Thickness, 20 nm = 0.02 um)
(define Tg 0.1)                 ; [um] 게이트 전극(TiN)의 두께 (Gate Thickness, 100 nm = 0.1 um)

(define Nbody @Nbody@)          ; [cm-3] P-type 바디 도핑 농도 (기본값: Boron 1e17 cm-3)
(define Nsd @Nsd@)              ; [cm-3] N-type 소스/드레인 접합부의 최고 농도 (기본값: Arsenic 1e20 cm-3)

(define X_max (+ Lsd Lg Lsd))   ; 소자의 전체 가로 길이 계산 (Lsd + Lg + Lsd = 0.5 + 1.0 + 0.5 = 2.0 um)
(define DeviceName "n@node@")   ; 현재 시뮬레이션 노드 번호에 맞는 소자 이름 정의

; ---------------------------------------------------------------------
; 2. 소자 구조 (Structure) 정의 (교수님 표준 좌표계 적용)
; ---------------------------------------------------------------------
; [중요 좌표계]: Y=0이 실리콘 바닥(기판 밑면)이며, Y=Tbody(1.2 um)가 실리콘 표면(채널 계면)입니다.
; Y방향 좌표가 커질수록 위로 올라가는 형태입니다.

; (sdegeo:create-rectangle (좌측하단 좌표) (우측상단 좌표) "재질" "리전이름")
; 실리콘 바디 영역 생성: 가로 0 ~ X_max, 세로 0 ~ Tbody (두께 1.2 um)
(sdegeo:create-rectangle (position 0 0 0) (position X_max Tbody 0) "Silicon" "Body")

; 게이트 산화막(SiO2) 생성: 게이트 길이 영역만큼 채널 표면 바로 위에 얹음 (세로: Tbody ~ Tbody+Tox)
(sdegeo:create-rectangle (position Lsd Tbody 0) (position (+ Lsd Lg) (+ Tbody Tox) 0) "SiO2" "GateOxide")

; 게이트 금속 전극(TiN) 생성: 산화막 바로 위에 적층 (세로: Tbody+Tox ~ Tbody+Tox+Tg)
(sdegeo:create-rectangle (position Lsd (+ Tbody Tox) 0) (position (+ Lsd Lg) (+ Tbody Tox Tg) 0) "TiN" "Gate")

; ---------------------------------------------------------------------
; 3. 전극 (Contact) 설정
; ---------------------------------------------------------------------
; (sdegeo:define-contact-set "전극명" 일함수(Workfunction) "패턴 색상" "##")
; TiN 게이트 전극의 물리적 일함수(Workfunction)인 4.6 eV를 적용합니다. 다른 전극은 0.0(옴익 접촉)으로 설정합니다.
(sdegeo:define-contact-set "source" 0.0 (color:rgb 0 255 0) "##")
(sdegeo:define-contact-set "drain" 0.0 (color:rgb 0 0 255) "##")
(sdegeo:define-contact-set "gate" 4.6 (color:rgb 255 0 0) "##")
(sdegeo:define-contact-set "body" 0.0 (color:rgb 255 255 0) "##")

; [소스 전극 형성]: 실리콘 상단(Y=Tbody) 좌측 영역 중 가운뎃부분(중앙 60% 영역)에 접촉창을 만듭니다.
; 에지(Edge)의 양쪽 끝 점(Vertex)을 삽입하여 전극 영역을 확실하게 구획한 후 전극을 지정합니다.
(sdegeo:insert-vertex (position (+ (* 0.5 Lsd) (* 0.3 Lsd)) Tbody 0))
(sdegeo:insert-vertex (position (+ (* 0.5 Lsd) (* -0.3 Lsd)) Tbody 0))
(sdegeo:set-contact (list (car (find-edge-id (position (* 0.5 Lsd) Tbody 0)))) "source")

; [드레인 전극 형성]: 실리콘 상단(Y=Tbody) 우측 영역 중 가운뎃부분(중앙 60% 영역)에 접촉창을 만듭니다.
(sdegeo:insert-vertex (position (+ Lsd Lg (* 0.5 Lsd) (* 0.3 Lsd)) Tbody 0))
(sdegeo:insert-vertex (position (+ Lsd Lg (* 0.5 Lsd) (* -0.3 Lsd)) Tbody 0))
(sdegeo:set-contact (list (car (find-edge-id (position (+ Lsd Lg (* 0.5 Lsd)) Tbody 0)))) "drain")

; [게이트 전극 형성]: TiN 메탈 박스의 최상단 면(Y = Tbody + Tox + Tg)을 게이트 전극으로 지정합니다.
(sdegeo:set-contact (list (car (find-edge-id (position (+ Lsd (* 0.5 Lg)) (+ Tbody Tox Tg) 0)))) "gate")

; [바디 전극 형성]: 실리콘 기판의 최하단 면(Y = 0) 전체를 바디 전극으로 지정합니다.
(sdegeo:set-contact (list (car (find-edge-id (position (+ Lsd (* 0.5 Lg)) 0 0)))) "body")

; ---------------------------------------------------------------------
; 4. 도핑 (Doping) 프로파일 설정
; ---------------------------------------------------------------------
; [4-1. 바디 균일 도핑 (Uniform Doping)]
; P-type 붕소(Boron) 활성 캐리어 농도를 Nbody 값으로 정의하고, 이를 "Silicon" 재질의 "Body" 리전에 균일하게 도핑합니다.
(sdedr:define-constant-profile "Const.Body" "BoronActiveConcentration" Nbody)
(sdedr:define-constant-profile-region "PlaceCD.Body" "Const.Body" "Body")

; [4-2. 소스 영역 가우시안 도핑 (Gaussian Doping)]
; 1. 도핑의 기준선(Baseline) 설정: 실리콘 좌측 상단 표면 (X: 0 ~ Lsd, Y: Tbody)
(sdedr:define-refeval-window "BaseLine.Source" "Line" (position 0 Tbody 0) (position Lsd Tbody 0))
; 2. 가우시안 농도 프로파일 정의: 표면 최고 농도 Nsd(Arsenic, 1e20), 깊이 Tsd(0.3 um) 지점의 농도는 5e17 cm-3, Gaussian Factor는 0.35 적용
(sdedr:define-gaussian-profile "Impl.Source" "ArsenicActiveConcentration" "PeakPos" 0 "PeakVal" Nsd "ValueAtDepth" 5e17 "Depth" Tsd "Gauss" "Factor" 0.35)
; 3. 정의한 가우시안 도핑 프로파일을 소스 기준선 아래(Negative Y방향)에 배치
(sdedr:define-analytical-profile-placement "Impl.Source" "Impl.Source" "BaseLine.Source" "Negative" "NoReplace" "Eval")

; [4-3. 드레인 영역 가우시안 도핑 (Gaussian Doping)]
; 1. 도핑의 기준선(Baseline) 설정: 실리콘 우측 상단 표면 (X: Lsd+Lg ~ X_max, Y: Tbody)
(sdedr:define-refeval-window "BaseLine.Drain" "Line" (position (+ Lsd Lg) Tbody 0) (position X_max Tbody 0))
; 2. 소스와 완전히 대칭되는 드레인용 가우시안 농도 프로파일 정의 (Arsenic 1e20, 접합 깊이 0.3 um)
(sdedr:define-gaussian-profile "Impl.Drain" "ArsenicActiveConcentration" "PeakPos" 0 "PeakVal" Nsd "ValueAtDepth" 5e17 "Depth" Tsd "Gauss" "Factor" 0.35)
; 3. 정의한 가우시안 도핑 프로파일을 드레인 기준선 아래에 배치
(sdedr:define-analytical-profile-placement "Impl.Drain" "Impl.Drain" "BaseLine.Drain" "Negative" "NoReplace" "Eval")

; ---------------------------------------------------------------------
; 5. 메쉬 (Mesh) 세분화 설정
; ---------------------------------------------------------------------
; 소자 내부 전위 및 전류 계산 오차를 줄이기 위해 중요 물리 영역별 격자(Mesh) 조밀도를 각각 다르게 설정합니다.

; [5-1. 전체 영역 메쉬 (Entire Mesh)]
; 소자 전체 영역 윈도우 생성: 가로 0 ~ X_max, 세로 0 ~ Tbody+Tox+Tg
(sdedr:define-refeval-window "Entire" "Rectangle"  (position 0 0 0)  (position X_max (+ Tbody Tox Tg) 0))
; 기본 격자 크기: 가로 0.05 um, 세로 0.05 um 설정
(sdedr:define-refinement-size "Entire" 0.05 0.05 0 0.05 0.05 0)
(sdedr:define-refinement-placement "Entire" "Entire" (list "window" "Entire" ) )

; [5-2. 채널 및 접합 접면 메쉬 (Channel & Junction Mesh)] - 중요 물리 계산 영역
; 채널 및 S/D Junction 부근 윈도우 생성 (Y: Tbody-Tsd ~ Tbody)
(sdedr:define-refeval-window "Channel" "Rectangle"  (position Lsd (- Tbody Tsd) 0)  (position (+ Lsd Lg) Tbody 0))
; 캐리어 거동과 펀치스루 현상을 조밀하게 보기 위해 격자 간격을 0.02 um로 더 세밀하게 조정
(sdedr:define-refinement-size "Channel" 0.02 0.02 0 0.02 0.02 0)
(sdedr:define-refinement-placement "Channel" "Channel" (list "window" "Channel" ) )

; [5-3. 산화막 계면 메쉬 (Oxide & Interface Mesh)] - 가장 격자가 촘촘해야 하는 극미세 영역
; 게이트 옥사이드 및 실리콘 계면 윈도우 생성
(sdedr:define-refeval-window "Oxide" "Rectangle"  (position Lsd (- Tbody (* 0.5 Tox)) 0)  (position (+ Lsd Lg) (+ Tbody Tox (* 0.5 Tox)) 0))
; Oxide 절연막에서의 급격한 전위 구배를 정확하게 솔빙하기 위해 격자 크기를 0.004 um (4 nm)로 최고밀 설정
(sdedr:define-refinement-size "Oxide" 0.004 0.004 0 0.004 0.004 0)
(sdedr:define-refinement-placement "Oxide" "Oxide" (list "window" "Oxide" ) )

; ---------------------------------------------------------------------
; 6. 저장 및 메쉬 빌드
; ---------------------------------------------------------------------
(sde:save-model "n@node@") ; Sentaurus Visual에서 소자 형상과 도핑 맵을 시각적으로 확인(TDR)할 수 있도록 구조 모델 세이브
(sde:set-meshing-command "snmesh -a -c boxmethod") ; 유한체적법(boxmethod)을 사용하도록 메쉬 빌드 명령어 설정
(sdedr:write-cmd-file "n@node@_msh.cmd") ; 메셔(mesher)가 사용할 상세 설정 cmd 파일 쓰기
(sde:build-mesh "snmesh" "-a -c boxmethod" "n@node@_msh") ; 최종 메쉬 격자가 분할된 구조 파일(n@node@_msh.tdr) 빌드 시작

