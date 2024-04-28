.model tiny
.8086
.code
        org 100h
start:
        mov ax,0003h
        int 10h
        
@@spawn1:
        ; i didn't make a random number generator.... 
        ; so the figures will be in a row
        mov ax,4
        mov word ptr [cur_x],ax ;cur_x,cur_y=4,0-> start pozition of figure
        mov al,byte ptr[next_f]        
        inc al
        cmp al,7        ;7 figure in tetris
        jb @@spawn2
        xor al,al
@@spawn2:
        mov byte ptr[next_f],al; rember number of figure
        xor ah,ah
        shl ax,1        ;ax*2
        mov si,ax
        mov ax,word ptr[list_figure+si]
        mov word ptr[cur_figure],ax
        call Check
        jc @@game_stop
        mov ax,0
        mov byte ptr[cur_var],al
@@fallLoop:
       call DrawField
      ;  call DrawOver
        call DrawFigure        
        mov ah,86h       ;wait
        mov dx,5f90h    ; 025f90h=155 536 microsecond
        mov cx,02h
        int 15h
@@key_loop:  
        mov ah,01h ;check key press
        int 16h
        jz @@nokey
        mov ah,00h      ;read key
        int 16h
        cmp ax, 011bh   ;key_esc
        je @@game_stop
        cmp ax,04800h   ;key_up
        je @@rotate ;in realization
        cmp ax,04b00h   ;key_left
        je  @@move_left
        cmp ax, 04d00h  ;key_right
        je @@move_right
        jmp @@key_loop
@@nokey:
        mov al,byte ptr[cur_y]
        inc al
        mov byte ptr[cur_y],al
        call Check
        jnc @@fallLoop 
         dec byte ptr [cur_y]
        call FixateFigure
        call RemoveLines
        jmp @@spawn1
@@move_left:               
        mov al,byte ptr[cur_x]
        or al,al
        jz @@key_loop
        dec al
        mov byte ptr [cur_x],al
        call Check
        jnc @@key_loop
        inc byte ptr [cur_x]
        jmp @@key_loop

@@move_right:
        mov al,byte ptr[cur_x]
        inc al
        mov byte ptr [cur_x],al
        call Check
        jnc @@key_loop
        dec byte ptr [cur_x]
@@key_loop2:
         jmp @@key_loop 
       

@@game_stop:        
        mov ax,4c00h
        int 21h


@@rotate:
        mov bl,byte ptr[cur_var]; curent state of figure
        mov dx,word ptr[cur_figure]     ;remeber previous state 
        mov al,byte ptr[next_f]
        xor ah,ah
        shl ax,1        ;ax*2          
        mov si,ax
        mov ax,word ptr[list_figure+si]; ax= offset of figure 
        push ax
        add ax,16
        mov si,ax
        pop ax
        mov cl,byte ptr[si]   ;all state of figure
        inc bl          ;go to next state
        mov byte ptr[cur_var],bl
        cmp bl,cl
        jbe @@rotate1                  ; if new_state<=all_state go else
        xor bl,bl
        mov byte ptr[cur_var],bl       ; cur_var=0
        mov word ptr[cur_figure],ax
        call Check
        jnc @@key_loop2
        mov word ptr[cur_figure],dx; cur_figure= previous state
        jmp @@key_loop2
@@rotate1:
         ;ax-offset figure dx -previous figure bl - next state
        xor bh,bh
        cmp bl,0
        jz @@rotate2
        shl bx,1
        shl bx,1
        shl bx,1
        shl bx,1 ;bx=bx*16 16 - size of one state of figure (shl bx,4 in my tasm dosn't work)
        inc bx          ;see how masiv organaze) 
@@rotate2:
        mov al,byte ptr[next_f]
        xor ah,ah
        shl ax,1        ;ax*2          
        mov si,ax
        mov ax,word ptr[list_figure+si]; ax= offset of figure 
        add ax,bx
        mov word ptr[cur_figure],ax
        push dx
        call Check
        jnc @@key_loop2
        pop dx
        mov word ptr[cur_figure],dx
        jmp @@key_loop2


RemoveLines:
        std 
        mov si,offset field+200-1
@@remove_loop:
        mov dl,1
        mov cx,10
        mov di,si       ;previus line
@@scan_line:
        lodsb
        or al,al
        jnz @@continue
        xor dl,dl
@@continue:
        loop @@scan_line
        or dl,dl
        jz @@next_line
        mov ax,ds
        mov es,ax
        push di
        mov cx,si
        sub cx,offset field
        inc cx
        rep movsb
        mov cx,10
        xor al,al
        rep stosb
        pop si
@@next_line:
        cmp si,offset field - 1
        jne @@remove_loop
        cld
        ret








FixateFigure:
        mov bx,word ptr[cur_x]  ;bl=cur_x bh=cur_y
        mov al,bh
        mov ah,10
        mul ah
        xor ch,ch
        mov cl,bl
        add ax,cx
        add ax,offset field
        mov di,ax
        mov si, word ptr[cur_figure]        ;array element <=> (cur_x,cur_y) 
        
        mov dx,4
@@rowFF:
        mov cx,4
@@colFF:        
        lodsb           ;al=cur_figure(x,y)
        or al,al
        jz @@skipFF
        mov byte ptr[di],al     ;field(x,y)=figure(bad explnation)
@@skipFF:
        inc di
        loop @@colFF
        add di,10-4          ;field_width-figure_wigth    
        dec dx
        jnz @@rowFF
        ret


Check:
        mov bx,word ptr[cur_x]  ;bl=cur_x bh=cur_y
        mov al,bh
        mov ah,10
        mul ah
        xor ch,ch
        mov cl,bl
        add ax,cx
        add ax,offset field
        mov di,ax
        mov ax,word ptr[cur_figure]
        mov si,ax
        mov dx,4
@@rowC:        
        mov cx,4
@@colC:
        lodsb   ;cur_figure->al
        or al,al
        jz @@skipC
        cmp bl,10       ;leave the field along x?
        jae @@overlay
        cmp bh,20      ;leave the field along y?
        jae @@overlay
        mov al,byte ptr [di] ;al = field element
        or al,al        
        jnz @@overlay   ;overlay with already standing figures
@@skipC:
        inc bl          ;cur_x+1
        inc di          ;next elem of field
        loop @@colc
        add di,10-4     ;field_width-figure_wigth
        sub bl,4        ;return cur_x
        inc bh          ;cur_y+1
        dec dx
        jnz @@rowc
        clc
        ret
@@overlay:
        stc
        ret

DrawField:
        mov bx,20
        mov si,offset field
        mov ax,0b800h
        mov es,ax
        mov di,160+20 
@@row:        
        mov ax,0fb3h
        stosw
        mov cx,10
@@col:        
        lodsb
        or al,al
        jz @@empty
@@full:
        mov ah,al
        mov al,0dbh
        stosw
        stosw
        loop @@col
        jmp @@end
@@empty:        
        mov ax,020h 
        stosw
        stosw
        loop @@col
@@end:
        mov ax,0fb3h
        stosw
        add di,160-44
        dec bx
        jnz @@row
        mov ax, 0fc0h
        stosw
        mov ax,0fc4h
        mov cx,20
        rep stosw
        mov ax,0fd9h
        stosw
        ret

DrawFigure:   
        mov bx,word ptr [cur_x];bl=cur_x;bh=cur_y
        ; cur_y*160 (field_hight)
        mov al,bh
        inc al
        mov ah,160
        mul ah
        ; (cur_x*2+1)*2  
        xor bh,bh
        shl bx,1        ;cur_x*2
        add bx,11       ;cur_x*2+start_field+1
        shl bx,1
        add ax,bx       
        mov di,ax       ;di=cur_y*160+(cur_x*2+1)*2     
        mov ax,0b800h   ;es:di->cur_video_ram
        mov es,ax
        mov bx,4
        mov si,word ptr[cur_figure]
@@rowF:       
        mov cx,4
@@colF:
        lodsb 
        or al,al        ;check al==0
        jz @@skipF 
        mov ah,al       ;ah- color
        mov al,0dbh      ;full_block
        stosw
        stosw
        loop @@colF
        jmp @@endF
@@skipF:
        add di,4        ;output feature
        loop @@colF
@@endF:
        add di,160-4*2*2        ;160 - screen 4- width figure 4-block
        dec bx
        jnz @@rowF
        ret

DrawOver:
        mov bx,4
        mov ax,0b800h
        mov es,ax
        mov di,26      ;goto start field into 
        mov ah,5
        mov ax,020h
@@rowO:
        mov cx,6
@@calO:
        stosw
        stosw
        loop @@calO
        add di,160-20
        dec bx
        jnz @@rowO
        ret



cur_figure dw offset square

cur_x db 0;
cur_y db 0;

next_f db 0;
cur_var db 0

list_figure dw offset square
            dw offset line
            dw offset s_figure
            dw offset t_figure
            dw offset z_figure
            dw offset l_figure
            dw offset re_l

square    db 3,3,0,0
          db 3,3,0,0
          db 0,0,0,0
          db 0,0,0,0
          db 0

line      db 5,0,0,0
          db 5,0,0,0
          db 5,0,0,0
          db 5,0,0,0
          db 1; count of variotion to rotate 0-no rotate 1- two choices and...
          db 0,0,0,0
          db 0,0,0,0
          db 0,0,0,0
          db 5,5,5,5

s_figure  db 6,0,0,0
          db 6,6,0,0
          db 0,6,0,0
          db 0,0,0,0
          db 1
          db 0,6,6,0
          db 6,6,0,0
          db 0,0,0,0
          db 0,0,0,0

z_figure  db 0,7,0,0
          db 7,7,0,0
          db 7,0,0,0
          db 0,0,0,0
          db 1
          db 7,7,0,0
          db 0,7,7,0
          db 0,0,0,0
          db 0,0,0,0

t_figure  db 0,9,0,0
          db 9,9,9,0
          db 0,0,0,0
          db 0,0,0,0
          db 2
          db 9,0,0,0
          db 9,9,0,0
          db 9,0,0,0
          db 0,0,0,0
          db 9,9,9,0
          db 0,9,0,0
          db 0,0,0,0
          db 0,0,0,0

l_figure  db 4,0,0,0
          db 4,0,0,0
          db 4,4,0,0
          db 0,0,0,0
          db 2
          db 4,4,4,0
          db 4,0,0,0
          db 0,0,0,0
          db 0,0,0,0
          db 4,4,0,0
          db 0,4,0,0
          db 0,4,0,0
          db 0,0,0,0

re_l      db 0,2,0,0
          db 0,2,0,0
          db 2,2,0,0
          db 0,0,0,0
          db 2
          db 2,0,0,0
          db 2,2,2,0
          db 0,0,0,0
          db 0,0,0,0
          db 2,2,0,0
          db 2,0,0,0
          db 2,0,0,0
          db 0,0,0,0

field db 200 dup(0)


end start













