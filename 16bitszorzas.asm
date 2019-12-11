; Mikrokontoller alap� rendszerek - h�zi feladat
; K�sz�tette: J�j�rt Bence - GFHSCH
;
; Ki�rt feladat:
;	Bels� mem�ri�ban l�v� 16 bites el�jeles sz�m "gyorsszorz�sa" 10 hatv�nya szorz�val (1, 10, 100, 1000, 10000), 
;	a 10 kitev�je bemen� param�tere a rutinnak. A gyorsszorz�s azt jelenti, hogy kihaszn�ljuk a szorz� speci�lis volt�t 
;	(pl. 10=8+2, 100=64+32+4), univerz�lis szorz� haszn�lata nem felel meg a feladatnak ! 
;	Az eredm�ny is 16 biten legyen �br�zolva, a t�lcsordul�s ennek figyelembev�tel�vel �ll�tand�. 
;	Bemenet: szorzand� c�me (mutat�), szorz� kitev�je, eredm�ny c�me (mutat�). Kimenet: 16 bites eredm�ny, OV 
; Kieg�sz�t�s:
;	A k�d elej�n a Program param�terei komment ut�n �t�rhat�k a bemeneti param�terek,
;	ez egyszer� szimb�lum defin�ci�kkal van megoldva.
;	A feladatot �gy oldottam meg, hogy a szorzand�t forgatom RL �s RLC parancsokkal, �s az egyes forgat�si ciklusokban
;	kapott eredm�nyket �sszadom. Pl. 100-szal szorz�s: 100=64+32+4 , azaz kell egy 6-os, egy 5-�s, �s egy 2-es rotate,
;	majd az egyes rotate ciklusokkal kapott eredm�nyek �sszead�sa. 
;	Az LJMP ProgramVege utas�t�son elhelyezett t�r�spontra a mem�riarekeszek m�r a v�gleges eredm�nyeket tartalmazz�k




;Program param�terei
SZORZANDO EQU 273				; szorz� �rt�ke
SZORZO_KITEVO EQU 2				; a szorzand� 10 h�nyadik hatv�nya (0-4 lehet az �rt�k)
SZORZANDO_CIM_L EQU 0x70		; szorzand� als� b�jtj�nak c�me a mem�ri�ban
SZORZANDO_CIM_H EQU 0x71		; szorzand� fels� b�jtj�nak c�me a mem�ri�ban
EREDMENY_CIM_L EQU 0x72			; eredm�ny als� b�jtj�nak c�me a mem�ri�ban
EREDMENY_CIM_H EQU 0x73			; eredm�ny fels� b�jtj�nak c�me a mem�ri�ban

; Bank1 R0-t is haszn�ljuk, szimb�lum defin�ci�t alkalmazunk az egyszer�bb el�r�s �rdek�ben, R8_CIM-k�nt �rj�k el.
; itt t�roljuk el, hogy egy adott forgat�si ciklusban mennyit kell m�g forgatni
R8_CIM EQU 0x08




;F�program
ORG 0
MOV SP, #0x0F			; Stack Pointert �t�ll�tjuk, mert a Bank1 R0 regiszter�t is haszn�ljuk
CALL Init				; Init f�ggv�ny h�v�sa (behozza a regiszterekbe a megfelel� �rt�keket)
CALL MainLoop			; MainLoop f�ggv�ny h�v�sa (sok ciklus, itt forgatunk �s adunk �ssze sokszor)
ProgramVege:			; V�gtelen ciklus, ha v�ge a programnak
	NOP
	LJMP ProgramVege


	
	
; Konstansok
; A k�l�nb�z� szorz�khoz h�ny k�l�nb�z� rotate ciklus kell (DB ut�ni els� konstans)
; Az egyes rotate ciklusokban h�nyat kell rotate-olni(annyi konstans, amennyit megadtunk az el�bb)
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
;	Be�rja a program bemen�i param�terei szerint a szorz�t a megadott c�mre (als�+fels� b�jt k�l�n).
;	Behozza a regiszterekbe a szorzand�k �rt�k�t, ill.  szorz� kitev�j�nek megfelel� konstansokat.
;	0-ba �ll�tja a regisztereket, ahol majd a v�s� eredm�nyt t�roljuk.
;	El�k�sz�ti a t�lcsordul�st jelz� bitet, a bitc�mezhet� mem�riar�szben van ez a bit
;	(kezdetben 0, ha b�rmikor t�lcsordul�st �rz�kel�nk, 1-re �ll).
;	Ha 1-gyel kell szorozni, akkor csak az �tm�soljuk az �rt�ket a szorzand� c�m�r�l az eredm�ny c�m�re.
; Bemen� param�terek:
;		SZORZANDO_CIM_L, SZORZANDO_CIM_H, SZORZANDO : szozand� c�me ill. �rt�ke
;		SZORZO_KITEVO : szorz� (10 hatv�nya) kitev�je
; Kimen� param�terek:
;		R0: szorzand� als� b�jtja
;		R1: szorzand� fels� b�jtja
;		R2: h�nyadik rotate ciklusn�l tartunk (kezdetben 0)
;		R3: h�ny rotate ciklus kell m�g
;		R6, R7: v�gs� eredm�ny itt lesz, ez�rt 0-val inicializ�ljuk
; Regiszterek v�ltoz�sa: R0, R1, ACC, DPTR, R2, R3, R6, R7, PSW 

Init:
MOV SZORZANDO_CIM_L, #LOW(SZORZANDO)	; a szozand� c�m�re ki�rjuk a szorzand�t (als�+fels� b�jt)
MOV SZORZANDO_CIM_H, #HIGH(SZORZANDO)	
MOV R0, SZORZANDO_CIM_L		; R0-ba megy a szozand� als� b�jtja, R1-be a fels�
MOV R1, SZORZANDO_CIM_H
MOV A, #SZORZO_KITEVO		; Akkuba megy a szort� kitev�je
CLR 0x00 	; itt fogjuk t�rolni a bitet, amely jelzi, hogy volt -e t�lcsordul�s. Kezdetben ez 0.
JZ Behoz1	; a szorz� kitev�je szerint (akku �rt�ke) ugrunk m�s-m�s c�mekre (itt pl. akkor ugrunk, ha a kitev� 0) 
DEC A
JZ Behoz10  ; ha a kitev� 1 (10=10^1) ...
DEC A
JZ Behoz100
DEC A
JZ Behoz1000
DEC A
JZ Behoz10000  
Init2:  ; DPTR-ben ekkor m�r bent van a c�m, amiben t�roljuk az adott szorz�nak megfelel� konstansokat
MOV A, #0
MOVC A, @A+DPTR		; A-ba behozzuk az els� b�jtot a cimke ut�n (azaz hogy �sszesen h�ny rotate ciklus kell)
MOV R2, #0 			; R2-ben t�rojuk, hogy h�nyadik rotate ciklusn�l tartunk (kezdetben 0)
MOV R3, A  			; R3-ban bent van, hogy h�ny k�l�nb�z� rotate ciklus kell m�g (kezdetben annyi, amennyi �sszesen kell)
MOV R6, #0 			; R4-ben lesz az eredm�ny als� b�jtja (kezdetben 0)
MOV R7, #0 			; R5-ben lesz az eredm�ny fels� b�jtja (kezdetben 0)
RET					; visszat�r�nk a f�programba

;aszerint ugrunk erre a r�szre, hogy mi a kitev�,
;itt pedig be�rjuk a DPTR-be a c�met, hogy honnan kell behozni a megfelel� konstansokat
Behoz1:	
	MOV EREDMENY_CIM_L, SZORZANDO_CIM_L		; akkor ugrunk ide, ha 1-gyel kell szorozni
	MOV EREDMENY_CIM_H, SZORZANDO_CIM_H		; csak �tm�soljuk a b�jtokat a szorz� c�m�r�l az eredm�ny c�m�re
	MOV A, #0			; OV=0 be�ll�t�sa
	ADD A, #0
	LJMP ProgramVege	; k�sz vagyunk, j� helyen van az eredm�ny, ugr�s a v�gtelen ciklusra
Behoz10:
	MOV DPTR, #Szorzas10	; ha 10-zel szorzunk, behozzuk a DPTR-be a szorzas10 c�mke �rt�k�t
	LJMP Init2				; visszaugrunk az Init szubrutinra
Behoz100:
	MOV DPTR, #Szorzas100   ; hasonl�an, mint a Behoz10-n�l ...
	LJMP Init2
Behoz1000:
	MOV DPTR, #Szorzas1000
	LJMP Init2
Behoz10000:
	MOV DPTR, #Szorzas10000
	LJMP Init2
	
	

	
; MainLoop szubrutin
;	El��ll�tja R6-ban �s R7-ben a v�gleges eredm�nyt.
;	Ehhez sokszor megh�vja a Rotate szubrutint, ami R4-en �s R5-�n kereszt�l forgatja a szorzand�t, t�bb ciklusban,
;	majd az egyes ciklusokban kapott eredm�nyeket hozz�adja R6-hoz �s R7-hez.
;	Ki�rja a mem�ri�ba az eredm�nyt.
;	Be�ll�tja az OV bitet.
; Bemen� param�terek:
;		R0: szorzand� als� b�jtja
;		R1: szorzand� fels� b�jtja
;		R2: h�nyadik rotate ciklusn�l tartunk (kezdetben 0)
;		R3: h�ny rotate ciklus kell m�g
;		DPTR: � jelzi, hogy honnan kell behozni a konstansokat, hogy mikor mennyivel kell forgatni
;		EREDMENY_CIM_L, EREDMENY_CIM_H: hova kell ki�rni az eredm�nyt
; Kimen� param�terek:
;		#EREDMENY_CIM_L, #EREDMENY_CIM_H: itt lesz a v�gs� eredm�ny elt�rolva
;		R6, R7: itt is el lesz t�rolva a v�gs� eredm�ny
;		OV flag: ha t�lcsordult az eredm�ny, pontosan akkor egy
; Regiszterek v�ltoz�sa: R2, R3, R4, R5, R6, R7, Bank1:R0, PSW, ACC 

MainLoop:
MOV A, R0 ; R4-ben forgatunk (als� b�jt), R4-be be�rjuk R0 �rt�k�t
MOV R4, A
MOV A, R1 ; R5-ben forgatunk (fels� b�jt), R5-be be�rjuk R1 �rt�k�t
MOV R5, A

INC R2		; N�velj�k az �rt�ket, hogy h�nyadik rotate ciklusn�l tartunk
MOV A, R2			;Behozzuk azt a konstanst a mem�ri�b�l, ami azt mutatja meg, 
MOVC A, @A+DPTR		;hogy az adott rotate ciklusban h�nyat kell forgatni
MOV R8_CIM , A 		;Ezt be�rjuk R8-ba
CALL Rotate			;Megh�vjuk a Rotate szubrutint
DJNZ R3, MainLoop	;Eggyel kevesebb rotate ciklus kell, teh�t R3-- . Amennyiben m�r egy sem kell, k�szen vagyunk.

MOV EREDMENY_CIM_L, R6		;Eredm�ny kivitele a mem�ri�ba
MOV EREDMENY_CIM_H, R7
MOV A, #0x7F		;OV flag be�ll�t�sa
ADD A, 0x20			;ha az OV-t jelz� bit=1, akkor �pp t�lcsordul, �s OV=1 lesz, ha nem, akkor nem

RET		; k�sz vagyunk, visszat�r�nk a f�programba




; Rotate szubrutin
;	R4-et forgatjuk a carryn kereszt�l, majd R5-�t, annyiszor, amennyi a Bank1:R0 bemen� param�terben volt �rt�k.
;	Ha eleget forgattunk, a kapott eredm�nyt hozz�adjuk az R6, R7 regiszterp�rhoz, ahol van a v�gs� eredm�ny.
;	V�gig figyel�nk, hogy volt e OV, ha igen, akkor a 0x00 bitet 1-be �ll�tjuk.
; Bemen� param�terek:
;		R4, R5: forgatand� szorz� als� �s fels� b�jtja
;		R6, R7: az eddigi forgat�si ciklusokkal mennyi lett az eredm�ny (als�+fels� b�jt)
;		Bank1:R0: adott forgat�si ciklusban mennyit kell forgatni
; Kimen� param�terek:
;		R6, R7: A mostani forgat�si ciklussal mennyi lett az �j eredm�ny (als�+fels� b�jt)
;		0x00 bit �rt�ke: Jelzi, ha volt t�lcsordul�s, �s a v�g�n OV-t be kell �ll�tani
; Regiszterek v�ltoz�sa: ACC, R4, R5, R6, R7, Bank1:R0, PSW

Rotate:
CLR C		; t�r�lj�k a carry-t, hogy jobbr�l RLC parancsn�l 0 j�jj�n be
MOV A, R4	; ACC-ba �tm�soljuk R4-et
RLC A		; forgatunk egyet balra
MOV R4, A	; vissza�rjuk R4-be az eredm�nyt
MOV 0x08, C ; carry-t lementj�k, hogyk�s�bb vissza tudjuk olvasni
	MOV A, R5	; ebben a r�szben csak az OV-t vizsg�ljuk meg, hogy keletkezik-e, csak az ACC-ban dolgozunk
	RL A		; akkor lesz OV, ha az eredeti �s a elforgatott �rt�k legfels� b�jtja nem egyezik meg
	XRL A, R5	; ugyanis ekkor negat�v->pozit�v �tmenet van, vagy ford�tva, ami pontosan t�lcsordul�s eset�n van
	ANL A, #0x80		; vizsg�ljuk XOR ut�n a legfels� bitet
	CJNE A, #0x00, SetBitForOV  ;ha az 1, azaz a k�t fels� bit nem egyezik, akkor elugunk az OV be�ll�t� programr�szre
Rotate2: 		; Rotate rutin folytat�sa
MOV C, 0x08		; mem-be ki�rt carry-t vissza�rjuk a carrybe, mert az el�bb elrontottuk
MOV A, R5		; ACC-ba �tm�soljuk R5-�t
RLC A			; forgatunk egyet balra. ha az R4-b�l j�tt �tvitel, a carry-n kereszt�l azt beforgatjuk
MOV R5, A		; vissza�rjuk R5-be az eredm�nyt
DJNZ R8_CIM, Rotate		; ha kell m�g forgatni (Bank1R0 szerint), akkor visszaugrunk a rutin elej�re, �s forgatunk m�g

MOV A, R6		;az eredm�nyt ki�rjuk (R6+=R4)
ADD A, R4
MOV R6, A
MOV 0x08, C		; carry-t lementj�k, hogyk�s�bb vissza tudjuk olvasni
	MOV A, R7		; ebben a r�szben csak az OV-t vizsg�ljuk meg, hogy keletkezik-e, csak az ACC-ban dolgozunk
	ADDC A, R5 		; ACC=R7+R5+C lesz
	XRL A, R5		; akkor lesz OV, ha R5 �s a ACC legfels� b�jtja nem egyezik meg
	ANL A, #0x80	; ugyanis ekkor negat�v->pozit�v �tmenet van, vagy ford�tva, ami pontosan t�lcsordul�s eset�n van
	CJNE A, #0x00, SetBitForOV2		;ha az 1, azaz a k�t fels� bit nem egyezik, akkor elugunk az OV be�ll�t� programr�szre
Rotate3:		; Rotate rutin folytat�sa
MOV C, 0x08		; mem-be ki�rt carry-t vissza�rjuk a carrybe, mert az el�bb elrontottuk
MOV A, R7		
ADDC A, R5		
MOV R7, A		; R7=R7+R5+C lesz, teh�t R7-be beker�l a j� eredm�ny
RET			; k�sz vagyunk az adott forgat�si ciklussal, visszat�r�nk a MainLoop-ba

SetBitForOV:		; ide akkor jutunk, ha t�lcsordul�s volt R5 forgat�sa k�zben 
	SETB 0x00		; a 0x00 c�men tal�lhat� bitet haszn�ljuk az OV jelz�s�re
	LJMP Rotate2	; visszat�r�nk oda, ahonnan elugrottunk
	
SetBitForOV2:		; ide akkor jutunk, ha t�lcsordul�s volt R7=R7+R5+Carry sz�m�t�sa sor�n
	SETB 0x00		; a 0x00 c�men tal�lhat� bitet haszn�ljuk az OV jelz�s�re
	LJMP Rotate3	; visszat�r�nk oda, ahonnan elugrottunk
