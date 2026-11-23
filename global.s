@ `caller` calls `callee`, which comes right after it. `callee` is global,
@ so `as` leaves a placeholder in the `bl` and an R_ARM_THM_CALL relocation.
@ local.s is the same file without the `.global callee` line.

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
	.global callee
	.thumb_func
	.type callee, %function
callee:
	bx lr
	.size callee, .-callee
