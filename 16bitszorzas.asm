; Mikrokontoller alapú rendszerek - házi feladat
; Készítette: Jójárt Bence - GFHSCH
;
; Kiírt feladat:
;	Belsõ memóriában lévõ 16 bites elõjeles szám "gyorsszorzása" 10 hatványa szorzóval (1, 10, 100, 1000, 10000), 
;	a 10 kitevõje bemenõ paramétere a rutinnak. A gyorsszorzás azt jelenti, hogy kihasználjuk a szorzó speciális voltát 
;	(pl. 10=8+2, 100=64+32+4), univerzális szorzó használata nem felel meg a feladatnak ! 
;	Az eredmény is 16 biten legyen ábrázolva, a túlcsordulás ennek figyelembevételével állítandó. 
;	Bemenet: szorzandó címe (mutató), szorzó kitevõje, eredmény címe (mutató). Kimenet: 16 bites eredmény, OV 
; Kiegészítés:
;	A kód elején a Program paraméterei komment után átírhatók a bemeneti paraméterek,
;	ez egyszerû szimbólum definíciókkal van megoldva.
;	A feladatot úgy oldottam meg, hogy a szorzandót forgatom RL és RLC parancsokkal, és az egyes forgatási ciklusokban
;	kapott eredményket összadom. Pl. 100-szal szorzás: 100=64+32+4 , azaz kell egy 6-os, egy 5-ös, és egy 2-es rotate,
;	majd az egyes rotate ciklusokkal kapott eredmények összeadása. 
;	Az LJMP ProgramVege utasításon elhelyezett töréspontra a memóriarekeszek már a vágleges eredményeket tartalmazzák




;Program paraméterei
SZORZANDO EQU 273				; szorzó értéke
SZORZO_KITEVO EQU 2				; a szorzandó 10 hányadik hatványa (0-4 lehet az érték)
SZORZANDO_CIM_L EQU 0x70		; szorzandó alsó bájtjának címe a memóriában
SZORZANDO_CIM_H EQU 0x71		; szorzandó felsõ bájtjának címe a memóriában
EREDMENY_CIM_L EQU 0x72			; eredmény alsó bájtjának címe a memóriában
EREDMENY_CIM_H EQU 0x73			; eredmény felsõ bájtjának címe a memóriában

; Bank1 R0-t is használjuk, szimbólum definíciót alkalmazunk az egyszerûbb elérés érdekében, R8_CIM-ként érjük el.
; itt tároljuk el, hogy egy adott forgatási ciklusban mennyit kell még forgatni
R8_CIM EQU 0x08




;Fõprogram
ORG 0
MOV SP, #0x0F			; Stack Pointert átállítjuk, mert a Bank1 R0 regiszterét is használjuk
CALL Init				; Init függvény hívása (behozza a regiszterekbe a megfelelõ értékeket)
CALL MainLoop			; MainLoop függvény hívása (sok ciklus, itt forgatunk és adunk össze sokszor)
ProgramVege:			; Végtelen ciklus, ha vége a programnak
	NOP
	LJMP ProgramVege


	
	
; Konstansok
; A különbözõ szorzókhoz hány különbözõ rotate ciklus kell (DB utáni elsõ konstans)
; Az egyes rotate ciklusokban hányat kell rotate-olni(annyi konstans, amennyit megadtunk az elõbb)
Szorzas1:						; 1=1
	DB 0						
Szorzas10:						; 10=8+2
	DB 2, 3, 1
Szorzas100:						; 100=64+32+4
	DB 3, 6, 5, 2
Szorzas1000:					; 1000=512+256+128+64+32+8
	DB 6, 9, 8, 7, 6, 5, 3
Szorzas10000:					; 10000=8192+1024+512+256+16
	DB 5, 13, 10, 9, 8, 4

	
	
	
; Init szubrutin
;	Beírja a program bemenõi paraméterei szerint a szorzót a megadott címre (alsó+felsõ bájt külön).
;	Behozza a regiszterekbe a szorzandók értékét, ill.  szorzó kitevõjének megfelelõ konstansokat.
;	0-ba állítja a regisztereket, ahol majd a vésõ eredményt tároljuk.
;	Elõkészíti a túlcsordulást jelzõ bitet, a bitcímezhetõ memóriarészben van ez a bit
;	(kezdetben 0, ha bármikor túlcsordulást érzékelünk, 1-re áll).
;	Ha 1-gyel kell szorozni, akkor csak az átmásoljuk az értéket a szorzandó címérõl az eredmény címére.
; Bemenõ paraméterek:
;		SZORZANDO_CIM_L, SZORZANDO_CIM_H, SZORZANDO : szozandó címe ill. értéke
;		SZORZO_KITEVO : szorzó (10 hatványa) kitevõje
; Kimenõ paraméterek:
;		R0: szorzandó alsó bájtja
;		R1: szorzandó felsõ bájtja
;		R2: hányadik rotate ciklusnál tartunk (kezdetben 0)
;		R3: hány rotate ciklus kell még
;		R6, R7: végsõ eredmény itt lesz, ezért 0-val inicializáljuk
; Regiszterek változása: R0, R1, ACC, DPTR, R2, R3, R6, R7, PSW 

Init:
MOV SZORZANDO_CIM_L, #LOW(SZORZANDO)	; a szozandó címére kiírjuk a szorzandót (alsó+felsõ bájt)
MOV SZORZANDO_CIM_H, #HIGH(SZORZANDO)	
MOV R0, SZORZANDO_CIM_L		; R0-ba megy a szozandó alsó bájtja, R1-be a felsõ
MOV R1, SZORZANDO_CIM_H
MOV A, #SZORZO_KITEVO		; Akkuba megy a szortó kitevõje
CLR 0x00 	; itt fogjuk tárolni a bitet, amely jelzi, hogy volt -e túlcsordulás. Kezdetben ez 0.
JZ Behoz1	; a szorzó kitevõje szerint (akku értéke) ugrunk más-más címekre (itt pl. akkor ugrunk, ha a kitevõ 0) 
DEC A
JZ Behoz10  ; ha a kitevõ 1 (10=10^1) ...
DEC A
JZ Behoz100
DEC A
JZ Behoz1000
DEC A
JZ Behoz10000  
Init2:  ; DPTR-ben ekkor már bent van a cím, amiben tároljuk az adott szorzónak megfelelõ konstansokat
MOV A, #0
MOVC A, @A+DPTR		; A-ba behozzuk az elsõ bájtot a cimke után (azaz hogy összesen hány rotate ciklus kell)
MOV R2, #0 			; R2-ben tárojuk, hogy hányadik rotate ciklusnál tartunk (kezdetben 0)
MOV R3, A  			; R3-ban bent van, hogy hány különbözõ rotate ciklus kell még (kezdetben annyi, amennyi összesen kell)
MOV R6, #0 			; R4-ben lesz az eredmény alsó bájtja (kezdetben 0)
MOV R7, #0 			; R5-ben lesz az eredmény felsõ bájtja (kezdetben 0)
RET					; visszatérünk a fõprogramba

;aszerint ugrunk erre a részre, hogy mi a kitevõ,
;itt pedig beírjuk a DPTR-be a címet, hogy honnan kell behozni a megfelelõ konstansokat
Behoz1:	
	MOV EREDMENY_CIM_L, SZORZANDO_CIM_L		; akkor ugrunk ide, ha 1-gyel kell szorozni
	MOV EREDMENY_CIM_H, SZORZANDO_CIM_H		; csak átmásoljuk a bájtokat a szorzó címérõl az eredmény címére
	MOV A, #0			; OV=0 beállítása
	ADD A, #0
	LJMP ProgramVege	; kész vagyunk, jó helyen van az eredmény, ugrás a végtelen ciklusra
Behoz10:
	MOV DPTR, #Szorzas10	; ha 10-zel szorzunk, behozzuk a DPTR-be a szorzas10 címke értékét
	LJMP Init2				; visszaugrunk az Init szubrutinra
Behoz100:
	MOV DPTR, #Szorzas100   ; hasonlóan, mint a Behoz10-nél ...
	LJMP Init2
Behoz1000:
	MOV DPTR, #Szorzas1000
	LJMP Init2
Behoz10000:
	MOV DPTR, #Szorzas10000
	LJMP Init2
	
	

	
; MainLoop szubrutin
;	Elõállítja R6-ban és R7-ben a végleges eredményt.
;	Ehhez sokszor meghívja a Rotate szubrutint, ami R4-en és R5-ön keresztül forgatja a szorzandót, több ciklusban,
;	majd az egyes ciklusokban kapott eredményeket hozzáadja R6-hoz és R7-hez.
;	Kiírja a memóriába az eredményt.
;	Beállítja az OV bitet.
; Bemenõ paraméterek:
;		R0: szorzandó alsó bájtja
;		R1: szorzandó felsõ bájtja
;		R2: hányadik rotate ciklusnál tartunk (kezdetben 0)
;		R3: hány rotate ciklus kell még
;		DPTR: õ jelzi, hogy honnan kell behozni a konstansokat, hogy mikor mennyivel kell forgatni
;		EREDMENY_CIM_L, EREDMENY_CIM_H: hova kell kiírni az eredményt
; Kimenõ paraméterek:
;		#EREDMENY_CIM_L, #EREDMENY_CIM_H: itt lesz a végsõ eredmény eltárolva
;		R6, R7: itt is el lesz tárolva a végsõ eredmény
;		OV flag: ha túlcsordult az eredmény, pontosan akkor egy
; Regiszterek változása: R2, R3, R4, R5, R6, R7, Bank1:R0, PSW, ACC 

MainLoop:
MOV A, R0 ; R4-ben forgatunk (alsó bájt), R4-be beírjuk R0 értékét
MOV R4, A
MOV A, R1 ; R5-ben forgatunk (felsõ bájt), R5-be beírjuk R1 értékét
MOV R5, A

INC R2		; Növeljük az értéket, hogy hányadik rotate ciklusnál tartunk
MOV A, R2			;Behozzuk azt a konstanst a memóriából, ami azt mutatja meg, 
MOVC A, @A+DPTR		;hogy az adott rotate ciklusban hányat kell forgatni
MOV R8_CIM , A 		;Ezt beírjuk R8-ba
CALL Rotate			;Meghívjuk a Rotate szubrutint
DJNZ R3, MainLoop	;Eggyel kevesebb rotate ciklus kell, tehát R3-- . Amennyiben már egy sem kell, készen vagyunk.

MOV EREDMENY_CIM_L, R6		;Eredmény kivitele a memóriába
MOV EREDMENY_CIM_H, R7
MOV A, #0x7F		;OV flag beállítása
ADD A, 0x20			;ha az OV-t jelzõ bit=1, akkor épp túlcsordul, és OV=1 lesz, ha nem, akkor nem

RET		; kész vagyunk, visszatérünk a fõprogramba




; Rotate szubrutin
;	R4-et forgatjuk a carryn keresztül, majd R5-öt, annyiszor, amennyi a Bank1:R0 bemenõ paraméterben volt érték.
;	Ha eleget forgattunk, a kapott eredményt hozzáadjuk az R6, R7 regiszterpárhoz, ahol van a végsõ eredmény.
;	Végig figyelünk, hogy volt e OV, ha igen, akkor a 0x00 bitet 1-be állítjuk.
; Bemenõ paraméterek:
;		R4, R5: forgatandó szorzó alsó és felsõ bájtja
;		R6, R7: az eddigi forgatási ciklusokkal mennyi lett az eredmény (alsó+felsõ bájt)
;		Bank1:R0: adott forgatási ciklusban mennyit kell forgatni
; Kimenõ paraméterek:
;		R6, R7: A mostani forgatási ciklussal mennyi lett az új eredmény (alsó+felsõ bájt)
;		0x00 bit értéke: Jelzi, ha volt túlcsordulás, és a végén OV-t be kell állítani
; Regiszterek változása: ACC, R4, R5, R6, R7, Bank1:R0, PSW

Rotate:
CLR C		; töröljük a carry-t, hogy jobbról RLC parancsnál 0 jöjjön be
MOV A, R4	; ACC-ba átmásoljuk R4-et
RLC A		; forgatunk egyet balra
MOV R4, A	; visszaírjuk R4-be az eredményt
MOV 0x08, C ; carry-t lementjük, hogykésõbb vissza tudjuk olvasni
	MOV A, R5	; ebben a részben csak az OV-t vizsgáljuk meg, hogy keletkezik-e, csak az ACC-ban dolgozunk
	RL A		; akkor lesz OV, ha az eredeti és a elforgatott érték legfelsõ bájtja nem egyezik meg
	XRL A, R5	; ugyanis ekkor negatív->pozitív átmenet van, vagy fordítva, ami pontosan túlcsordulás esetén van
	ANL A, #0x80		; vizsgáljuk XOR után a legfelsõ bitet
	CJNE A, #0x00, SetBitForOV  ;ha az 1, azaz a két felsõ bit nem egyezik, akkor elugunk az OV beállító programrészre
Rotate2: 		; Rotate rutin folytatása
MOV C, 0x08		; mem-be kiírt carry-t visszaírjuk a carrybe, mert az elõbb elrontottuk
MOV A, R5		; ACC-ba átmásoljuk R5-öt
RLC A			; forgatunk egyet balra. ha az R4-bõl jött átvitel, a carry-n keresztül azt beforgatjuk
MOV R5, A		; visszaírjuk R5-be az eredményt
DJNZ R8_CIM, Rotate		; ha kell még forgatni (Bank1R0 szerint), akkor visszaugrunk a rutin elejére, és forgatunk még

MOV A, R6		;az eredményt kiírjuk (R6+=R4)
ADD A, R4
MOV R6, A
MOV 0x08, C		; carry-t lementjük, hogykésõbb vissza tudjuk olvasni
	MOV A, R7		; ebben a részben csak az OV-t vizsgáljuk meg, hogy keletkezik-e, csak az ACC-ban dolgozunk
	ADDC A, R5 		; ACC=R7+R5+C lesz
	XRL A, R5		; akkor lesz OV, ha R5 és a ACC legfelsõ bájtja nem egyezik meg
	ANL A, #0x80	; ugyanis ekkor negatív->pozitív átmenet van, vagy fordítva, ami pontosan túlcsordulás esetén van
	CJNE A, #0x00, SetBitForOV2		;ha az 1, azaz a két felsõ bit nem egyezik, akkor elugunk az OV beállító programrészre
Rotate3:		; Rotate rutin folytatása
MOV C, 0x08		; mem-be kiírt carry-t visszaírjuk a carrybe, mert az elõbb elrontottuk
MOV A, R7		
ADDC A, R5		
MOV R7, A		; R7=R7+R5+C lesz, tehát R7-be bekerül a jó eredmény
RET			; kész vagyunk az adott forgatási ciklussal, visszatérünk a MainLoop-ba

SetBitForOV:		; ide akkor jutunk, ha túlcsordulás volt R5 forgatása közben 
	SETB 0x00		; a 0x00 címen található bitet használjuk az OV jelzésére
	LJMP Rotate2	; visszatérünk oda, ahonnan elugrottunk
	
SetBitForOV2:		; ide akkor jutunk, ha túlcsordulás volt R7=R7+R5+Carry számítása során
	SETB 0x00		; a 0x00 címen található bitet használjuk az OV jelzésére
	LJMP Rotate3	; visszatérünk oda, ahonnan elugrottunk
