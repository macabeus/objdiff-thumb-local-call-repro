@ Two Thumb functions: `caller` calls `callee`, which comes right after it.
@ repro.sh assembles this file twice. The only difference is the `.global callee` line:
@   local.o   callee is local:  `as` resolves the `bl` itself and leaves no relocation
@   global.o  callee is global: `as` leaves a placeholder and an R_ARM_THM_CALL relocation

	.text
	.thumb

	.global caller
	.thumb_func
	.type caller, %function
caller:
	push {lr}
	bl callee
	pop {r0}
	bx r0
	.size caller, .-caller

	.align 2
.ifdef GLOBAL
	.global callee
.endif
	.thumb_func
	.type callee, %function
callee:
	bx lr
	.size callee, .-callee
