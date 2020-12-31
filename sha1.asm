IDEAL
MODEL small
STACK 100h
DATASEG

	temp_320chunk db 140h dup(0) ;a temporary array of big 32 bit words that holds every current chunk while processing 

	h0 db 67h,45h,23h,01h ;hash values
	h1 db 0efh, 0cdh,0abh,89h ;hash values
	h2 db 98h, 0bah, 0dch, 0feh ;hash values
	h3 db 10h, 32h, 54h, 76h ;hash values
	h4 db 0c3h, 0d2h, 0e1h, 0f0h ;hash values
	
	a db 4 dup(0) ;chunk hash values
	b db 4 dup(0) ;chunk hash values
	c db 4 dup(0) ;chunk hash values
	d db 4 dup(0) ;chunk hash values
	e db 4 dup(0) ;chunk hash values
	f db 4 dup(0) ;chunk hash values
	k db 4 dup(0) ;a "key" in the main loop. changes according to index in block.
	temp db 4 dup(0) ;chunk hash values
	
	k1 db 5ah, 82h,79h, 99h  ;key of cycle 1 (saved for processing)
	k2 db 6eh,0d9h,0ebh,0a1h ;key of cycle 2 (saved for processing)
	k3 db 8fh, 1bh, 0bch, 0dch ;key of cycle 3 (saved for processing)
	k4 db 0cah, 62h, 0c1h, 0d6h ;key of cycle 4 (saved for processing)
	
	counter db 0 ;keeps track of the index of big 32 bit words of temp_320chunk
	
	address1 dw ? ;saves return address in functions
	address2 dw ? ;saves return address in functions
	address3 dw ? ;saves return address in functions
	address4 dw ? ;saves return address in functions
	address5 dw ? ;saves return address in functions
	
	tempbigword1 db 4 dup(0) ;a temporary 32 bit big word, for doing complex calculations without overwriting any saved big 32 bit words
	tempbigword2 db 4 dup(0) ;a temporary 32 bit big word, for doing complex calculations without overwriting any saved big 32 bit words
	
	line db 10,13,'$' ;a string that when printed makes a line in the user window
	ml dw ? ;a variable that holds message length (in binary)
	input_message db 'please enter string (maximum 255 characters)',10,13,'$' ;a message that gets printed when asking for input
	string_prefix db 0, 0 ;saved for: how many bytes are free for input sting. how many bytes of ascii code user actually inputed.
	string db ? ;input string goes in here

CODESEG
proc input ;a function that gets input from user and stores it in the offset given to it by stack
	pop [address4]
	pop dx
	mov bx, dx
	mov [byte ptr bx], 0ffh
	mov ah, 0ah
	int 21h
	push [address4]
	ret
endp input

proc print ;a function that prints a message by it's offset given to it by stack
	pop [address4]
	pop dx
	mov ah, 9
	int 21h
	push [address4]
	ret
endp print

proc input_and_pad ;a function that asks for input in string, and then pads it (so string will be ready for hashing). the function gets offset of string by stack
	pop [address1]
	pop si
	push offset input_message
	call print
	push si		;
	sub si, 2	;
	push si		;
	call input	;
	pop si		;
	push si						;
	mov al, [byte ptr si -1]	;
	xor ah, ah					;
	shl ax, 3					;
	mov [ml], ax				;
	shr ax, 3					;
	push ax						;
	push si						;
	call pad					;
	pop si						;
	mov ax, [ml]
	mov [byte ptr si+1], al ;padding with ml
	mov [byte ptr si], ah ;padding with ml
	pop si
	push [address1]
	ret
endp input_and_pad

proc pad ;a function that pads the offset of a sting given to it by stack and by the help of the number of characters in string given to it by stack 
	pop [address2]
	pop si ;offset string
	pop bx ;number of chars	
	add si, bx
	push bx
	call mod_64_56
	pop ax
	cmp al, 1
	je pad_ml
	mov [byte ptr si], 80h
	inc si
	push si
	push bx
	call pad_with_0
	pop si
pad_ml:
	mov cx, 6
again_pad:
	mov [byte ptr si], 0
	inc si
	loop again_pad
	push si
	push [address2]
	ret
endp pad

proc pad_with_0 ;a function that gets number of characters in input string, and offset of string by stack. Pads string with 0 accordingly.
	pop [address3]
	pop bx
	pop si
	inc bx
again_pad_with_0:
	mov [byte ptr si], 0
	inc si
	inc bx
	push bx
	call mod_64_56
	pop ax
	cmp al, 1
	jne again_pad_with_0
	push si
	push [address3]
	ret
endp pad_with_0
	
proc mod_64_56 ;a function that gets string length (number of bytes) returns 1 if length%64 == 56 else returns 0
	pop [address4]
	pop ax 
	and ax, 3fh ;like checking for reminder
	cmp ax, 38h
	je mod_64_56_true
	push 0
	jmp mod_64_56_end
mod_64_56_true:
	push 1
mod_64_56_end:
	push [address4]
	ret
endp mod_64_56

proc print_hash ;a function that gets offset of 40 bytes in the data segment and prints them to the console.
	pop [address1]
	pop si
	mov cx, 14h
again_print_hash:
	xor ah, ah
	mov al, [byte ptr si]
	push ax
	call identifier
	call print_char
	call print_char
	inc si
	loop again_print_hash
	push [address1]
	ret
endp print_hash

proc identifier ;a function that gets a 16 bit word by stack and returns through stack every digit ascii code in the right order.
	pop [address2]
	pop ax
	mov ah, al
	and ax, 0f00fh
	shr ah, 4 ;ah now holds the leftmost digit while al holds the rightmost digit of the current byte
	cmp al, 9
	ja hexa1
	add al, '0'
	jmp cont_identifier
hexa1:
	add al, 'a'
	sub al, 0ah
cont_identifier:
	cmp ah, 9
	ja hexa2
	add ah, '0'
	jmp end_identifier
hexa2:
	add ah, 'a'
	sub ah, 0ah
end_identifier:
	mov bl, ah
	push ax
	push bx
	push [address2]
	ret
endp identifier

proc print_char ;a function that prints a single character to the console.
	pop [address2]
	pop dx
	mov ah, 2
	int 21h
	push [address2]
	ret
endp print_char

proc hash ;a function that hashes string and stores hash values in h0 through h4 in the data segment.
	pop [address1]
	mov si, offset string
	mov cx, [ml]
	add cx, 40h ;ml is the message lenth before padding
	shr cx, 9
	inc cl
	xor ch, ch
again_hash:
	push cx
	push si
	
	push si
	call chunk_hash
	
	pop si
	add si, 40h
	pop cx
	loop again_hash
	push [address1]
	ret
endp hash

proc chunk_hash ;a function that gets (by stack) offset of a chunk hashes it (chunks are 64 32 bit big words long) and adds the hash values to the current hash values pre chunk hash (h0 through h4)
	pop [address2]
	pop si
	mov di, offset temp_320chunk
	push di
	
	push di
	push si
	call copy_chunk
	
	pop di
	push di
	
	push di
	call extend_chunk
	
	pop di
	push di
	
	call initialize
	
	pop di
	push di
	
	push di
	call main_loop
	
	pop di
	call add_hash_result
	
	push [address2]
	ret
endp chunk_hash

proc copy_chunk ;a function that gets by stack offset of chunk1 and offset of chunk2. copies content of chunk1 to chunk2.
	pop [address3]
	pop si ;from
	pop di ;to
	mov cx, 10h
again_chunk_hash1:
	push cx	
	push si
	push di
	
	push di
	push si
	call mov_bw
	
	pop di
	pop si
	add si, 4
	add di, 4
	pop cx
	loop again_chunk_hash1
	push [address3]
	ret
endp copy_chunk

proc extend_chunk ;a function that gets (by stack) offset of a chunk and extends it by bitwise operations.
	pop [address3]
	pop di
	add di, 40h
	mov cx, 40h
again_extend_chunk:
	push cx
	push di
	
	push offset tempbigword1
	sub di, 0ch
	push di
	call mov_bw
	
	pop di
	push di
	
	push offset tempbigword1
	sub di, 20h
	push di
	call xor_bw 
	
	pop di
	push di
	
	push offset tempbigword1
	sub di,38h
	push di
	call xor_bw
	
	pop di
	push di
	
	push offset tempbigword1
	sub di, 40h
	push di
	call xor_bw
	
	pop di
	push di
	
	push di
	push offset tempbigword1
	call mov_bw
	
	pop di
	push di
	
	push di
	push 1
	call rol_bw
	
	pop di
	add di,4
	pop cx
	loop again_extend_chunk
	push [address3]
	ret
endp extend_chunk

proc initialize ;a function that initializes hash values for current chunk, (must happen before processing chunk hash)
	pop [address3]
	push offset a
	push offset h0
	call mov_bw
	push offset b
	push offset h1
	call mov_bw
	push offset c
	push offset h2
	call mov_bw
	push offset d
	push offset h3
	call mov_bw
	push offset e
	push offset h4
	call mov_bw
	push [address3]
	ret
endp initialize

proc main_loop ;the main loop, makes most of the hashing to the hash values a through e. gets offset of 320 bit chunk by stack.
	pop [address3]
	pop di
	mov [counter], 0
	mov cx, 50h
again_main_loop:
	push cx
	push di
	
	cmp [counter], 13h
	jbe case1
	cmp [counter], 27h
	jbe case2
	cmp [counter], 3bh
	jbe case3
case4:
	call func4
	jmp cont_main_loop
case3:
	call func3
	jmp cont_main_loop
case2:
	call func2
	jmp cont_main_loop
case1:
	call func1
cont_main_loop:
	
	pop di
	push di
	
	push di
	call end_main_loop
	
	inc [counter]
	pop di
	add di, 4
	pop cx
	loop again_main_loop
	push [address3]
	ret
endp main_loop

proc end_main_loop ;a function that makes all the bitwise operations of the end of the main loop (so the main loop wont be 500 lines long).
	pop [address5]
	push offset tempbigword1
	push offset a
	call mov_bw
	push offset tempbigword1
	push 5
	call rol_bw
	push offset tempbigword1
	push offset f
	call add_bw
	push offset tempbigword1
	push offset e
	call add_bw
	push offset tempbigword1
	push offset k
	call add_bw
	pop di
	push offset tempbigword1
	push di
	call add_bw
	push offset temp
	push offset tempbigword1
	call mov_bw
	push offset e
	push offset d
	call mov_bw
	push offset d
	push offset c
	call mov_bw
	push offset c
	push offset b
	call mov_bw
	push offset c
	push 1eh
	call rol_bw
	push offset b
	push offset a
	call mov_bw
	push offset a
	push offset temp
	call mov_bw
	push [address5]
	ret
endp end_main_loop

proc add_hash_result ;a function that gets called after program already hashed a chunk. adds chunk hash results to total hash results.
	pop [address3]
	push offset h0
	push offset a
	call add_bw
	push offset h1
	push offset b
	call add_bw
	push offset h2
	push offset c
	call add_bw
	push offset h3
	push offset d
	call add_bw
	push offset h4
	push offset e
	call add_bw
	push [address3]
	ret
endp add_hash_result

proc func1 ;a function that makes all the bitwise operations of the first function of the main loop (if index is between 19 and 0 inclusive).
	pop [address5]
	push offset tempbigword1
	push offset b
	call mov_bw
	push offset tempbigword1
	push offset c
	call and_bw
	push offset tempbigword2
	push offset b
	call mov_bw
	push offset tempbigword2
	call not_bw
	push offset tempbigword2
	push offset d
	call and_bw
	push offset tempbigword1
	push offset tempbigword2
	call or_bw
	push offset f
	push offset tempbigword1
	call mov_bw
	push offset k
	push offset k1
	call mov_bw
	push [address5]
	ret
endp func1

proc func2 ;a function that makes all the bitwise operations of the second function of the main loop (if index is between 20 and 39 inclusive).
	pop [address5]
	push offset tempbigword1
	push offset b
	call mov_bw
	push offset tempbigword1
	push offset c
	call xor_bw
	push offset tempbigword1
	push offset d
	call xor_bw
	push offset f
	push offset tempbigword1
	call mov_bw
	push offset k
	push offset k2
	call mov_bw
	push [address5]
	ret
endp func2

proc func3 ;a function that makes all the bitwise operations of the third function of the main loop (if index is between 40 and 59 inclusive).
	pop [address5]
	push offset tempbigword1
	push offset b
	call mov_bw
	push offset tempbigword1
	push offset c
	call and_bw
	push offset tempbigword2
	push offset b
	call mov_bw
	push offset tempbigword2
	push offset d
	call and_bw
	push offset tempbigword1
	push offset tempbigword2
	call or_bw
	push offset tempbigword2
	push offset c
	call mov_bw
	push offset tempbigword2
	push offset d
	call and_bw
	push offset tempbigword1
	push offset tempbigword2
	call or_bw
	push offset f
	push offset tempbigword1
	call mov_bw
	push offset k
	push offset k3
	call mov_bw
	push [address5]
	ret
endp func3

proc func4 ;a function that makes all the bitwise operations of the fourth function of the main loop (if index is between 60 and 79 inclusive).
	pop [address5]
	push offset tempbigword1
	push offset b
	call mov_bw
	push offset tempbigword1
	push offset c
	call xor_bw
	push offset tempbigword1
	push offset d
	call xor_bw
	push offset f
	push offset tempbigword1
	call mov_bw
	push offset k
	push offset k4
	call mov_bw
	push [address5]
	ret
endp func4

proc mov_bw ;mov, but gets 2 offsets from stack of 2 big 32 bit words and moves between them.
	pop [address4]
	pop di ;from
	pop si ;to
	mov cx, 2
again_mov_bw:
	mov ax, [word ptr di]
	mov [word ptr si], ax
	add si, 2
	add di, 2
	loop again_mov_bw
	push [address4]
	ret
endp mov_bw

proc xor_bw ;xor, but gets 2 offsets from stack of 2 big 32 bit words and xores between them.
	pop [address4]
	pop si ;second operand
	pop di ;first operand
	mov cx, 2
again_xor_bw:
	mov ax, [word ptr si]
	xor [word ptr di], ax
	add si, 2
	add di, 2
	loop again_xor_bw
	push [address4]
	ret
endp xor_bw


proc rol_bw ;rol, but gets an offset of 32 bit big word from stack and number of rols from stack and rols accordingly.
	pop [address4]
	pop cx ;number of times of rol
	pop si ;number 
again_rol_bw1:
	xor ax, ax ;al holds the last carry and ah holds the current carry
	shl [byte ptr si], 1
	adc al, 0
	add si, 3
	push cx
	mov cx, 3
again_rol_bw2:
	shl [byte ptr si], 1
	adc ah, 0
	add [byte ptr si], al
	mov al, ah
	xor ah, ah
	dec si
	loop again_rol_bw2
	add [byte ptr si], al
	pop cx
	loop again_rol_bw1
	push [address4]
	ret
endp rol_bw

proc add_bw ;add, but gets 2 offsets from stack of 2 big 32 bit words and adds between them.
	pop [address4]
	pop si ;offset of second number
	pop di ;offset of first number
	add si, 3
	add di, 3
	xor ah, ah ;carry
	mov cx, 4
again_add_bw:
	mov al, ah
	xor ah, ah
	add al, [byte ptr si]
	add [byte ptr di], al
	adc ah, 0
	dec si
	dec di
	loop again_add_bw
	push [address4]
	ret
endp add_bw

proc and_bw ;and, but gets 2 offsets from stack of 2 big 32 bit words and "ands" between them.
	pop [address4]
	pop si ;second operand
	pop di ;first operand
	mov cx, 2
again_and_bw:
	mov ax, [word ptr si]
	and [word ptr di], ax
	add si, 2
	add di, 2
	loop again_and_bw
	push [address4]
	ret
endp and_bw

proc not_bw ;not, but gets an offsets from stack of big 32 bit word and "nots" it.
	pop [address4]
	pop si ;operand
	not [word ptr si]
	not [word ptr si +2]
	push [address4]
	ret
endp not_bw

proc or_bw ;or, but gets 2 offsets from stack of 2 big 32 bit words and ores between them.
	pop [address4]
	pop si ;second operand
	pop di ;first operand
	mov cx, 2
again_or_bw:
	mov ax, [word ptr si]
	or [word ptr di], ax
	add si, 2
	add di, 2
	loop again_or_bw
	push [address4]
	ret
endp or_bw

start:
	mov ax, @data
	mov ds, ax
	push offset string
	call input_and_pad
	push offset string
	call hash
	push offset line
	call print
	push offset h0
	call print_hash
exit:
	mov ax, 4c00h
	int 21h
END start
