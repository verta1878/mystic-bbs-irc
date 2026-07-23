	.file "m_input_crt.pas"
# Begin asmlist al_begin
# End asmlist al_begin
# Begin asmlist al_stabs
# End asmlist al_stabs
# Begin asmlist al_procedures

.text
	.balign 4,0x90
.globl	M_INPUT_CRT_TINPUTCRT_$__CREATE$$TINPUTCRT
M_INPUT_CRT_TINPUTCRT_$__CREATE$$TINPUTCRT:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$8,%esp
	movl	%eax,-8(%ebp)
	movl	%edx,-4(%ebp)
	movl	-4(%ebp),%eax
	cmpl	$1,%eax
	ja	Lj5
	jmp	Lj6
Lj5:
	movl	-4(%ebp),%eax
	movl	-4(%ebp),%edx
	call	*52(%edx)
	movl	%eax,-8(%ebp)
Lj6:
	movl	-8(%ebp),%eax
	testl	%eax,%eax
	je	Lj11
	jmp	Lj12
Lj11:
	jmp	Lj3
Lj12:
	movl	-8(%ebp),%eax
	movl	$0,%edx
	call	SYSTEM_TOBJECT_$__CREATE$$TOBJECT
	movl	-8(%ebp),%eax
	testl	%eax,%eax
	jne	Lj19
	jmp	Lj18
Lj19:
	movl	-4(%ebp),%eax
	testl	%eax,%eax
	jne	Lj17
	jmp	Lj18
Lj17:
	movl	-8(%ebp),%eax
	movl	-8(%ebp),%edx
	movl	(%edx),%edx
	call	*68(%edx)
Lj18:
Lj3:
	movl	-8(%ebp),%eax
	leave
	ret

.text
	.balign 4,0x90
.globl	M_INPUT_CRT_TINPUTCRT_$__DESTROY
M_INPUT_CRT_TINPUTCRT_$__DESTROY:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$8,%esp
	movl	%eax,-8(%ebp)
	movl	%edx,-4(%ebp)
	movl	-4(%ebp),%eax
	cmpl	$0,%eax
	jg	Lj24
	jmp	Lj25
Lj24:
	movl	-8(%ebp),%eax
	movl	-8(%ebp),%edx
	movl	(%edx),%edx
	call	*72(%edx)
Lj25:
	movl	-8(%ebp),%eax
	movl	$0,%edx
	call	SYSTEM_TOBJECT_$__DESTROY
	movl	-8(%ebp),%eax
	testl	%eax,%eax
	jne	Lj34
	jmp	Lj33
Lj34:
	movl	-4(%ebp),%eax
	testl	%eax,%eax
	jne	Lj32
	jmp	Lj33
Lj32:
	movl	-8(%ebp),%eax
	movl	-8(%ebp),%edx
	movl	(%edx),%edx
	call	*56(%edx)
Lj33:
	leave
	ret

.text
	.balign 4,0x90
.globl	M_INPUT_CRT_TINPUTCRT_$__PROCESSQUEUE$$BOOLEAN
M_INPUT_CRT_TINPUTCRT_$__PROCESSQUEUE$$BOOLEAN:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$5,%esp
	movl	%eax,-4(%ebp)
	call	CRT_KEYPRESSED$$BOOLEAN
	movb	%al,-5(%ebp)
	movb	-5(%ebp),%al
	leave
	ret

.text
	.balign 4,0x90
.globl	M_INPUT_CRT_TINPUTCRT_$__KEYWAIT$LONGINT$$BOOLEAN
M_INPUT_CRT_TINPUTCRT_$__KEYWAIT$LONGINT$$BOOLEAN:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$16,%esp
	movl	%eax,-8(%ebp)
	movl	%edx,-4(%ebp)
	movl	TC_M_INPUT_CRT_TINPUTCRT_$_KEYWAIT$LONGINT$$BOOLEAN_defaultWaitTimer,%eax
	movl	%eax,-16(%ebp)
	call	CRT_KEYPRESSED$$BOOLEAN
	movb	%al,-9(%ebp)
	jmp	Lj48
	.balign 4,0x90
Lj47:
	movw	$20,%ax
	call	CRT_DELAY$WORD
	addl	$20,-16(%ebp)
	movl	-8(%ebp),%eax
	call	M_INPUT_CRT_TINPUTCRT_$__KEYPRESSED$$BOOLEAN
	movb	%al,-9(%ebp)
Lj48:
	movb	-9(%ebp),%al
	testb	%al,%al
	je	Lj56
	jmp	Lj49
Lj56:
	movl	-16(%ebp),%eax
	cmpl	-4(%ebp),%eax
	jl	Lj47
	jmp	Lj49
Lj49:
	movb	-9(%ebp),%al
	leave
	ret

.text
	.balign 4,0x90
.globl	M_INPUT_CRT_TINPUTCRT_$__READKEY$$CHAR
M_INPUT_CRT_TINPUTCRT_$__READKEY$$CHAR:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$5,%esp
	movl	%eax,-4(%ebp)
	call	CRT_READKEY$$CHAR
	movb	%al,-5(%ebp)
	movb	-5(%ebp),%al
	leave
	ret

.text
	.balign 4,0x90
.globl	M_INPUT_CRT_TINPUTCRT_$__KEYPRESSED$$BOOLEAN
M_INPUT_CRT_TINPUTCRT_$__KEYPRESSED$$BOOLEAN:
	pushl	%ebp
	movl	%esp,%ebp
	subl	$5,%esp
	movl	%eax,-4(%ebp)
	call	CRT_KEYPRESSED$$BOOLEAN
	movb	%al,-5(%ebp)
	movb	-5(%ebp),%al
	leave
	ret
# End asmlist al_procedures
# Begin asmlist al_globals

.data
	.balign 4
.globl	_$M_INPUT_CRT$_Ld1
_$M_INPUT_CRT$_Ld1:
	.byte	9
	.ascii	"TInputCRT"

.data
	.balign 4
.globl	VMT_M_INPUT_CRT_TINPUTCRT
VMT_M_INPUT_CRT_TINPUTCRT:
	.long	4,-4
	.long	VMT_SYSTEM_TOBJECT
	.long	_$M_INPUT_CRT$_Ld1
	.long	0,0
	.long	_$M_INPUT_CRT$_Ld2
	.long	RTTI_M_INPUT_CRT_TINPUTCRT
	.long	0,0
	.long	FPC_EMPTYINTF
	.long	0
	.long	M_INPUT_CRT_TINPUTCRT_$__DESTROY
	.long	SYSTEM_TOBJECT_$__NEWINSTANCE$$TOBJECT
	.long	SYSTEM_TOBJECT_$__FREEINSTANCE
	.long	SYSTEM_TOBJECT_$__SAFECALLEXCEPTION$TOBJECT$POINTER$$HRESULT
	.long	SYSTEM_TOBJECT_$__DEFAULTHANDLER$formal
	.long	SYSTEM_TOBJECT_$__AFTERCONSTRUCTION
	.long	SYSTEM_TOBJECT_$__BEFOREDESTRUCTION
	.long	SYSTEM_TOBJECT_$__DEFAULTHANDLERSTR$formal
	.long	SYSTEM_TOBJECT_$__DISPATCH$formal
	.long	SYSTEM_TOBJECT_$__DISPATCHSTR$formal
	.long	SYSTEM_TOBJECT_$__EQUALS$TOBJECT$$BOOLEAN
	.long	SYSTEM_TOBJECT_$__GETHASHCODE$$LONGINT
	.long	SYSTEM_TOBJECT_$__TOSTRING$$ANSISTRING
	.long	0

.data
	.balign 4
.globl	THREADVARLIST_M_INPUT_CRT
THREADVARLIST_M_INPUT_CRT:
	.long	0
# End asmlist al_globals
# Begin asmlist al_const
# End asmlist al_const
# Begin asmlist al_typedconsts

.data
	.balign 4
TC_M_INPUT_CRT_TINPUTCRT_$_KEYWAIT$LONGINT$$BOOLEAN_defaultWaitTimer:
	.long	0
# End asmlist al_typedconsts
# Begin asmlist al_rotypedconsts
# End asmlist al_rotypedconsts
# Begin asmlist al_threadvars
# End asmlist al_threadvars
# Begin asmlist al_imports
# End asmlist al_imports
# Begin asmlist al_exports
# End asmlist al_exports
# Begin asmlist al_resources
# End asmlist al_resources
# Begin asmlist al_rtti

.data
	.balign 4
.globl	_$M_INPUT_CRT$_Ld2
_$M_INPUT_CRT$_Ld2:
	.short	0
	.long	_$M_INPUT_CRT$_Ld3
	.balign 4
.globl	_$M_INPUT_CRT$_Ld3
_$M_INPUT_CRT$_Ld3:
	.short	0

.data
	.balign 4
.globl	INIT_M_INPUT_CRT_TINPUTCRT
INIT_M_INPUT_CRT_TINPUTCRT:
	.byte	15,9
	.ascii	"TInputCRT"
	.long	4,0

.data
	.balign 4
.globl	RTTI_M_INPUT_CRT_TINPUTCRT
RTTI_M_INPUT_CRT_TINPUTCRT:
	.byte	15,9
	.ascii	"TInputCRT"
	.long	VMT_M_INPUT_CRT_TINPUTCRT
	.long	RTTI_SYSTEM_TOBJECT
	.short	0
	.byte	11
	.ascii	"m_Input_CRT"
	.short	0
# End asmlist al_rtti
# Begin asmlist al_dwarf_frame
# End asmlist al_dwarf_frame
# Begin asmlist al_dwarf_info
# End asmlist al_dwarf_info
# Begin asmlist al_dwarf_abbrev
# End asmlist al_dwarf_abbrev
# Begin asmlist al_dwarf_line
# End asmlist al_dwarf_line
# Begin asmlist al_picdata
# End asmlist al_picdata
# Begin asmlist al_resourcestrings
# End asmlist al_resourcestrings
# Begin asmlist al_objc_data
# End asmlist al_objc_data
# Begin asmlist al_objc_pools
# End asmlist al_objc_pools
# Begin asmlist al_end
# End asmlist al_end

