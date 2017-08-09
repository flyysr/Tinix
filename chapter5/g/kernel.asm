
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                               kernel.asm
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;                                                     Forrest Yu, 2005
; ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

; ----------------------------------------------------------------------
; �������ӷ���:
; [root@XXX XXX]# rm -f kernel.bin
; [root@XXX XXX]# nasm -f elf -o kernel.o kernel.asm
; [root@XXX XXX]# nasm -f elf -o string.o string.asm
; [root@XXX XXX]# nasm -f elf -o klib.o klib.asm
; [root@XXX XXX]# gcc -c -o start.o start.c
; [root@XXX XXX]# ld -s -Ttext 0x30400 -o kernel.bin kernel.o string.o start.o klib.o
; [root@XXX XXX]# rm -f kernel.o string.o start.o
; [root@XXX XXX]# 
; ----------------------------------------------------------------------

SELECTOR_KERNEL_CS	equ	8

; ���뺯��
extern	cstart

; ����ȫ�ֱ���
extern	gdt_ptr


[SECTION .bss]
StackSpace		resb	2 * 1024
StackTop:		; ջ��

[section .text]	; �����ڴ�

global _start	; ���� _start

_start:
	; ��ʱ�ڴ濴��ȥ�������ģ�����ϸ���ڴ������ LOADER.ASM ����˵������
	;              ��                                    ��
	;              ��                 ...                ��
	;              �ǩ�������������������������������������
	;              ��������������Page  Tables��������������
	;              ������������(��С��LOADER����)���������� PageTblBase
	;    00101000h �ǩ�������������������������������������
	;              ����������Page Directory Table���������� PageDirBase = 1M
	;    00100000h �ǩ�������������������������������������
	;              ���������� Hardware  Reserved ���������� B8000h �� gs
	;       9FC00h �ǩ�������������������������������������
	;              ����������������LOADER.BIN�������������� somewhere in LOADER �� esp
	;       90000h �ǩ�������������������������������������
	;              ����������������KERNEL.BIN��������������
	;       80000h �ǩ�������������������������������������
	;              ������������������KERNEL���������������� 30400h �� KERNEL ��� (KernelEntryPointPhyAddr)
	;       30000h �ǩ�������������������������������������
	;              ��                 ...                ��
	;              ��                                    ��
	;           0h ���������������������������������������� �� cs, ds, es, fs, ss
	;
	;
	; GDT �Լ���Ӧ���������������ģ�
	;
	;		              Descriptors               Selectors
	;              ����������������������������������������
	;              ��         Dummy Descriptor           ��
	;              �ǩ�������������������������������������
	;              ��         DESC_FLAT_C    (0��4G)     ��   8h = cs
	;              �ǩ�������������������������������������
	;              ��         DESC_FLAT_RW   (0��4G)     ��  10h = ds, es, fs, ss
	;              �ǩ�������������������������������������
	;              ��         DESC_VIDEO                 ��  1Bh = gs
	;              ����������������������������������������
	;
	; ע��! ��ʹ�� C �����ʱ��һ��Ҫ��֤ ds, es, ss �⼸���μĴ�����ֵ��һ����
	; ��Ϊ�������п��ܱ����ʹ�����ǵĴ���, ��������Ĭ��������һ����. ���紮�����������õ� ds �� es.
	;
	;


	; �� esp �� LOADER Ų�� KERNEL
	mov	esp, StackTop	; ��ջ�� bss ����

	sgdt	[gdt_ptr]	; cstart() �н����õ� gdt_ptr
	call	cstart		; �ڴ˺����иı���gdt_ptr������ָ���µ�GDT
	lgdt	[gdt_ptr]	; ʹ���µ�GDT

	;lidt	[idt_ptr]

	jmp	SELECTOR_KERNEL_CS:csinit
csinit:		; �������תָ��ǿ��ʹ�øոճ�ʼ���Ľṹ������<<OS:D&I 2nd>> P90.

	push	0
	popfd	; Pop top of stack into EFLAGS

	hlt