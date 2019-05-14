# GRUPPO DI LAVORO :
# DUCCIO SERAFINI			E-MAIL: duccio.serafini@stud.unifi.it
# ANDRE CRISTHIAN BARRETO DONAYRE	E-MAIL: andre.barreto@stud.unifi.it
# 
# DATA DI CONSEGNA: 
#

.data 

# STRINGHE DEDICATE PER LA VISUALIZZAZIONE DELLA OPERAZIONE IN CORSO:
		opCifra:		.asciiz		"Cifratura in corso...\n"
		opDecif:		.asciiz		" \nDecifratura in corso...\n"
		done:		.asciiz	 	"\nOperazione Terminata." 
# DESCRITTORI DEI FILE IN INGRESSO: 
		messaggio:	.asciiz		"C:/Users/duxom/Desktop/Mars/messaggio.txt"
		chiave:		.asciiz	 	"C:/Users/duxom/Desktop/Mars/chiave.txt"
# DESCRITTORI DEI FILE IN USCITA: 
	 	msgCifrato:	.asciiz		"C:/Users/duxom/Desktop/Mars/messaggioCifrato.txt"	
	 	msgDecifrato:	.asciiz		"C:/Users/duxom/Desktop/Mars/messaggioDecifrato.txt"
.align 2
		
# BUFFER DECICATI AL SUPPORTO DELLE PROCEDURE:
		algorithmJAT:	.space		20
		statusABC:	.space		36
		supportInvert: 	.space		4	
		occurrenceBuffer:.space		1500
		supportBuffer: 	.space		1500
					
# BUFFER DEDICATI ALLA LETTURA DEI DATI DEI FILE IN INPUT:
		bufferReader:	.space	    	1500
		bufferKey:	.space	   	4	
.align 2

.text
.globl main
	
main:		addi	$sp, $sp, -16
		jal	algorithmTable		# Creo una JAT table per chiamare gli algoritmi
		sw	$ra, 0($sp)		# Salvo nello stack l'indirizzo di ritorno del chiamante
		sw 	$s0, 4($sp)
		sw 	$s1, 8($sp)
		sw 	$s2, 12($sp) 
		
################ AVVIO FASE CIFRATURA ################
		
		la	$a0, chiave		# Carico l'indirizzo del file che contiene la chiave
		jal	readKey			# Vado alla procedura che la legge
		
		la	$a0, messaggio		# Carico l'indirizzo del file che contiene il messaggio
		jal	readMessage		# Vado alla procedura che lo legge
		
		li	$s7, 0			# VARIABILE DI STATO : settata per la CIFRATURA 
									
		jal	cifratura		# FASE CIFRATURA
		
		la	$a0, msgCifrato		# Carico l'indirizzo del file in cui verra' scritto il messaggio cifrato
		jal	writeMessage		# E vado alla procedura che lo scrive
		
		li	$v0, 16
		la	$a0, msgCifrato		# Chiusura del file del messaggio cifrato
		syscall
		
################ AVVIO FASE DECIFRATURA ################
		
		li	$s7, 1			# VARIABILE DI STATO : settata per la DECIFRATURA
		
		la	$a0, msgCifrato
		jal	readMessage
							
		jal	decrifratura			# FASE DECIFRATURA		
		
		la	$a0, msgDecifrato		# SCRITTURA-FILE: MESSAGGIOCIFRATO.TXT
		jal	writeMessage			# il messaggio decifrato si trova in bufferReader
		
		li	$v0, 16
		la	$a0, msgDecifrato
		syscall
		
		j	exit  			# Vado alla fine del programma
		
#-----------------------------------------------------------------------------------------------------------------------#
cifratura:	addi	$sp, $sp,-4		# Alloco spazio dello stack per una parola
		sw	$ra, 0($sp)		# Salvo il ritorno del chiamante del main
		
		li	$v0, 4			# Stampa del messaggio della cifratura
		la	$a0, opCifra		# "Cifratura in corso..."
		syscall 
		
		la	$a1, statusABC 		# Inizializzo l'array degli stati per gli algoritmi A-B-C
		jal	setStatusABC		# Salto alla procedura di inizializzazione
		
		la	$s6, bufferKey		# Metto l'indirizzo del buffer chiave in $s6
		jal	core  			# Vado alla parte centrale del programma

uscita:		lw	$ra, 0($sp)		# Riprendo l'indirizzo di ritorno del chiamante	
		addi	$sp, $sp, 4		# Dealloco lo spazio che lo conteneva
		jr	$ra			# Torno al chiamante che era nel main
		
#-----------------------------------------------------------------------------------------------------------------------#
decrifratura:	addi	$sp, $sp,-4		# salvo il registro $ra corrente per potere tornare 
		sw	$ra, 0($sp)		# al main a fine alla fine della procedura

		li	$v0, 4			# messaggio indicativo per indicare la procedura in corso 
		la	$a0, opDecif						
		syscall 			 
		
		la	$a1, statusABC 		#  inizializzo l'array degli stati dedicati per gli algoritmi A-B-C
		jal	setStatusABC
				
		jal core  

		lw	$ra, 0($sp)				
		addi	$sp, $sp, 4			
		jr	$ra			# reimposto il registro $ra iniziale per potere tornare al main
									
#-----------------------------------------------------------------------------------------------------------------------#

core:		addi 	$sp, $sp, -4		# Alloco spazio nello stack per una parola
		sw 	$ra, 0($sp)		# Ci salvo l'indirizzo di ritorno del chiamante

		beqz	$s7, scorriChiave	# Se il flag e' 0 siamo in cifratura e vado a scorriChiave
		li	$s3, -1			# Imposto $s3 a -1 per scorrere la chiave al contrario
		addi	$s6, $s6, -1		# Torno indietro di una posizione perche' la cifratura ha portato
						# il puntatore della chiave fuori dal buffer
		j	prossimoAlg
		
scorriChiave:	li 	$s3, 1			# Imposto $s3 a 1 per scorrere la chiave in avanti
	
prossimoAlg: 	lb 	$t0, ($s6)		# Carico l'elemento puntato della chiave
		beqz	$t0, fineCore		# Se e' zero allora sono arrivato alla fine della stringa
		blt	$t0, 65, goNext		# Controlli per evitare ogni altro simbolo presente nella chiave
	  	bgt	$t0, 69, goNext
	  	
		li	$t1, 65			# I varia algoritmi da chiamare vengono riconosciuti
		sub	$t0, $t0, $t1		# atraverso una operazione di sottrazione con 65
		move	$a0, $t0			# Salvo il risultato  della sottrazione in $a0
		
		la	$a1, supportBuffer	# Carico il buffer di support
		jal	cleanBuffer		# per pulirlo attraverso cleanBuffer
		
		jal	goToAlg			# Vado al metodo che chiama l'algoritmo scelto dalla chiave
		
goNext:		add	$s6, $s6, $s3		# aggiorna il registro di 1 per chiamare |||| S3 è l'offset||||
		j	prossimoAlg		# l'algoritmo successivo

fineCore:	lw	$ra, 0($sp)		# reimposto il registro $ra iniziale per potere tornare	
		addi	$sp, $sp, 4
		jr	$ra				
		# FINE CORE
		
# goToAlg: Procedura che calcola la posizione in cui saltare nella tabella degli algoritmi
# Parametri: $a0 <-- Sottrazione ottenuta in precedenza fra il valore ascii della chiave e 65
# 
# In questo modo verra' restituito un valore che, moltiplicato nel seguente metodo per 4, servira' a trovare
# la posizione corretta nella tabella degli algoritmi da cui verra' chiamato l'algoritmo di cifratura richiesto

goToAlg:		addi	$sp, $sp,-4		# Salvo il registro $ra corrente per potere tornare 
		sw	$ra, 0($sp)		# al main a fine alla fine della procedura
		
		li	$t2, 4			# Costante di default per il calcolo dell'indirizzo in cui saltare
		mult	$t2, $a0			# Moltiplico la costante per la sottrazione ottenuta in precedenza
		mflo	$t2			# Riprendo il risultato dal regristro dedicato alla moltiplicazione																							

		lw	$a0, algorithmJAT($t2)	# Carico l'indirizzo contenuto nella JAT alla posizione specificata
		jr	$a0			# Viene eseguito il salto all'algoritmo richiesto

ritorno_scelta:	lw	$ra, 0($sp)		# Carico l'indirizzo di ritorno
		addi	$sp, $sp, 4		# Dealloco spazio nello stack
		jr	$ra			# Torno a CORE
		
#-----------------------------------------------------------------------------------------------------------------------#

# cleanBuffer: Procedura dedicata alla pulizia del contenuto di qualsiasi buffer in ingresso 
# Parametri : 		$a1 <-- buffer da pulire
cleanBuffer:	lb	$t0, ($a1)		# Carico in $t0 l'elemento puntato
		beqz	$t0, endClean		# Se e' zero sono arrivato alla fine della stringa
		move	$t0, $zero		# Altrimento svuoto la variabile
		sb	$t0, 0($a1)		# Per caricarla nella stringa, cancellando il precedente elemento
		addi	$a1, $a1, 1		# Vado al prossimo elemento
		
		j	cleanBuffer		# Ripeto
		
endClean:	jr	$ra

# PROCEDURA GENERICA CHE SVOLGERA IL CIFRATURA E LA DECIFRATURA DEGLI ALGORITMI A - B - C 
# IL SUO COMPORTAMENTO E' DEFINITO DA PROCEDURE DEDICATE CHE SETTANO DEI FLAG AD OGNI CHIAMATA
# PARAMETRI:		$s0 <--  offset di inizio di scorrimento del buffer
#			$s1 <--  flag distinzione tra operazione di CRIFRATURA e DECIFRATURA
#			$s2 <--	 offset dedicato al passo di scorrimento del buffer
#
# VALORE DI RITORNO:	VOID

shifter:		addi	$sp, $sp,-8			# salvo il registro $ra corrente per potere tornare 
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
			# CI POSSIAMO METTERE S7!!!!!!!!!!!!!!!!!!!!!! 
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
							# Ciclo di inversione:				
reversal:	beq	$t0, $s0, swapVet		# Se il numero dei caratteri inseriti è pari alla lunghezza del buffer
							# allora posso uscire dalla procedura	
		lbu	$t1, ($a2)
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
itemToPlace:	la	$a2, supportBuffer	# Imposto l'indirizzo iniziale del buffer di supporto in $a2
		lbu	$t0, ($a1)		# Carico il primo elemento della frase in $t0 (che sara' l'elemento
						# che dovr? essere inserito per formare la frase originaria)
		addi	$a1, $a1, 2		# Scorro avanti di 2 dato che dopo questo elemento ci sara'sicuramente '-'
		move	$t1, $zero		# Inizializzo la variabile che formera' la posizione
	
						# Ciclo che trova la posizione in cui piazzare l'elemento
findPos:	lbu	$t2, ($a1)			# Carico l'elemento puntato in $t2
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

#-----------------------------------------------------------------------------------------------------------------------#
				

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
algorithmTable: la 	$t7, algorithmJAT	# Salvo l'indirizzo della JAT in $t7
		la	$t6, algoritmo_A		# In $t6 metto l'indirizzo all'algoritmo A
		sw	$t6, 0($t7)		# E lo salvo nella JAT	
		la	$t6, algoritmo_B		# In $t6 metto l'indirizzo all'algoritmo B
		sw	$t6, 4($t7)		# E lo salvo nella JAT
		la	$t6, algoritmo_C		# In $t6 metto l'indirizzo all'algoritmo C
		sw	$t6, 8($t7)		# E lo salvo nella JAT
		la	$t6, algoritmo_D		# In $t6 metto l'indirizzo all'algoritmo D
		sw	$t6, 12($t7)		# E lo salvo nella JAT
		la	$t6, algoritmo_E		# In $t6 metto l'indirizzo all'algoritmo E
		sw	$t6, 16($t7)		# E lo salvo nella JAT

		move	$v0, $t7			# Restituisco l'indirizzo della JAT in $v0
		jr	$ra  			# Torno nel main


# setStatusABC: Imposta l'array degli stati dedicati alle procedure A, B e C
# Offset per lettura dello stato : 0 è A , 12 è B, 24 è C
# 
setStatusABC:	addi 	$sp, $sp, -4		# Faccio spazio nello stack per una parola
		sw 	$ra, 0($sp)		# Salvo l'indirizzo di ritorno del chiamante

		jal	algAStatus		# Imposto gli stati per l'algoritmo A

		addi	$a1, $a1, 12		# Vado avanti di 3 spazi
		jal 	algBStatus		# Imposto gli stati per l'algoritmo B
	
		addi 	$a1, $a1, 12		# Vado avanti di 3 spazi
		jal 	algCStatus		# Imposto gli stati per l'algoritmo B

		lw	$ra, 0($sp)		# Carico l'indirizzo di ritorno del chiamante
		addi	$sp, $sp, 4		# Dealloco spazio dello stack
		jr 	$ra			# Torno al chiamante in Cifratura/Decifratura

# algAStatus: Procedura dedicata al settaggio dei flag dedicati all'algoritmo A 		
algAStatus:	addi 	$sp, $sp, -4		# Faccio spazio nello stack per una parola
		sw 	$ra, 0($sp)		# Salvo l'indirizzo di ritorno del chiamante

		li	$t0, 0			# Carico l'offset di partenza
		sb	$t0, 0($a1)		# E lo salvo nel buffer
		li	$t2, 1			# Carico il passo di lettura
		sb	$t2, 8($a1)		# E lo salvo nel buffer

		beqz 	$s7, stepA		# Se il flag e' 0 allora siamo in cifratura
		li	$t1, 1			# Altrimenti siamo in decifratura e imposto il flag a 1
		sb	$t1, 4($a1)		# E lo salvo nel buffer		
		j	fineStatusA		# Vado alla fine del metodo

stepA:		li	$t1, 0			# Essendo in cifratura imposto il flag a 0
		sb	$t1, 4($a1)		# E lo salvo nel buffer

fineStatusA:	lw	$ra, 0($sp)		# Carico indirizzo di ritorno del chiamante
		addi	$sp, $sp, 4		# Dealloco spazio dello stack
		jr $ra				# Torno a setStatusABC

# algBStatus: Procedura dedicata al settaggio dei flag dedicati all'algoritmo B		
algBStatus:	addi 	$sp, $sp, -4		# Faccio spazio nello stack per una parola
		sw 	$ra, 0($sp)		# Salvo l'indirizzo di ritorno del chiamante

		li	$t0, 0			# Carico l'offset di partenza
		sb	$t0, 0($a1)		# E lo salvo nel buffer
		li	$t2, 2			# Carico il passo di lettura
		sb	$t2, 8($a1)		# E lo salvo nel buffer	
			
		beqz 	$s7, stepB		# Se il flag e' 0 allora siamo in cifratura
		li	$t1, 1			# Altrimenti siamo in decifratura e imposto il flag a 1
		sb	$t1, 4($a1)		# E lo salvo nel buffer			
		j	fineStatusB		# Vado alla fine del metodo
		
stepB:		li	$t1, 0			# Essendo in cifratura imposto il flag a 0
		sb	$t1, 4($a1)		# E lo salvo nel buffer

fineStatusB:	lw	$ra, 0($sp)		# Carico indirizzo di ritorno del chiamante
		addi	$sp, $sp, 4		# Dealloco spazio dello stack	
		jr $ra				# Torno a setStatusABC

# algCStatus: Procedura dedicata al settaggio dei flag dedicati all'algoritmo C	
algCStatus:	addi 	$sp, $sp, -4		# Faccio spazio nello stack per una parola
		sw 	$ra, 0($sp)		# Salvo l'indirizzo di ritorno del chiamante

		li	$t0, 1			# Carico l'offset di partenza
		sb	$t0, 0($a1)		# E lo salvo nel buffer
		li	$t2, 2			# Carico il passo di lettura
		sb	$t2, 8($a1)		# E lo salvo nel buffer
			
		beqz 	$s7, stepC		# Se il flag e' 0 allora siamo in cifratura
		li	$t1, 1			# Altrimenti siamo in decifratura e imposto il flag a 1
		sb	$t1, 4($a1)		# E lo salvo nel buffer				
		j	fineStatusC		# Vado alla fine del metodo
		
stepC:		li	$t1, 0			# Essendo in cifratura imposto il flag a 0
		sb	$t1, 4($a1)		# E lo salvo nel buffer
		
fineStatusC:	lw	$ra, 0($sp)		# Carico indirizzo di ritorno del chiamante
		addi	$sp, $sp, 4		# Dealloco spazio dello stack
		jr $ra				# Torno a setStatusABC
		
#-----------------------------------------------------------------------------------------------------------------------#

 # chiamata ad gli algoritmi ci cifratura e decifratura
						
algoritmo_A:	addi 	$sp, $sp, -8			# chiama Shifter : settato per algoritmo A
		sw 	$s6, 0($sp)
		sw	$ra, 4($sp)

		la	$a0, statusABC 
		jal	shifter
		
		lw	$ra, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 8
		
		j	ritorno_scelta
					
algoritmo_B:	addi 	$sp, $sp, -8			# chiama Shifter : settato per algoritmo B
		sw 	$s6, 0($sp)
		sw	$ra, 4($sp)

		la	$a0, statusABC
		addi 	$a0, $a0, 12
		jal	shifter

		lw	$ra, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 8
	
		j	ritorno_scelta
			
algoritmo_C:	addi 	$sp, $sp, -8			# chiama Shifter : settato per algoritmo C
		sw 	$s6, 0($sp)
		sw	$ra, 4($sp)

		la	$a0, statusABC
		addi 	$a0, $a0, 24
		jal	shifter
				
		lw	$ra, 4($sp)
		lw	$s6, 0($sp)
		addi	$sp, $sp, 8
		j	ritorno_scelta
			
algoritmo_D:	addi 	$sp, $sp, -4			# chiama Inverter
		sw	$ra, 0($sp)
		
		la 	$a2, bufferReader
		la	$a3, supportBuffer
		jal	algD	
						
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4

		j	ritorno_scelta
		
						
algoritmo_E:	addi 	$sp, $sp, -4			# countOccurence 
		sw	$ra, 0($sp)
		
		la	$a1, bufferReader
		la	$a3, supportBuffer
		
		beq	$s7, 1, decifra_E
		jal	AlgE
		j	SO_decifra
		
decifra_E:	la	$a1, bufferReader		# buffer reader a questo punto arriva pieno con il valori giusti
		jal	decifraE
		
SO_decifra:	lw	$ra, 0($sp)
		addi	$sp, $sp, 4

		j	ritorno_scelta
			
#-----------------------------------------------------------------------------------------------------------------------#


# readMessage : Procedura dedicata alla lettura del file che deve essere CIFRATO o DECIFRATO
# parametri : 	$a0 <-- descritttore del file da leggere 
#
# valore di ritorno: 	void 
# il suo effetto è quello di riempire il file da trattare 	
readMessage:	addi 	$sp, $sp, -4		# Apro spazio nello stack per una parola
		sw	$ra, 0($sp)		# Salvo l'indirizzo di ritorno del chiamante
		
		jal	openFile			# Apre il file in solo lettura, il descrittore lo riceve dal main 		
		
		move	$a0, $v0		 	# Passo il descrittore del file 
		la	$a1, bufferReader	# Carico il buffer che conterra' il messaggio
		li	$a2, 255			# Imposto la dimensione del buffer
		jal	readFile			# Leggo il file e carico il buffer dedicato
			 		
		lw	$ra, 0($sp)		# Reimposto il registro del chiamante
		addi	$sp, $sp, 4		# Dealloco spazio dello stack
		jr $ra

# readKey: Procedura dedicata alla lettura del file che contiene la CHIAVE di cifratura(decifratura)
# PARAMETRI : 		$a0 <-- DESCRITTORE DEL FILE 
#
# Valore di ritorno: 	void 
# Il suo effetto è quello di riempire il buffer con la chiave
readKey:		addi 	$sp, $sp, -4		# Alloco spazio nel buffer per una parola
		sw   	$ra, 0($sp)		# Salvo il rigistro di ritorno del chiamante 
		jal 	openFile			# Apro il file in lettura
		
		move	$a0, $v0			# Salvo il descrittore del file per la prossima procedura
		la	$a1, bufferKey		# Carico il buffer che conterra' la chiave 
		li	$a2, 4			# Imposto la dimensione del buffer
		jal	readFile			# Vado alla procedura di lettura da file
													
		lw	$ra, 0($sp)		# Carico il registro di ritorno
		addi	$sp, $sp, 4		# Dealloco lo spazio della pila
		jr $ra				# Torno al precedente Jal
						
# OPEN-FILE: PROCEDURA CHE PERMETTE DI APRILE UN FILE IN LETTURA / SCRITTURA
# $a0: DESCRITTORE DEL FILE
#
# VALORE DI RITORNO :	$v0 <-- Indirizzo di memoria del buffer con i dati letti
openFile:	li	$v0, 13			# Chiamata a sistema per apertura file	 
		li	$a1, 0	  		# Flag di lettura
		li	$a2, 0			# (Ignorato)
		syscall	
		
		move $v1, $v0      	 	# Salvo il percorso del file in $v1
		jr $ra 
			
# readFile: Procedura per la lettura dei file
# $a0: Descrittore del file	
# $a1: Registro che contiene l'indirizzo di partenza del buffer di riferimento
# $a2: Grandezza del buffer di riferimento
# VALORE DI RITORNO:	$v0 <-- REGISTRO DEL BUFFER CON I DATI LETTI		
readFile:	li 	$v0, 14	 
		syscall				  
 				
		jr $ra  
		
# WRITE-FILE: PROCEDURA PER SCRIVERE IL CONTENUTO NEL FILE
# $a0: Descrittore del file	
# $a1: Registro che contiene l'indirizzo di partenza del buffer di riferimento
# $a2: Grandezza del buffer di riferimento
writeFile:   	li 	$v0, 15
    		syscall
    		
     		jr $ra 
#-----------------------------------------------------------------------------------------------------------------------#
exit:		lw 	$ra, 0($sp)
		lw 	$s0, 4($sp)
		lw 	$s1, 8($sp)
		lw 	$s2, 12($sp)
		addi 	$sp, $sp, 16		# Dealloco spazio dello stack per chiuderlo definitivamente
	
		li	$v0, 4			# Visualizza il messaggio di terminazione del programma	
		la	$a0, done		# "Operazione Terminata."						
		syscall				
	
			
		li $v0,10			# Chiusura del programma
		syscall
