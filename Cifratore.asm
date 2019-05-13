# GRUPPO DI LAVORO :
# DUCCIO SERAFINI			E-MAIL: duccio.serafini@stud.unifi.it
# ANDRE CRISTHIAN BARRETO DONAYRE	E-MAIL: andre.barreto@stud.unifi.it
# 
# DATA DI CONSEGNA: 
#

.data 

# STRINGHE DEDICATE PER LA VISUALIZZAZIONE DELLA OPERAZIONE IN CORSO:
		opCifra:	.asciiz			"Cifratura in corso...\n"
		opDecif:	.asciiz			" \nDecifratura in corso...\n"
		done:		.asciiz	 	"\nOperazione Terminata. " 
# DESCRITTORI DEI FILE IN INGRESSO: 
		messaggio:	.asciiz		"C:/Users/duxom/Desktop/Mars/messaggio.txt"
		chiave:		.asciiz	 	"C:/Users/duxom/Desktop/Mars/chiave.txt"
# DESCRITTORI DEI FILE IN USCITA: 
	 	msgCifrato:	.asciiz		"C:/Users/duxom/Desktop/Mars/messaggioCifrato.txt"	
	 	msgDecifrato:	.asciiz		"C:/Users/duxom/Desktop/Mars/messaggioDecifrato.txt"
	 	space:		.asciiz		"\n"
.align 2
		
# BUFFER DECICATI AL SUPPORTO DELLE PROCEDURE:
		algorithmJAT:	.space		20
		statusABC:	.space		36
		supportInvert: 	.space		4	
		occurrenceBuffer:.space		1500
		supportBuffer: 	.space		1500
					
# BUFFER DEDICATI ALLA LETTURA DEI DATI DEI FILE IN INPUT:
		bufferReader:	.space	    	1500
		bufferKey:	.space	   	 4
		
					
.align 2

.text
.globl main
	
main:		addi	$sp, $sp,-16			# alloco lo spazio per una word nello stack
		#sw	$ra, 0($sp)			# salvo nello stack l'indirizzo di ritorno del chiamante
		#sw 	$s0, 4($sp)
		#sw 	$s1, 8($sp)
		#sw 	$s2, 12($sp) 
		
		jal	algorithmTable			# inizializzo una JAT TABLET PER GLI ALGORITMI DA CHIAMARE
		
		# # # AVVIO FASE CIFRATURA
		la	$a0, chiave
		jal	readKey				# inizializzo il buffer dedicato alla chiave CIFRATURRA
		
		la	$a0, messaggio
		jal	readMessage
		
	
		li	$s7, 0				# VARIABILE DI STATO : settata in  CIFRATURA 
									
		jal	cifratura			# FASE CIFRATURA 
		
		li	$s7, 1				# VARIABILE DI STATO : settata in  DECIFRATURA
		
		
		la	$a0, msgCifrato			# SCRITTURA-FILE: MESSAGGIOCIFRATO.TXT
		jal	writeMessage			# il messaggio cifrato si trova in bufferReader 
		
		li	$v0, 16
		la	$a0, msgCifrato
		syscall
		
		# # # AVVIO FASE DECIFRATURA
		
		la	$a0, msgCifrato
		jal	readMessage
							
		jal	decrifratura			# FASE DECIFRATURA		
		
		la	$a0, msgDecifrato		# SCRITTURA-FILE: MESSAGGIOCIFRATO.TXT
		jal	writeMessage			# il messaggio decifrato si trova in bufferReader
		
		li	$v0, 16
		la	$a0, msgDecifrato
		syscall
		
		j exit  
		
# MAIN PROCEDURES :VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV					
cifratura:	addi	$sp, $sp,-4			# salvo il $ra corrente per potere tornare 
		sw	$ra, 0($sp)			# al main a fine alla fine della procedura
		
		li	$v0, 4				# messaggio indicativo per indicare la procedura in corso 
		la	$a0, opCifra			
		syscall 
		
		la	$a1, statusABC 			#  inizializzo l'array degli stati dedicati per gli algoritmi A-B-C
		jal	setStatusABC
		
		la	$s6, bufferKey			# da giutificare
		
		jal	core  
		

uscita:		lw	$ra, 0($sp)			
		addi	$sp, $sp, 4			 
		jr	$ra				# reimpostato il registro $ra iniziale per potere tornare al main
		
# -----------------------------------------------------------------------------------------------------------------------
decrifratura:	addi	$sp, $sp,-4			# salvo il registro $ra corrente per potere tornare 
		sw	$ra, 0($sp)			# al main a fine alla fine della procedura

		li	$v0, 4				# messaggio indicativo per indicare la procedura in corso 
		la	$a0, opDecif						
		syscall 			 
		
		la	$a1, statusABC 			#  inizializzo l'array degli stati dedicati per gli algoritmi A-B-C
		jal	setStatusABC
				
		jal core  

		lw	$ra, 0($sp)				
		addi	$sp, $sp, 4			
		jr	$ra				# reimposto il registro $ra iniziale per potere tornare al main
									
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		
		# INIZIO CORE
core:		addi 	$sp, $sp, -4			# salvo il registro $ra corrente per potere tornare
		sw 	$ra, 0($sp)			# alla procedura chiamante
		
		la	$s5, bufferReader		# $s5 registro di partenza per bufferReader 
		la	$s4, statusABC			# $s4 registro di partenza per l'array degli statusABC 
		
		beq	$s7, 0, nextAlg
		li	$s3, -1
		addi	$s6, $s6, -1			# perche noi ci fermiamo due valori fuori l'array
		j	step_over_one 
nextAlg:	li 	$s3, 1	
step_over_one: 	lb 	$t0, ($s6)			# carico il primo simbolo delle chiavi 
		
		beqz	$t0, EXITCore			# controllo se sono arrivato a fine stringa.
		blt	$t0, 65, goNext			# per ignorare eventuali spazi vuoti non visibili
	  	bgt	$t0, 69, goNext
	  	
		li	$t1, 65				# # I varia algoritmi da chiamare vengono riconosciuti   # migliorare
		sub	$t0, $t0, $t1			# atraverso una operazione di sottrazione con 65  
	  	
	  	slt	$t1, $t0, $zero			# 
		beq	$t1, 1, goNext
	  	bgt	$t0, 4, EXITCore
	  		 
		move	$a0, $t0	
		
		la	$a1, supportBuffer
		jal	cleanBuffer			# NUOVO!!! IN QUESTO MODO SVUOTA SUPPORT BUFFER PRIMA
							# OGNI ALGORITMO
		jal	goToAlg
		
goNext:		add	$s6, $s6, $s3			# aggiorna il registro di 1 per chiamare |||| S3 è l'offset||||
		j	step_over_one			# l'algoritmo successivo

EXITCore:	lw	$ra, 0($sp)			# reimposto il registro $ra iniziale per potere tornare	
		addi	$sp, $sp, 4
		jr	$ra				
		# FINE CORE
		
# procedura che calcola la posizione in cui saltare nella tabella degli algoritmi
# parametri in $a2 vuole il risultato da moltiplicare
#  

goToAlg:	addi	$sp, $sp,-16			# salvo il registro $ra corrente per potere tornare 
		sw	$ra, 0($sp)			# al main a fine alla fine della procedura
		sw	$t2, 4($sp)
		sw	$t3, 8($sp)
		sw	$t0, 12($sp)
		
		li	$t2, 4				# costante di default per il calcolo dell'indirizzo in cui saltare
		mult	$t2, $a0			# moltiplico la costante per la scelta 
		mflo	$t2				# riprendo il risultato dal regristro dedicato alla moltiplicazione																							
		lw	$a0, algorithmJAT($t2)		# carico la posizione richiesta 																			
		jr	$a0				# viene eseguito il salto alla posizione richiesta
	
	
ritorno_scelta: lw	$t0, 12($sp)
		lw	$t3, 8($sp)
		lw	$t2, 4($sp)
		lw	$ra, 0($sp)				
		addi	$sp, $sp, 16			
		jr	$ra				# reimposto il registro $ra iniziale per potere tornare al CORE
		
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

# TOEMPTY: PROCEDURA DEDICATA A PULIRE IL CONTENUTO DI QUALSIASI BUFFER IN INGRESSO 
# PARAMETRI : 		$a1 <-- buffer da pulire
	
cleanBuffer:	lb	$t0, ($a1)		# Carico in $t0 l'elemento puntato
		beqz	$t0, endClean		# Se e' zero sono arrivato alla fine della stringa
		move	$t0, $zero		# Altrimento svuoto la variabile
		sb	$t0, 0($a1)		# Per caricarla nella stringa, cancellando il precedente elemento
		addi	$a1, $a1, 1		# Vado al prossimo elemento
		
		j	cleanBuffer
		
endClean:	jr	$ra



# PROCEDURA GENERICA CHE SVOLGERA IL CIFRATURA E LA DECIFRATURA DEGLI ALGORITMI A - B - C 
# IL SUO COMPORTAMENTO E' DEFINITO DA PROCEDURE DEDICATE CHE SETTANO DEI FLAG AD OGNI CHIAMATA
# PARAMETRI:		$s0 <--  offset di inizio di scorrimento del buffer
#			$s1 <--  flag distinzione tra operazione di CRIFRATURA e DECIFRATURA
#			$s2 <--	 offset dedicato al passo di scorrimento del buffer
#
# VALORE DI RITORNO:	VOID

shifter:	addi	$sp, $sp,-8			# salvo il registro $ra corrente per potere tornare 
		sw	$ra, 0($sp)
		sw	$a2, 4($sp)
		
		la	$a3, bufferReader		# carico il buffer di lavoro 
		move	$s6, $a0			# riprendo l'indirizzo di partenza de array degli stati
		
		lb	$s0, 0($s6) 			# $s0: definiamo l'indice di partenza 
		add	$a3, $a3, $s0		
								
convertitore:	lb	$t0, 0($a3) 			# $t0 carichiamo la lettera da cifrare
		beqz    $t0, uscitaShifter 		# controlliamo di non essere arrivati alla fine 
		li	$t1, 255			# definiamo il valore del modulo 
		li	$t2, 4				# costante di cifratura	
		lb	$t3, 4($s6)			# $s1 : carico il flag di operazione		
	
decriptazione:	beqz	$t3, criptazione		# discrimiante delle operazioni di cifratura o decifratura 
		li 	$t4, -1				# AGGIUNGERE CONTROLLO SUI NEGATIVI   
		mult	$t2, $t4			#
		mflo	$t2		
	
criptazione:	add	$t0, $t0, $t2			# operazione di cifratura			
		div	$t0, $t1
		mfhi	$t0  		 		
		sb	$t0, 0($a3)			# salvo il nuovo contenuto da stampare sullo stesso buffer !!!
	
		lb	$s2, 8($s6)			# $s2: carico il passo per la lettura del successivo   
		add	$a3, $a3, $s2
					
		j 	convertitore
		
uscitaShifter:	addi 	$v0, $a3, -1			# $V0: valore di ritorno 
		
		lw	$a2, 4($sp)
		lw	$ra, 0($sp)			# reimposto il registro $ra iniziale per potere tornare	
		addi	$sp, $sp, 8			# al main 
		jr	$ra				# fine SHIfTER





# PROCEDURA GENERICA DEDICATA ALL'INVERSIONE DI QUALCUASI STRINGA SIA DATA IN PASTO 
# PARAMETRI : $a2 <--- bufferReader , buffer contenente la stringa a invertire 
#	      $a3 <--- buffer di support alla procedura di inversione
	
algD:		add	$sp, $sp, -4
		sw	$ra, 0($sp)
		
		move	$t9, $a2 			# bufferReader 
		move	$t8, $a3			# support buffer	
		
		jal	bufferLenght
							# recupero il valore di ritorno : lunghezza del buffer corrente
		move 	$s0, $v1
		
		#li	$v0, 1
		#move	$a0, $s0
		#syscall
							# Ciclo di inversione:				
reversal:	beq	$t0, $s0, swapVet		# Se il numero dei caratteri inseriti è pari alla lunghezza del buffer
							# allora posso uscire dalla procedura	
		lbu	$t1, ($a2)
		
		#li	$v0, 11
		#move	$a0, $t1
		#syscall
		
		beq	$t1, 10 , go_Other		# Altrimenti metto in $t1 l'elemento del buffer di input
		sb	$t1, ($a3)			# e lo salvo nel buffer di uscita
		addi	$a2, $a2, -1			# Vado al carattere precedente del buffer di input	
		addi	$a3, $a3, 1			# Scorro alla posizione successiva del buffer di output
		addi	$t0, $t0, 1			# Aumento di 1 il contatore dei caratteri inseriti
		j 	reversal
		
go_Other:	addi	$a2, $a2, -1			# Vado al carattere precedente del buffer di input
		j	reversal
		
swapVet: 	la	$a1, bufferReader			
		jal	cleanBuffer
			
		la	$a3, supportBuffer		# $a2 : sovrascrivo il contenuto di bufferReader
		move	$a2, $t9			# $a3 : vettore che con i dati partenza 					 												 							
		move	$a1, $s0			# $a1 : grandeza dei buffer
		jal	overWrite
		
		move	$v0, $v1			# valore di ritorno : è depositato sul buffer principale
			
		lw	$ra, 0($sp)
		add	$sp, $sp, 4
		
		jr	$ra				# fine algoritmo D
	
	
# procedura che sovrascrive il contenuto di qualasiasi vettore 
#	parametri 	$a3 : vettore che con i dati partenza 	
# 			$a2 : vettore di arrivo
#			$s0 : mettiamo la lunghezza dell'array da sovrascivere

overWrite:	add	$sp, $sp, -8
		sw	$ra, 0($sp)
		sw	$s0, 4($sp)

		la	$t9, bufferReader			# $a2 : sovrascrivo il contenuto di bufferReader 		

		la	$t8, supportBuffer			# $a3 : vettore che con i dati partenza 
		
	#	li	$v0, 4
	#	move	$a0, $t8
	#	syscall
		
		move	$t0, $zero
		move	$s0, $a1
loop_overWrite: beq	$t0, $s0, EXIT_loopOW
		lb	$t1, 0($t8)
		
		beq	$t1, 10, jumpOW 
		sb	$t1, 0($t9)
		j 	stepOver
		
jumpOW:		addi	$t8, $t8, 1 
		j	loop_overWrite
		
stepOver:	addi	$t8, $t8, 1 
		addi	$t9, $t9, 1
		addi	$t0, $t0, 1
		j	loop_overWrite
		
EXIT_loopOW:	move	$v1, $a2			# Restituisco in $v0 il buffer di output

		lw	$s0, 4($sp)		
		lw	$ra, 0($sp)
		addi	$sp, $sp, 8
		jr 	$ra
		

# procedura che conta il numero dei caratteri nel buffer in ingresso
# vuole in $a2 la stringa da contare la lunghezza
#
bufferLenght:	add	$sp, $sp, -12
		sw	$ra, 0($sp)			# Metodo che conta quanti elementi sono presenti nel buffer
		sw	$v0, 4($sp)
		sw	$a1, 8($sp)
		
		move	$t0, $zero			# Inizializzo contatore degli elementi della stringa a 0
				
counterLoop:	lbu	$t1, 0($a2)			# Carico il carattere puntato in $t1
		beqz	$t1, EXIT_loopCounter		# Se sono arrivato alla fine della stringa il metodo termina	
		beq	$t1, 10, EXIT_loopCounter
		addi	$t0, $t0, 1			# Altrimenti aumento il contatore di 1
jumpOver:	addi	$a2, $a2, 1			# Scorro alla posizione successiva del buffer
		j 	counterLoop			# Inizio un nuovo ciclo

EXIT_loopCounter:
		addi	$a2, $a2, -1			# Dato che il il puntatore e' fuori dal buffer, lo faccio tornare						# indietro di una posizione
							# ritorno il numero delgi l'elementi $v1
		#addi	$v1, $t0, 0
		addi	$v1, $t0, 1			# PERCHE?????
			
		move	$t0, $zero			# Reinizializzo $t0 per contare il numero di elementi che verranno inseriti
		
		lw	$a1, 8($sp)
		lw	$v0, 4($sp)
		lw	$ra, 0($sp)
		add	$sp, $sp, 12
		jr $ra
		
# AlgE : algoritmo che conta le occorence della stringa in pasto 
#	$a2 - bufferReader
#	$a3 - supportBuffer
#
AlgE:			add	$sp, $sp, -4
			sw	$ra, 0($sp)
		
			la	$a2, occurrenceBuffer		# Carico il buffer che conterr? gli elementi presenti in bufferReader
							# ripetuti una sola volta
			jal	occurrence			# Salto al metodo che crea tale buffer

			la	$a2, occurrenceBuffer		# Rimetto il puntatore all'inizio del buffer
			move	$t5, $zero			# Inizializazzione del contatore degli elementi inseriti in supportBuffer 
	
			jal	writer				# Salto al metodo che produce l'output di cifratura
			
			la	$a2, supportBuffer
			jal	bufferLenght
			addi	$a1, $v1,-2			# motivi di lunghezzA
			#move	$a1, $v1
					
			la	$a2, bufferReader
			la	$a3, supportBuffer
			jal	overWrite
					
			la	$a1, supportBuffer
			jal	cleanBuffer
			
			la	$a1, occurrenceBuffer
			jal	cleanBuffer
			
			lw	$ra, 0($sp)
			add	$sp, $sp, 4
			jr	$ra				
			# fine algoritmo E
		
# Inizio del metodo che riempe occurrenceBuffer
occurrence:		lbu	$t1, ($a1)			# Carico in $t1 il carattere puntato di bufferReader
			beq	$t1, 10,finish_occurence		# Se sono alla fine del buffer allora il metodo termina
			beqz	$t1, finish_occurence
								# Frammento di metodo che riconosce se un elemento e' gia' stato inserito	
control:		lbu	$t2, ($a2)			# Carico l'elemento puntato in $t2
			beqz	$t2, firstOccurrence		# Se in quella posizione non e' presente alcun elemento allora e' la prima
								# volta che viene trovato. Vado quindi a "firstOccurrence"
			beq	$t1, $t2, ignore		# Se gli elementi sono uguali invece vado a "ignore"
			addi	$a2, $a2, 1			# Altrimenti se sono diversi scorro di una posizione il buffer delle
			j	control				# occorrenze per controllare se l'elemento e' gia' stato trovato prima
								# oppure e' la prima volta
								# Metodo che gestisce la prima occorrenza di un elemento
firstOccurrence:	sb	$t1, 0($a2)			# Salvo l'elemento che ho trovato nel buffer delle occorrenze
			addi	$a1, $a1, 1			# Vado alla posizione successiva di bufferReader
			la	$a2, occurrenceBuffer		# Rimetto il puntatore all'inizio del buffer delle occorrenze
			
		
				
			j	occurrence			# e inizio nuovamente a cercare le prime occorrenze degli elementi
	
# Metodo che ignora un elemento in caso di uguaglianza
ignore:			addi	$a1, $a1, 1			# Scorro alla posizione successiva di bufferReader
			la	$a2, occurrenceBuffer		# Rimetto il puntatore all'inizio del buffer delle occorrenze
			j	occurrence			# e inizio nuovamente a cercare le prime occorrenze degli elementi

finish_occurence:	jr	$ra				# Metodo che torna al metodo principale dell'algoritmo
	
	
# Metodo che inizia il ciclo di cifratura del messaggio
writer:			la	$a1, bufferReader		# Torno all'inizio di bufferReader per leggere il messaggio
			move	$t0, $zero			# Inizializzo il contatore delle posizioni
	
							# Metodo che scorre il buffer delle occorrenze per esaminare uno
							# specifico elemento all'interno di bufferReader
elements:		lbu	$t2, ($a2)			# Carico l'elemento puntato di occurrenceBuffer in $t2
			beqz	$t2, end_writer			# Se e' arrivato alla fine del buffer allora l'algoritmo termina
			sb	$t2, 0($a3)			# Altrimenti salvo $t2 all'interno di supportBuffer, in modo tale che
							# evidenzi l'elemento preso in esame in occurrenceBuffer
			addi	$a3, $a3, 1			# Vado alla posizione successiva di supportBuffer
			addi	$t5, $t5, 1			# Dato che ho inserito un elemento aumento il contatore $t5 di 1
	
# Metodo che stampa le posizioni in cui si trova l'elemento esaminato
positions:		lbu	$t1, ($a1)			# Carico l'elemento puntato di bufferReader in $t1
			beqz	$t1, nextElement		# Se sono alla fine del buffer allora vuol dire che ho controllato tutte le 
							# occorrenze dell'elemento puntato in occurrenceBuffer, e posso andare al prossimo
			bne	$t1, $t2, nextControl		# Se $t1 e $t2 sono diversi allora vado al metodo che scorre al controllo
							# successivo sul bufferReader
			li	$t3, '-'			# Altrimenti carico il simbolo '-'
			sb	$t3, 0($a3)			# e lo salvo in supportBuffer per separare le occorrenze

			addi	$t5, $t5, 1			# Dato che ho inserito un elemento in supportBuffer aumento $t5 di 1
	
			move	$t4, $t0			# Metto in $t4 il contatore delle posizioni
			move	$t8, $zero			# Inizializzo il contatore delle cifre
	
			sgt	$t7, $t4, 9			# Se il contatore e' superiore a 9 imposto $t7 a 1
			beq	$t7, 1, digitsCounter		# In tal caso vado al metodo che conta da quante cifre e' composto
							# il contatore
# Metodo che salva una sola cifra	
storeDigit:		addi	$a3, $a3, 1			# Avanzo di uno perche' puntatore punta a "-"
			addi	$t0, $t0, 48			# Aggiungo 48 a $t0 per convertirlo in ASCII
			sb	$t0, 0($a3)			# Salvo il valore ottenuto in supportBuffer
			addi	$t0, $t0, -48			# Faccio tornate il contatore di posizioni al valore precedente
			addi	$a3, $a3, 1			# Avanzo di una posizione su supportBuffer
			addi	$t5, $t5, 1			# Aumento di uno il contatore degli elementi
	
# Metodo che passa al prossimo controllo
nextControl:		addi	$a1, $a1, 1			# Vado all'elemento successivo di bufferReader
			addi	$t0, $t0, 1			# Aumento di 1 il contatore delle posizioni
			j	positions			# Torno al controllo delle posizioni
	
# Metodo che permette di passare al prossimo controllo degli elementi
							# basato sul buffer delle occorrenze
nextElement:		li	$t3, ' '			# Carico in $t3 uno spazio per separare le varie occorrenze
			sb	$t3, 0($a3)			# Lo salvo all'interno di supportBuffer
			addi	$a3, $a3, 1			# Avento inserito questo elelemento avanzo alla posizone successiva
			addi	$t5, $t5, 1			# E aumento di 1 il contatore degli elementi
			addi	$a2, $a2, 1			# Passo al prossimo elemento di confronto presente in occurrenceBuffer
			j	writer				# E ricomincio il ciclo
	
# Metodo che conta da quante cifre e' formata l'occorrenza 
digitsCounter:		beqz	$t4, storeDigits		# Se ho contato tutte le cifre allora vado al metodo che salva cifre multiple 
			li	$t9, 10				# Metto in $t9 il valore 10
			div	$t4, $t9			# Per effettuare la divisione ed eliminare l'ultima cifra
			mflo	$t4				# Salvo il quoziente in $t4
			addi	$t8, $t8, 1			# Aumento di 1 il contatore delle cifre
			j	digitsCounter			# Ricomincio il ciclo di divisione

# Metodo che salva in supportBuffer occorrenze con piu' di una cifra
storeDigits:		move	$s0, $t8			# Salvo il numero delle cifre nella costante $s0
			add	$a3, $a3, $s0			# Avanzo del numero di cifre corretto su supportBuffer
			move	$t4, $t0			# Metto in $t4 il contatore delle posizioni
	
# Ciclo di salvataggio di cifre multiple
storeCicle:		div	$t4, $t9			# Divido il contatore delle posizioni per 10
			mflo	$t4				# Salvo in $t4 il quoziente
			mfhi	$t8				# Salvo in $t8 il resto
							# per poi salvare la cifra ottenuta nella giusta posizione
			addi	$t8, $t8, 48			# Aggiungo 48 a $t8 per convertirlo in ASCII
			sb	$t8, ($a3)			# Salvo il valore cos? ottenuto nella giusta posizione
			beqz	$t4, offset			# Se il numero e' stato stampato completamente allora termino il ciclo
			addi	$a3, $a3, -1			# Altrimenti vado alla posizione precedente del buffer
							# per salvare la cifra precedente della posizione
			j	storeCicle			# Ricomincio il ciclo di salvataggio

# Metodo che imposta nelle giuste posizioni i puntatori ai buffer
# e aumenta i contatori del valore corretto
offset:			add	$a3, $a3, $s0			# Avanzo nuovamente in supportBuffer del numero di cifre appena salvate
			add	$t5, $t5, $s0			# Il contatore dei caratteri inseriti aumenta del numero di cifre salvate
			addi	$a1, $a1, 1			# Avanzo di 1 in bufferReader
			addi	$t0, $t0, 1			# Aumento di 1 il contatore delle posizioni
			j	positions			# Torno a cercare le posizioni degli elementi
end_writer:		jr	$ra				# Torno al metodo principale
	

# vuole l'indirizzo di partenz $a1
#
#
decifraE:	addi	$sp, $sp -4
		sw	$ra, 0($sp)
		
		
decryption_E:	li	$s1, 10					# $t1 e' la costante che servira' per formare le posizioni superiori al 9

													
# Metodo che trova l'elemento da piazzare
itemToPlace:	la	$a2, supportBuffer			# Imposto l'indirizzo iniziale del buffer di supporto in $a2
		lbu	$t0, ($a1)				# Carico il primo elemento della frase in $t0 (che sara' l'elemento
								# che dovr? essere inserito per formare la frase originaria)
		addi	$a1, $a1, 2				# Scorro avanti di 2 dato che dopo questo elemento ci sara'sicuramente '-'
		move	$t1, $zero				# Inizializzo la variabile che formera' la posizione
	
								# Ciclo che trova la posizione in cui piazzare l'elemento
findPos:	lbu	$t2, ($a1)				# Carico l'elemento puntato in $t2
		beq	$t2, '-', placeItem			# Se tale elemento e' '-'
		beq	$t2, ' ', placeItem			# O uno spazio
		beqz	$t2, placeItem				# Oppure la fine della stringa
								# Allora ho trovato la posizione giusta dove collocare l'elemento
		mult	$t1, $s1				# Altrimenti vuol dire che la posizione non e' completa
		mflo	$t1					# Salvo il risultato della moltiplicazione di $t1 per 10 in $t1
		addi	$t2, $t2, -48				# Converto l'elemento da ASCII a numero
		add	$t1, $t1, $t2				# Sommo la cifra per formare la posizione
		addi	$a1, $a1, 1				# Scorro di 1 il buffer
		j	findPos					# Ricomincio il ciclo
	
# Metodo che piazza l'elemento una volta trovata la sua posizione
placeItem:	add	$a2, $a2, $t1			# Mi sposto alla posizione indicata
		sb	$t0, 0($a2)			# Inserisco l'elemento in posizione corretta
		
		addi	$a1, $a1, 1			# Avanzo di 1 sul buffer
		beq	$t2, ' ', itemToPlace		# Se prima ho trovato uno spazio allora devo trovare
		
							# il prossimo elemento da piazzare 
		la 	$a2, supportBuffer		# Se invece ho trovato un '-' significa che devo piazzare l'elemento
							# altre volte, torno quindi all'inizio del buffer decodificato
		move	$t1, $zero			# Metto nuovamente a 0 il contatore delle posizioni
		beq	$t2, '-', findPos		# E torno al metodo che trova le posizioni
		
							# ALTRIMENTI VUOL DIRE CHE SONO ARRIVATO ALLA FINE DELLA STRINGA
							# E IL PROGRAMMA PUO' TERMINARE!!
		
		la	$a1, bufferReader
		jal	cleanBuffer
							
		la	$a2, supportBuffer
		addi	$a2, $a2, 1
		jal	bufferLenght
						# motivi di lunghezzA
		move	$a1, $v1
		la	$a2, bufferReader
		la	$a3, supportBuffer
		jal	overWrite
		
		la	$a1, supportBuffer
		jal	cleanBuffer
		
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
				

# writeMessage : procedura dedicata a scrivere il file che deve essere CIFRATO o DECIFRATO
# parametri : 		$a0 : descritttore del file da leggere (l'etticheta che conitiene il percorso) 
#
# valore di ritorno: 	void 
# il suo effetto è quello di riempire il file da trattare 	
writeMessage:	addi 	$sp, $sp, -4
		sw	$ra, 0($sp)		# salvo il registro di ritorno del chiamante
						
						# $a0<--DESCRITTORE DEL FILE
		li	$v0, 13			# OPEN-FILE: PROCEDURA CHE PERMETTE DI APRILE UN FILE IN LETTURA / SCRITTURA
		li	$a1, 1			# flag di scrittura
		li	$a2, 0			#   
		syscall
					
		move	$a0, $v0	 	# passo il descrittore del file 
		move	$a1, $a0
		
		la	$a2, bufferReader
		jal	bufferLenght
			
		addi	$a2, $v1,-1		# dimensione del buffer
		la	$a1, bufferReader	
		jal	writeFile		# leggo il file e carico il buffer dedicato
		
		li	$v0, 16			# Close File Syscall
		move	$a0, $a1
		syscall

		lw	$ra, 0($sp)		# reimposto il registro del chiamante
		addi	$sp, $sp, 4
		jr $ra				
		
# procedura che inizializza la tabella dedicata agli algoritmi 
algorithmTable: la 	$t7, algorithmJAT
		la	$t6, algorithm_A
		sw	$t6, 0($t7)					
		la	$t6, algorithm_B
		sw	$t6, 4($t7)		
		la	$t6, algorithm_C
		sw	$t6, 8($t7)
		la	$t6, algorithm_D
		sw	$t6, 12($t7)
		la	$t6, algorithm_E
		sw	$t6, 16($t7)		

		move	$v0, $t7		# salvo l'indirzzo della menuJAT in $v0
		jr	$ra  		


# setStatusABC setta l'array degli stati dedicati alle procedure ABC
# ofsetper leggere lo stato : 0 è A , 12 è B,  24 è C
# 	
setStatusABC:	addi 	$sp, $sp, -4
		sw 	$ra, 0($sp)
		
		move	$t9, $a1 				# faccio una copia perche torna comodo
	
		jal algAStatus

		addi	$a1, $a1, 12
		jal algBStatus
	
		addi 	$a1, $a1, 12
		jal algCStatus
	
		move	$v0, $t9				# ritorno il registro di inzio 
	
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4	
		jr $ra		
				

# ALGORITMO A- STATUS:  PROCEDURA DEDICATA AL SETTAGGIO DEI FLAG DEDICATI ALL'ALGORITMO A 		
algAStatus:	addi 	$sp, $sp, -4
		sw 	$ra, 0($sp)

		move	$t1, $a1 # sposto il riferimento al buffer degli stati per poterlo trattare meglio
		li	$s0, 0
		li	$s2, 1
		sb	$s0, 0($t1)	# carico l'indirizzo di partenza $s0
		sb	$s2, 8($t1)	# carico il passo di lettura $s2	
		beqz 	$s7, CifraturaA
		li	$s1, 1
		sb	$s1, 4($t1)	# carico $s1 che specifica l'operazione da eseguire		
		j	DecifraturaA
CifraturaA:	li	$s1, 0
		sb	$s1, 4($t1)	# carico $s1 che specifica l'operazione da eseguire

DecifraturaA:	lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr $ra

# ALGORITMO B- STATUS:  PROCEDURA DEDICATA AL SETTAGGIO DEI FLAG DEDICATI ALL'ALGORITMO B 				
algBStatus:	addi 	$sp, $sp, -4
		sw 	$ra, 0($sp)
		
		move	$t1, $a1
		li	$s0, 0
		li	$s2, 2
		sb	$s0, 0($t1)	# carico l'indirizzo di partenza $s0
		sb	$s2, 8($t1)	# carico il passo di lettura $s2		
		beqz 	$s7, CifraturaB
		li	$s1, 1
		sb	$s1, 4($t1)	# carico $s1 che specifica l'operazione da eseguire			
		j	DecifraturaB
CifraturaB:	li	$s1, 0
		sb	$s1, 4($t1)

DecifraturaB:	lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr 	$ra

# ALGORITMO C- STATUS:  PROCEDURA DEDICATA AL SETTAGGIO DEI FLAG DEDICATI ALL'ALGORITMO C		
algCStatus:	addi 	$sp, $sp, -4
		sw 	$ra, 0($sp)
		
		move	$t1, $a1
		li	$s0, 1
		li	$s2, 2
		sb	$s0, 0($t1)	# carico l'indirizzo di partenza $s0
		sb	$s2, 8($t1)	# carico il passo di lettura $s2		
		beqz 	$s7, CifraturaC
		li	$s1, 1
		sb	$s1, 4($t1)	# carico $s1 che specifica l'operazione da eseguire				
		j	DecifraturaC
CifraturaC:	li	$s1, 0	
		sb	$s1, 4($t1)
		
DecifraturaC:	lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr $ra
		
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

 # chiamata ad gli algoritmi ci cifratura e decifratura
						
algorithm_A:	addi 	$sp, $sp, -16			# chiama Shifter : settato per algoritmo A
		sw 	$s6, 0($sp)
		sw 	$s5, 4($sp)
		sw 	$s4, 8($sp)
		sw	$t0, 12($sp)
		sw	$ra, 16($sp)
				
		move	$a0, $s4			# passo il registro di inzio degli stati 
		jal	shifter
		
		lw	$ra, 16($sp)
		lw	$t0, 12($sp)
		lw	$s4, 8($sp)
		lw	$s5, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 16
		
		j	ritorno_scelta
		
						
algorithm_B:	addi 	$sp, $sp, -16			# chiama Shifter : settato per algoritmo B
		sw 	$s6, 0($sp)
		sw 	$s5, 4($sp)
		sw 	$s4, 8($sp)
		sw	$t0, 12($sp)
		sw	$ra, 16($sp)
							
		addi 	$s4, $s4, 12
		move	$a0, $s4			# passo il registro di inzio degli stati 	
		jal	shifter

		lw	$ra, 16($sp)
		lw	$t0, 12($sp)
		lw	$s4, 8($sp)
		lw	$s5, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 16
	
		j	ritorno_scelta
		
		
						
algorithm_C:	addi 	$sp, $sp, -16			# chiama Shifter : settato per algoritmo C
		sw 	$s6, 0($sp)
		sw 	$s5, 4($sp)
		sw 	$s4, 8($sp)
		sw	$t0, 12($sp)
		sw	$ra, 16($sp)
		
		addi 	$s4, $s4, 24
		move	$a0, $s4			# passo il registro di inzio degli stati 
		jal	shifter
				
		lw	$ra, 16($sp)
		lw	$t0, 12($sp)
		lw	$s4, 8($sp)
		lw	$s5, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 16
		j	ritorno_scelta

						
algorithm_D:	addi 	$sp, $sp, -16			# chiama Inverter
		sw 	$s6, 0($sp)
		sw 	$s5, 4($sp)
		sw 	$s4, 8($sp)
		sw	$t0, 12($sp)
		sw	$ra, 16($sp)
		
		la 	$a2, bufferReader
		la	$a3, supportBuffer
		jal	algD
		
						
		lw	$ra, 16($sp)
		lw	$t0, 12($sp)
		lw	$s4, 8($sp)
		lw	$s5, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 16

		j	ritorno_scelta
		
						
algorithm_E:	addi 	$sp, $sp,-16			# countOccurence 
		sw 	$s6, 0($sp)
		sw 	$s5, 4($sp)
		sw 	$s4, 8($sp)
		sw	$t0, 12($sp)
		sw	$ra, 16($sp)
		
		la	$a1, bufferReader
		la	$a3, supportBuffer
		
		beq	$s7, 1, decifra_E
		jal	AlgE
		j	SO_decifra
		
decifra_E:	la	$a1, bufferReader		# buffer reader a questo punto arriva pieno con il valori giusti
		jal	decifraE
		
SO_decifra:	lw	$ra, 16($sp)
		lw	$t0, 12($sp)
		lw	$s4, 8($sp)
		lw	$s5, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 16
		
		
		j	ritorno_scelta
			
# ___________________________________________________________________________________________________________________________________________


# readMessage : procedura dedicata a leggere il file che deve essere CIFRATO o DECIFRATO
# parametri : 		$a0 : descritttore del file da leggere (l'etticheta che conitiene il percorso) 
#
# valore di ritorno: 	void 
# il suo effetto è quello di riempire il file da trattare 	
readMessage:	addi 	$sp, $sp, -4
		sw	$ra, 0($sp)		# salvo il registro di ritorno del chiamante
		
		jal	openFile		#  apre il file in solo lettura,il descrittore lo riceve dal main 		
		
		move	$a0, $v0	 	# passo il descrittore del file 
		la	$a1, bufferReader	# buffer che conterra il messaggio corrente 
		li	$a2, 255		# dimensione del buffer
		jal	readFile		# leggo il file e carico il buffer dedicato
			 		
		lw	$ra, 0($sp)		# reimposto il registro del chiamante
		addi	$sp, $sp, 4
		jr $ra

# readKey: Procedura dedicata alla lettura del file che contiene la CHIAVE di cifratura(decifratura)
# PARAMETRI : 		$a0 <-- DESCRITTORE DEL FILE 
#
# Valore di ritorno: 	void 
# il suo effetto è quello di riempire il file da trattare 
readKey:		addi 	$sp, $sp, -4		# Alloco spazio nel buffer per una parola
		sw   	$ra, 0($sp)		# Salvo il rigistro di ritorno del chiamante 
		jal 	openFile			# Apro il file in lettura
		
		move	$a0, $v0			# Sasso il descrittore del file per la prossima procedura
		la	$a1, bufferKey		# Carico il buffer che conterra' la chiave 
		li	$a2, 4			# Imposto la dimensione del buffer
		jal	readFile			# Vado alla procedura di lettura da file
													
		lw	$ra, 0($sp)		# Carico il registro di ritorno
		addi	$sp, $sp, 4		# Dealloco lo spazio della pila
		jr $ra				# Torno al precedente Jal
						
# OPEN-FILE: PROCEDURA CHE PERMETTE DI APRILE UN FILE IN LETTURA / SCRITTURA
# $a0: DESCRITTORE DEL FILE
# $a1: FLAG DI SOLO LETTURA
# $a2: (IGNORATO)
# VALORE DI RITORNO :	$v0 <-- Indirizzo di memoria del buffer con i dati letti
openFile:	li	$v0, 13			# Chiamata a sistema per apertura file	 
		li	$a1, 0	  		
		li	$a2, 0
		syscall	
		
		move $v1, $v0       		# Salvo il percorso del file in $v1
		jr $ra 
			
# READ-FILE: PROCEDURA PER LEGGERE IL CONTENUTO DEL FILE	
# $a0: DESCRITTORE DEL FILE	
# $a1: REGISTRO CHE CONTIENE L'INDIRIZZO DI PARTENZA DEL BUFFER DI RIFERIMENTO
# $a2: GRANDEZZA DEL BUFFER DI RIFERIMENTO
# VALORE DI RITORNO:	$v0<--REGISTRO DEL BUFFER CON I DATI LETTI		
readFile:	li 	$v0, 14	 
		syscall				  
 				
		jr $ra  
		
# WRITE-FILE: PROCEDURA PER SCRIVERE IL CONTENUTO NEL FILE
# $a0 : DESCRITTORE DEI FILE
# $a1 :	REGISTRO CHE CONTIENE L'INDIRIZZO DI PARTENZA DEL BUFFER DI RIFERIMENTO  
# $a2 :	GRANDEZZA DEL BUFFER DI RIFERIMENTO 
writeFile:   	li 	$v0, 15
    		syscall
    		
     		jr $ra 
# -----------------------------------------------------------------------------------------------------------------------		
exit:		# fine del programma
		lw 	$ra, 0($sp)
		lw 	$s0, 4($sp)
		lw 	$s1, 8($sp)
		lw 	$s2, 12($sp)
		addi 	$sp, $sp, 16
	
		li	$v0, 4				
		la	$a0, done		# visualizza il messaggio di terminazione del programma							
		syscall				
	
			
		li $v0,10
		syscall