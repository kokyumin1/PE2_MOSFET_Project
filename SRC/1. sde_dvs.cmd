(sde:clear)

; ---------------------------------------------------------------------
; 1. 파라미터 (Parameters) 정의
; ---------------------------------------------------------------------
(define Lg @Lg@)                ; [um] gate length
(define Lsd @Lsd@)              ; [um] source/drain length
(define Tbody @Tbody@)          ; [um] body thickness
(define Tsd @Tsd@)              ; [um] junction depth
(define Tox @Tox@)              ; [um] oxide thickness
(define Tg 0.1)                 ; [um] gate thickness (새로 추가됨)

(define Nbody @Nbody@)          ; [cm-3] Body Boron doping concentration
(define Nsd @Nsd@)              ; [cm-3] Source/Drain Arsenic doping concentration

(define X_max (+ Lsd Lg Lsd))
(define DeviceName "n@node@")

; ---------------------------------------------------------------------
; 2. 소자 구조 (Structure) 정의 (교수님 표준 좌표계 완벽 적용)
; ---------------------------------------------------------------------
; Y=0 이 바디 바닥, Y=Tbody 가 실리콘 상단(표면). 즉 위로 솟아오르는 형태입니다.
(sdegeo:create-rectangle (position 0 0 0) (position X_max Tbody 0) "Silicon" "Body")

(sdegeo:create-rectangle (position Lsd Tbody 0) (position (+ Lsd Lg) (+ Tbody Tox) 0) "SiO2" "GateOxide")
(sdegeo:create-rectangle (position Lsd (+ Tbody Tox) 0) (position (+ Lsd Lg) (+ Tbody Tox Tg) 0) "TiN" "Gate")

; ---------------------------------------------------------------------
; 3. 전극 (Contact) 설정 (교수님 방식 완벽 적용)
; ---------------------------------------------------------------------
(sdegeo:define-contact-set "source" 0.0 (color:rgb 0 255 0) "##")
(sdegeo:define-contact-set "drain" 0.0 (color:rgb 0 0 255) "##")
(sdegeo:define-contact-set "gate" 4.6 (color:rgb 255 0 0) "##")
(sdegeo:define-contact-set "body" 0.0 (color:rgb 255 255 0) "##")

; Source Contact (실리콘 상단 표면 좌측 중앙)
(sdegeo:insert-vertex (position (+ (* 0.5 Lsd) (* 0.3 Lsd)) Tbody 0))
(sdegeo:insert-vertex (position (+ (* 0.5 Lsd) (* -0.3 Lsd)) Tbody 0))
(sdegeo:set-contact (list (car (find-edge-id (position (* 0.5 Lsd) Tbody 0)))) "source")

; Drain Contact (실리콘 상단 표면 우측 중앙)
(sdegeo:insert-vertex (position (+ Lsd Lg (* 0.5 Lsd) (* 0.3 Lsd)) Tbody 0))
(sdegeo:insert-vertex (position (+ Lsd Lg (* 0.5 Lsd) (* -0.3 Lsd)) Tbody 0))
(sdegeo:set-contact (list (car (find-edge-id (position (+ Lsd Lg (* 0.5 Lsd)) Tbody 0)))) "drain")

; Gate Contact (TiN 윗면)
(sdegeo:set-contact (list (car (find-edge-id (position (+ Lsd (* 0.5 Lg)) (+ Tbody Tox Tg) 0)))) "gate")

; Body Contact (실리콘 바닥 중앙)
(sdegeo:set-contact (list (car (find-edge-id (position (+ Lsd (* 0.5 Lg)) 0 0)))) "body")

; ---------------------------------------------------------------------
; 4. 도핑 (Doping) 프로파일 (교수님 방식 적용)
; ---------------------------------------------------------------------
(sdedr:define-constant-profile "Const.Body" "BoronActiveConcentration" Nbody)
(sdedr:define-constant-profile-region "PlaceCD.Body" "Const.Body" "Body")

(sdedr:define-refeval-window "BaseLine.Source" "Line" (position 0 Tbody 0) (position Lsd Tbody 0))
(sdedr:define-gaussian-profile "Impl.Source" "ArsenicActiveConcentration" "PeakPos" 0 "PeakVal" Nsd "ValueAtDepth" 5e17 "Depth" Tsd "Gauss" "Factor" 0.35)
(sdedr:define-analytical-profile-placement "Impl.Source" "Impl.Source" "BaseLine.Source" "Negative" "NoReplace" "Eval")

(sdedr:define-refeval-window "BaseLine.Drain" "Line" (position (+ Lsd Lg) Tbody 0) (position X_max Tbody 0))
(sdedr:define-gaussian-profile "Impl.Drain" "ArsenicActiveConcentration" "PeakPos" 0 "PeakVal" Nsd "ValueAtDepth" 5e17 "Depth" Tsd "Gauss" "Factor" 0.35)
(sdedr:define-analytical-profile-placement "Impl.Drain" "Impl.Drain" "BaseLine.Drain" "Negative" "NoReplace" "Eval")

; ---------------------------------------------------------------------
; 5. 메쉬 (Mesh) 설정 (교수님 방식 완벽 적용)
; ---------------------------------------------------------------------
(sdedr:define-refeval-window "Entire" "Rectangle"  (position 0 0 0)  (position X_max (+ Tbody Tox Tg) 0))
(sdedr:define-refinement-size "Entire" 0.05 0.05 0 0.05 0.05 0)
(sdedr:define-refinement-placement "Entire" "Entire" (list "window" "Entire" ) )

(sdedr:define-refeval-window "Channel" "Rectangle"  (position Lsd (- Tbody Tsd) 0)  (position (+ Lsd Lg) Tbody 0))
(sdedr:define-refinement-size "Channel" 0.02 0.02 0 0.02 0.02 0)
(sdedr:define-refinement-placement "Channel" "Channel" (list "window" "Channel" ) )

(sdedr:define-refeval-window "Oxide" "Rectangle"  (position Lsd (- Tbody (* 0.5 Tox)) 0)  (position (+ Lsd Lg) (+ Tbody Tox (* 0.5 Tox)) 0))
(sdedr:define-refinement-size "Oxide" 0.004 0.004 0 0.004 0.004 0)
(sdedr:define-refinement-placement "Oxide" "Oxide" (list "window" "Oxide" ) )

; ---------------------------------------------------------------------
; 6. 저장 및 메쉬 빌드 (교수님 명령어 포맷 적용 + TDR 저장 복구)
; ---------------------------------------------------------------------
(sde:save-model "n@node@") ; Svisual 시각화를 위해 반드시 필요한 TDR 구조 파일 저장!
(sde:set-meshing-command "snmesh -a -c boxmethod")
(sdedr:write-cmd-file "n@node@_msh.cmd")
(sde:build-mesh "snmesh" "-a -c boxmethod" "n@node@_msh")
