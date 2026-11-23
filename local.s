@ `caller` calls `callee`, which comes right after it. `callee` is local,
@ so `as` resolves the `bl` itself and leaves no relocation.
@ global.s is the same file plus one `.global callee` line.

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
	.thumb_func
	.type callee, %function
callee:
	bx lr
	.size callee, .-callee
