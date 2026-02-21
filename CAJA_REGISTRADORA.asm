.data
buffer: 			    .space 20 	    # Buffer para teclado

# Punteros de lista
head_compra:  		    .word 0  	    # Puntero a cabeza
tail_compra: 		    .word 0   	    # Puntero a cola

# Mensajes para imprimir
prompt:         		.asciiz "> "
newline:       		    .asciiz "\n"
error_msg:        	    .asciiz "Error: Producto no encontrado\n"
error_anular_msg:	    .asciiz "Error: No se pueden anular mas productos (Lista vacia)\n"
error_file_msg:		    .asciiz "Error: No se pudo crear el archivo (Verifique permisos)\n"
archivo_name_msg:	    .asciiz "\nArchivo generado exitosamente:      "

# Mensajes modificados para estetica
total_msg:      		.asciiz "Total Compra:"
dot:            		.asciiz "."
mult_msg:       		.asciiz " [Cant: "
eq_dollar:      		.asciiz "] = $"
eq_neg_dollar:     	    .asciiz "] = -$"
void_msg:       		.asciiz "ANULADO: "
dollar_msg:		        .asciiz "$"

# Mensajes de cierre
cierre_dia_msg:        	.asciiz "-------------------- CIERRE DEL DIA --------------------\n"
stock_msg:      		.asciiz "] -- Stock: "
total_cierre_msg:  	    .asciiz "Total Cierre de Caja:"
precio_msg:     		.asciiz " | Precio: $"
archivo_inventario:	    .asciiz "inventario_final.txt"
espacio: 		        .asciiz " "

# Corregido para evitar error de impresion (faltaba la z)
inv_stock_msg:    	    .asciiz "-- Stock: " 
line:			        .asciiz "--------------------------------------------------------\n"

# Importamos el inventario
.align 5
.include "inventario.asm"

# Tabla iterable de inventario
.align 5
inventory_table:
    .word P001, P002, P003, P004, P005
    .word 0
    
# Libro de contabilidad
ventas_dia:
    .word 0, 0, 0, 0, 0    

.text
.globl main

# BUCLE PRINCIPAL Y DISPATCHER
main:
    # Imprimir ">"
    li   $v0, 4
    la   $a0, prompt
    syscall
    
    # Leer entrada del usuario (max 20 chars)
    li   $v0, 8
    la   $a0, buffer
    li   $a1, 20
    syscall
    
    # Cargar el primer caracter para decidir
    lb   $t0, buffer
    
    # Manejo de errores (Input vacio)
    beq  $t0, 10, main
    
    # Comparadores de entrada
    beq  $t0, 42, maneja_multiplicacion	# Si es '*' (ASCII 42)
    beq  $t0, 45, maneja_anulacion	    # Si es '-' (ASCII 45)
    beq  $t0, 43, manejo_total     	    # Si es '+' (ASCII 43)
    beq  $t0, 47, maneja_cierre_dia	    # Si es '/' (ASCII 47)
    
    # Caso base
    j procesar_producto
    
# LOGICA DE PROCESAMIENTO DE PRODUCTO (Busqueda e Insercion)
procesar_producto:
    # Llamada a atoi
    la   $a0, buffer
    
    # Salta y guarda retorno
    jal atoi 				            # El CPU salta a 'aoti'
    
    move $s1, $v0			            # Resultado de atoi
    
    # Si input es 0 o basura, ignorar
    beq  $s1, $zero, main

    # Llamada al buscador
    la   $t0, P001
   
bucle_busqueda:
    # Carga el UPC del producto apuntado
    lw   $t1, 0($t0)
    
    # Verificacion de final de inventario
    beq  $t1, $zero, no_encontrado
    
    # Verificiacion de producto deseado
    beq  $s1, $t1, encontrado
    
    addi $t0, $t0, 32 			        # Aumenta el puntero
    
    # Si no es el producto deseado avanzamos al siguiente
    j bucle_busqueda
    
# --- Resultados de la busqueda ---
no_encontrado:
    # Imprimir el mensaje de error (definido en .data)
    li   $v0, 4
    la   $a0, error_msg
    syscall
    
    j main
    
encontrado:
    move $s2, $t0
    
    # Crear el nodo de 16 bytes
    li   $v0, 9
    li   $a0, 16
    syscall
    
    move $s3, $v0
    
    # Guarda el puntero al producto (de $s2) en el offset 0
    sw   $s2, 0($s3)
    
    # Guarda la cantidad por defecto (1) en el offset 4
    li   $t0, 1
    sw   $t0, 4($s3)
    
    # Carga el puntero 'head' para revisarlo
    lw   $t1, head_compra
    beq  $t1, $zero, caso_vacia 		# Si es lista vacia
    
    # Caso 1. Lista no vacia
    lw   $t2, tail_compra     		    # Cargamos el ultimo elemento listado
    sw   $s3, 8($t2)          		    # El viejo apunta al nuevo
    sw   $t2, 12($s3)         		    # El nuevo apunta al viejo
    sw   $zero, 8($s3)        		    # El nuevo termina en NULL
    sw   $s3, tail_compra     		    # Actualizamos el tail
    
    j imprimir_ticket_linea

caso_vacia:
    # Caso 2. Lista vacia
    sw   $s3, head_compra    		    # Head apunta al nuevo
    sw   $s3, tail_compra     		    # Tail apunta al nuevo
    sw   $zero, 8($s3)        		    # Siguiente es NULL
    sw   $zero, 12($s3)       		    # Anterior es NULL
    
    j imprimir_ticket_linea

imprimir_ticket_linea: 
    # Imprime el nombre del producto
    addi $a0, $s2, 16
    jal  strlen
    move $s6, $v0
    
    lw   $a0, 8($s2)
    jal  intlen
    add  $s6, $s6, $v0
    addi $s6, $s6, 2
    addi $s6, $s6, 3     
    
    li   $t0, 56 
    sub  $s7, $t0, $s6    

    addi $a0, $s2, 16
    li   $v0, 4
    syscall
    
    # Relleno de espacios
    move $a0, $s7
    jal  print_padding
    
    # Imprime " $"
    li   $a0, 36
    li   $v0, 11
    syscall
    li   $a0, 32
    syscall
    
    # Imprime dolares (Parte entera)
    lw   $a0, 8($s2)
    li   $v0, 1
    syscall
    
    # Imprime el punto "."
    li   $a0, 46
    li   $v0, 11
    syscall
    
    # Imprime centavos (Parte decimal)
    lw   $a0, 12($s2)
    bge  $a0, 10, print_cents_normal
    move $t8, $a0         
    li   $a0, 48          
    li   $v0, 11
    syscall
    move $a0, $t8 
            
print_cents_normal:
    li   $v0, 1
    syscall
    
    # Imprime salto de linea (\n)
    li   $v0, 4
    la   $a0, newline
    syscall

    j main				                # Salto al inicio
    
# MANEJADORES DE COMANDOS (+, -, *, /)
# --- Manejador de Multiplicacion (*) ---
maneja_multiplicacion:
    # Convertir 'n'
    la   $a0, buffer
    
    # Toma el entero luego del asterisco
    addi $a0, $a0, 1
    jal atoi
    move $t1, $v0
      
    # Si input <= 0 (ej "*"), volver a main
    blez $t1, main
    
    # Encuentra el ultimo nodo
    lw   $t2, tail_compra
   
    # Chequea de seguridad
    beq  $t2, $zero, main
   
    # Actualiza la cantidad
    sw   $t1, 4($t2)
    lw   $t3, 0($t2)

    # Direccion del producto
    lw   $t4, 8($t3)
    lw   $t5, 12($t3)
   
    # Calculamos: TotalCentavos = (Dolares * 100) + Centavos
    mul  $t4, $t4, 100
    add  $t5, $t4, $t5
   
    # Calcular el nuevo precio total
    mul  $t5, $t5, $t1
   
    # Convierte a dolares y centavos
    # Cargamos 100 en un registro para dividir
    li   $t6, 100
  
    # Divide $t5 / $t6
    div  $t5, $t6
    mflo $t7
    mfhi $t8
  
    # Imprime nombre
    addi $a0, $t3, 16
    li   $v0, 4
    syscall
  
    # Imprime " [Cant: "
    la   $a0, mult_msg
    syscall
  
    # Imprime la cantidad 'n'
    move $a0, $t1
    li   $v0, 1
    syscall
  
    # Imprime "] = $"
    la   $a0, eq_dollar
    li   $v0, 4
    syscall
  
    # Imprime los nuevos dolares
    move $a0, $t7
    li   $v0, 1
    syscall
  
    # Imprime el "."
    la   $a0, dot
    li   $v0, 4
    syscall
  
    # Imprimir los nuevos centavos
    move $a0, $t8
    li   $v0, 1
    syscall
    
    # Salto de linea
    la   $a0, newline
    li   $v0, 4
    syscall
  
    j main				                # Salto al inicio
  
# --- Manejador de Anulacion (-) ---
maneja_anulacion:
    # Convierte 'n'
    la   $a0, buffer
    addi $a0, $a0, 1
    
    jal atoi
    
    move $s4, $v0
    # Si n=0, no hacer nada
    blez $s4, main
    
bucle_borrado:
    # Condicion de salida (n=0)
    beq  $s4, $zero, main
    
    # Chequeo de seguridad (lista vacia)
    lw   $t0, tail_compra
    beq  $t0, $zero, fin_del_borrado_error
    
    # Imprime el item anulado
    li   $v0, 4
    la   $a0, void_msg
    syscall
    
    # Sacar el puntero al producto 
    lw   $t1, 0($t0)
    lw   $t2, 4($t0)
    
    # Imprime nombre
    addi $a0, $t1, 16
    li   $v0, 4
    syscall
    
    # Imprime " [Cant: "
    la   $a0, mult_msg
    li   $v0, 4
    syscall
    
    move $a0, $t2
    li   $v0, 1
    syscall
    
    # Calcula e imprime precio
    li   $t6, 100
    lw   $t3, 8($t1)  
    lw   $t4, 12($t1)    
    mul  $t3, $t3, $t6  
    add  $t4, $t3, $t4   
    mul  $t4, $t4, $t2   
    
    div  $t4, $t6
    mflo $t7
    mfhi $t8

    # Imprime "] = -$"
    la   $a0, eq_neg_dollar 
    li   $v0, 4
    syscall
    
    move $a0, $t7
    li   $v0, 1
    syscall
    
    la   $a0, dot
    li   $v0, 4
    syscall
    
    move $a0, $t8
    li   $v0, 1
    syscall
    
    la   $a0, newline
    li   $v0, 4
    syscall
    lw   $t5, 12($t0)     		        # Cargar puntero anterior
    
    beq  $t5, $zero, borrar_ultimo_nodo # Si anterior es NULL
    
    # Caso normal
    sw   $zero, 8($t5)    		        # Siguiente del anterior = NULL
    sw   $t5, tail_compra 		        # Tail = Anterior
    
    addi $s4, $s4, -1    			    # Restar 1 al contador
    j bucle_borrado
       
borrar_ultimo_nodo:
    # Lista queda vacia
    sw   $zero, head_compra
    sw   $zero, tail_compra
    addi $s4, $s4, -1
    
    j bucle_borrado
    
fin_del_borrado_error:
    li   $v0, 4
    la   $a0, error_anular_msg
    syscall
    
    j main
    
# --- Manejador de Total de Compra (+) ---
manejo_total:
    li   $s5, 0               		    # Total acumulado en centavos
    lw   $t0, head_compra
    li   $t6, 100
    la   $s6, inventory_table 		    # Puntero a la tabla de productos
    la   $s7, ventas_dia      		    # Puntero al libro de ventas
    
bucle_total:
    # Condicion de salida (fin de la lista)
    beq  $t0, $zero, fin_total
    
    lw   $t1, 0($t0)
    lw   $t2, 4($t0)
    
    # Convierte precio unitario a centavos
    lw   $t3, 8($t1)
    lw   $t4, 12($t1)
    mul  $t3, $t3, $t6
    add  $t4, $t3, $t4
    
    mul  $t4, $t4, $t2    		        # Calcular subtotal de linea
    add  $s5, $s5, $t4     		        # Acumular el gran total
    li   $t5, 0 				        # Anotar en el libro de contabilidad
    
bucle_buscar_indice:
    # Verificacion de producto deseado
    lw   $t3, 0($s6)
    beq  $t3, $t1, indice_encontrado
    
    # Si no, avanzar al siguiente indice
    addi $t5, $t5, 1
    addi $s6, $s6, 4
    
    j bucle_buscar_indice
    
indice_encontrado:
    # Mueve el puntero del libro de ventas al lugar correcto
    mul  $t3, $t5, 4
    add  $t3, $t3, $s7
    
    lw   $t4, 0($t3)
    add  $t4, $t4, $t2
    sw   $t4, 0($t3)
    
    # Resstea el puntero de la tabla para la proxima iteracion
    la   $s6, inventory_table
    
    lw   $t0, 8($t0)    			    # Avanza al siguiente nodo
    
    j bucle_total
    
fin_total:
    # Calculo de total
    div  $s5, $t6
    mflo $t7
    mfhi $t8

    li   $s6, 13
    move $a0, $t7
    
    jal  intlen
    
    add  $s6, $s6, $v0
    move $a0, $t8
    
    jal  intlen
    
    add  $s6, $s6, $v0
    addi $s6, $s6, 3
    
    li   $t0, 56
    sub  $s7, $t0, $s6
    
    # Imprime "Total compra:"
    li   $v0, 4
    la   $a0, total_msg   
    syscall
    
    move $a0, $s7
    jal  print_padding
    
    li   $a0, 36
    li   $v0, 11
    syscall
    
    li   $a0, 32
    syscall
    
    # Imprime dolares totales
    move $a0, $t7
    li   $v0, 1
    syscall
    
    # Imprime "."
    li   $a0, 46     
    li   $v0, 11
    syscall
    
    # Imprime centavos totales
    move $a0, $t8
    bge  $a0, 10, print_total_cents
    move $t9, $a0
    li   $a0, 48
    li   $v0, 11
    syscall
    
    move $a0, $t9

print_total_cents:
    li   $v0, 1
    syscall
    
    # Imprime salto de linea
    li   $v0, 4
    la   $a0, newline
    syscall

    # Libera memoria (borra la lista)
    sw   $zero, head_compra
    sw   $zero, tail_compra

    j main				                # Salto al inicio

# --- Manejador de Cierre del Dia (/) ---
maneja_cierre_dia:
    # Imprime cabecera
    li   $v0, 4
    la   $a0, cierre_dia_msg
    syscall
    
    ##
    
    li   $s5, 0               
    la   $s6, inventory_table 
    la   $s7, ventas_dia      
    li   $t6, 100             
    
bucle_cierre:
    # Condicion de salida
    lw   $t0, 0($s6)
    beq  $t0, $zero, fin_cierre
    
    # Carga datos
    lw   $t1, 0($s7)

    # Imprime el nombre del producto (Alineado a la izquierda)
    addi $a0, $t0, 16
    li   $v0, 4
    syscall
    
    # Calcular padding hasta la columna 19
    li   $t9, 19
    addi $a0, $t0, 16
    jal  strlen
    sub  $a0, $t9, $v0
    
    li $t4, 100
    blt $t1, $t4, no_ajuste_pad
    
    addi $a0, $a0, -1
    
no_ajuste_pad:
    bltz $a0, padding_min_cero
    jal print_padding
    j fin_ajuste_pad
    
padding_min_cero:
    li $a0, 0
    jal print_padding

fin_ajuste_pad:
    # Imprime " [Cant: "
    li   $v0, 4            
    la   $a0, mult_msg
    syscall
    
    # Imprime cantidad vendida
    move $a0, $t1
    li   $v0, 1
    syscall

    li   $a0, 93        			    # ASCII ']'
    li   $v0, 11
    syscall
    
    # Calcular padding hasta columna 30 
    move $s3, $zero 
    li   $t9, 30
    li   $s3, 27        			    # 19 (inicio) + 8 (txt)
    
    move $a0, $t1
    jal  intlen
    add  $s3, $s3, $v0  			    # Sumar longitud numero
    addi $s3, $s3, 1    			    # Sumar longitud del corchete ']'
    
    sub  $a0, $t9, $s3
    jal  print_padding
    
    # Imprime "] -- Stock: "
    li   $v0, 4            
    la   $a0, inv_stock_msg   
    syscall
    
    # Calcula y actualiza stock
    lw   $t2, 4($t0)
    sub  $t2, $t2, $t1
    sw   $t2, 4($t0)
    
    # Imprime stock restante
    move $a0, $t2
    li   $v0, 1
    syscall
    
    li   $v0, 15
    move $a0, $s0
    addi $a1, $t0, 16
    move $t9, $a1
    move $a0, $t9
    
    jal  strlen
    move $a2, $v0
    li   $v0, 15
    syscall
    
    li $v0, 15
    move $a0, $s0
    la $a1, inv_stock_msg
    
    li $a2, 10
    syscall
    
    move $a0, $t2
    jal int_to_ascii
    
    li $v0, 15
    move $a0, $s0
    la $a1, buffer
    move $a2, $v0
    syscall
    
    li $v0, 15
    move $a0, $s0
    la $a1, newline
    li $a2, 1
    syscall
    
    # PRECIO (Alineado a la derecha en col 56)
    # Calcula y suma subtotal
    lw   $t3, 8($t0)
    lw   $t4, 12($t0)
    
    move $a0, $t3
    jal  intlen
    move $s4, $v0
    
    addi $s4, $s4, 2
    addi $s4, $s4, 3  			        # " $ ."
    
    li   $s3, 40 
    move $a0, $t2
    
    jal  intlen
    
    add  $s3, $s3, $v0
    li   $t9, 56
    sub  $t9, $t9, $s3
    sub  $a0, $t9, $s4
    
    jal  print_padding
    
    # Imprime precio " $X.Y"
    li   $a0, 36
    li   $v0, 11
    syscall
    
    li   $a0, 32
    syscall
    
    move $a0, $t3
    li   $v0, 1
    syscall
    
    li   $a0, 46
    li   $v0, 11
    syscall
    
    move $a0, $t4
    bge  $a0, 10, p_ccents
    move $t8, $a0
    li   $a0, 48
    li   $v0, 11
    syscall
    
    move $a0, $t8
    
p_ccents:
    li   $v0, 1
    syscall
    
    li   $v0, 4
    la   $a0, newline
    syscall
    
    # Calcula y acumula al gran total
    mul  $t3, $t3, $t6
    add  $t4, $t3, $t4
    mul  $t4, $t4, $t1
    add  $s5, $s5, $t4
    
    # Siguiente item
    addi $s6, $s6, 4
    addi $s7, $s7, 4
    
    j bucle_cierre

fin_cierre:
    li   $v0, 4
    la   $a0, line
    syscall

    # Imprime "Total cierre de caja: $" (Alineado)
    # Calcula dolares y centavos del total
    div  $s5, $t6
    mflo $t7
    mfhi $t8
    
    li   $s3, 21
    move $a0, $t7
    jal  intlen
    
    add  $s3, $s3, $v0
    move $a0, $t8
    jal  intlen
    
    add  $s3, $s3, $v0
    addi $s3, $s3, 3
    
    li   $t9, 56
    sub  $a0, $t9, $s3
    move $s4, $a0
    
    li   $v0, 4
    la   $a0, total_cierre_msg
    syscall
    
    move $a0, $s4
    jal  print_padding
    
    li   $a0, 36
    li   $v0, 11
    syscall
    
    li   $a0, 32
    syscall
    
    move $a0, $t7
    li   $v0, 1
    syscall
    
    li   $a0, 46
    li   $v0, 11
    syscall
    
    move $a0, $t8
    bge  $a0, 10, p_fcents
    move $t9, $a0
    li   $a0, 48
    li   $v0, 11
    syscall
    
    move $a0, $t9
    
p_fcents:
    li   $v0, 1
    syscall
    li   $v0, 4
    la   $a0, newline
    syscall
    
    # Reincio de conteo para proximo dia
    la   $s7, ventas_dia
    la   $s6, inventory_table
    
bucle_reinicio:
    lw   $t0, 0($s6)
    beq  $t0, $zero, fin_reinicio
    sw   $zero, 0($s7)     
    addi $s6, $s6, 4
    addi $s7, $s7, 4
    j bucle_reinicio

error_abrir_archivo:
    li   $v0, 4
    la   $a0, error_file_msg
    syscall
    
    j fin_reinicio
    
fin_reinicio:
    jal guardar_inventario_final
    
    # Imprime mensaje y nombre del archivo de inventario final
    li   $v0, 4
    la   $a0, archivo_name_msg
    syscall
    li   $v0, 4
    la   $a0, archivo_inventario
    syscall
    
    # Termina el programa
    li   $v0, 10
    syscall

# BIBLIOTECA DE UTILIDADES
# --- ATOI (ASCII a entero) ---
atoi:
    li   $v0, 0              		    # Inicializamos el total en 0

atoi_loop:
    lb   $t0, 0($a0)          		    # Lee el caracter actual

    blt  $t0, 48, atoi_end   		    # Si es menor que '0', terminar.
    bgt  $t0, 57, atoi_end   		    # Si es mayor que '9', terminar.

    sub  $t0, $t0, 48
    mul  $v0, $v0, 10
    add  $v0, $v0, $t0
    
    # Avanza al siguiente caracter
    addi $a0, $a0, 1
    
    j atoi_loop 

atoi_end:
    jr   $ra

# --- STRLEN (Longitud de string) ---   
strlen:
    addi $sp, $sp, -8
    sw   $t1, 0($sp)
    sw   $t2, 4($sp)

    li   $v0, 0
    
strlen_loop:
    add  $t1, $a0, $v0
    lb   $t2, 0($t1)
    beqz $t2, strlen_end
    addi $v0, $v0, 1
    j    strlen_loop
    
strlen_end:
    lw   $t2, 4($sp)
    lw   $t1, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

# --- INTLEN (Digitos de un entero) ---
intlen:
    addi $sp, $sp, -8
    sw   $t1, 0($sp)
    sw   $t2, 4($sp)

    li   $v0, 0
    move $t1, $a0
    
    # Caso especial: si es 0, longitud es 1
    bnez $t1, intlen_check
    li   $v0, 1
    j    intlen_restore

intlen_check:
    # Si es negativo
    bge  $t1, 0, intlen_loop
    neg  $t1, $t1
    addi $v0, $v0, 1       	 	        # Sumar 1 por el signo '-'

intlen_loop:
    beqz $t1, intlen_restore
    div  $t1, $t1, 10
    addi $v0, $v0, 1
    j    intlen_loop

intlen_restore:
    lw   $t2, 4($sp)
    lw   $t1, 0($sp)
    addi $sp, $sp, 8
    jr   $ra

# --- INT_TO_ASCII (convierte entero positivo a string) ---
int_to_ascii:
    addi $sp, $sp, -16
    sw   $t0, 0($sp)
    sw   $t1, 4($sp)
    sw   $t2, 8($sp)
    sw   $t3, 12($sp)

    move $t0, $a0
    la   $t1, buffer
    move $v0, $zero     			    # Contador de digitos

    # Si el numero es 0
    bnez $t0, itoa_loop
    li   $t2, 48        			    # '0'
    sb   $t2, 0($t1)
    li   $v0, 1
    j    itoa_end

itoa_loop:
    # Calcula el ultimo dígito = n % 10
    li   $t3, 10
    div  $t0, $t3
    mfhi $t2            			    # Digito

    # Convierte a ASCII
    addi $t2, $t2, 48

    # Guarda en buffer (temporalmente al revés)
    sb   $t2, 0($t1)

    addi $t1, $t1, 1
    addi $v0, $v0, 1    			    # Contador de digitos

    # n = n / 10
    mflo $t0
    bnez $t0, itoa_loop

    # Ahora el número está al revés en buffer entonces lo invierte
    la   $t1, buffer
    addi $t2, $t1, 0        		    # Inicio
    add  $t3, $t1, $v0
    addi $t3, $t3, -1       		    # Final

itoa_reverse_loop:
    bge  $t2, $t3, itoa_end

    lb   $t0, 0($t2)
    lb   $t1, 0($t3)

    sb   $t1, 0($t2)
    sb   $t0, 0($t3)

    addi $t2, $t2, 1
    addi $t3, $t3, -1

    j itoa_reverse_loop

itoa_end:
    lw   $t3, 12($sp)
    lw   $t2, 8($sp)
    lw   $t1, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 16
    jr $ra

# --- PRINT_PADDING (Imprime N espacios) ---
print_padding:
    addi $sp, $sp, -8
    sw   $t0, 0($sp)
    sw   $a0, 4($sp)

    move $t0, $a0
    li   $v0, 11        			    # Syscall imprimir caracter
    li   $a0, 32        			    # ASCII espacio ' '
    
padding_loop:
    blez $t0, padding_end
    syscall
    
    addi $t0, $t0, -1
    
    j    padding_loop
    
padding_end:
    lw   $a0, 4($sp)
    lw   $t0, 0($sp)
    addi $sp, $sp, 8
    
    jr   $ra

# --- Guardado de archivo con inventario final ---
guardar_inventario_final:
    # Abrir archivo en modo escritura
    li   $v0, 13
    la   $a0, archivo_inventario   	    # Nombre
    li   $a1, 1
    li   $a2, 0
    syscall

    move $s0, $v0
    bltz $s0, guardar_inv_fin		    # Salir si hay error

    la   $s1, inventory_table		    # Puntero a tabla

guardar_inv_loop:
    lw   $t0, 0($s1)               	    # Puntero a producto
    beq  $t0, $zero, guardar_inv_cierre

    # Obtener puntero a nombre
    addi $t1, $t0, 16              	    # Nombre del producto

    # Calcular longitud del nombre
    move $t2, $t1
    
prod_len:
    lb   $t3, 0($t2)
    beq  $t3, $zero, prod_len_ok
    addi $t2, $t2, 1
    j prod_len

prod_len_ok:
    subu $a2, $t2, $t1             	    # Longitud del nombre
    move $a1, $t1
    move $a0, $s0
    li   $v0, 15
    syscall                       	    # Escribir nombre
    
    la $a1, espacio
    li $a2, 1
    move $a0, $s0
    li $v0, 15
    syscall				                # Agregar un espacio

    # Escribir " -- Stock: "
    la   $a1, inv_stock_msg       	    # "-- Stock: "
    li   $a2, 10
    move $a0, $s0
    li   $v0, 15
    syscall

    # Leer stock del producto
    lw   $t4, 4($t0)               	    # Stock

    # Convertir entero a ASCII
    move $t5, $t4
    la   $t6, buffer
    li   $t7, 0

prod_inv_convertir:
    li   $t8, 10
    div  $t5, $t8
    mfhi $t9
    mflo $t5
    addi $t9, $t9, 48
    sb   $t9, 0($t6)
    addi $t6, $t6, 1
    addi $t7, $t7, 1
    bgtz $t5, prod_inv_convertir

    # Invertir el número
    la   $t1, buffer
    move $t2, $t6
    addi $t2, $t2, -1

prod_invertir:
    lb   $t3, 0($t1)
    lb   $t4, 0($t2)
    sb   $t4, 0($t1)
    sb   $t3, 0($t2)
    addi $t1, $t1, 1
    addi $t2, $t2, -1
    blt  $t1, $t2, prod_invertir

    # Escribir stock convertido
    move $a0, $s0
    la   $a1, buffer
    move $a2, $t7
    li   $v0, 15
    syscall

    # Escribir salto de línea 
    la   $a1, newline
    li   $a2, 1
    move $a0, $s0
    li   $v0, 15
    syscall

    # Avanzar en la tabla de inventario
    addi $s1, $s1, 4
    j guardar_inv_loop


guardar_inv_cierre:
    li   $v0, 16
    move $a0, $s0
    syscall

guardar_inv_fin:
    jr $ra
