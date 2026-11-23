# objdiff: a Thumb call to a local function scores below 100%

objdiff 3.8.3 scores a Thumb function below 100% when one object calls a function directly and the other calls it
through a relocation. This happens even with relocation diffs off (`functionRelocDiffs=none`), and even though both
objects link to identical bytes.

This is common in decomp projects. The target object is often built from assembly where the callee is a local
label. The base, built from C, calls the same function as a global symbol. Or the other way round: the target's
callee is global, and the C defines it `static`.

## Run it

```sh
OBJDIFF=/path/to/objdiff-cli ./repro.sh
```

You need GNU binutils for ARM (`arm-none-eabi-as`, `-ld`, `-objcopy`, `-objdump`), `jq`, and
[objdiff-cli 3.8.3](https://github.com/encounter/objdiff/releases/tag/v3.8.3).

## What it shows

[`local.s`](local.s) and [`global.s`](global.s) are the same code: `caller` calls `callee`, which comes right after
it. The only difference is the `.global callee` line in `global.s`:

| Object | `callee` is | The `bl callee` in `caller` |
|---|---|---|
| `local.o` | local | resolved by `as`: `f000 f803`, no relocation |
| `global.o` | global | a placeholder `f7ff fffe` plus an `R_ARM_THM_CALL callee` relocation (addend −4) |

After linking, both give the same bytes. objdiff scores `caller` like this, whichever object is the target:

```
target local.o,  base global.o: 98.75%
target global.o, base local.o:  98.75%
```

The expected score is 100% in both directions. With `functionRelocDiffs=none`, objdiff is meant to let a value in
the target match a relocation in the base.

## Why

There are two separate causes, one for each direction.

1. **Target `local.o`, base `global.o`: the destination is computed 4 bytes short.** objdiff checks whether a
   relocation lands inside the current function, and if so treats it as a branch inside the function. It computes
   where the relocation lands as `S + A`. ARM branch addends are relative to the PC, which is 4 bytes ahead in Thumb
   and 8 in ARM, so the real destination is `S + A + 4`. Here that is `0xc + (−4) = 0x8`, the `bx r0` inside
   `caller`. objdiff takes the call for a branch to it, and it no longer matches the resolved `bl 0xc`. This only
   happens when the callee comes right after the caller, as here.
2. **Target `global.o`, base `local.o`: the relaxation works in one direction only.** objdiff matches a value in
   the target against a relocation in the base. It never matches a relocation in the target against a value in the
   base.

## The fix

The branch
[`fix-thumb-local-call-reloc-relax`](https://github.com/macabeus/objdiff/tree/fix-thumb-local-call-reloc-relax) in
`macabeus/objdiff` makes two changes, one for each cause:

- It adds the PC offset when resolving ARM and Thumb branch relocations.
- It lets a relocation in the target match a value in the base with `functionRelocDiffs=none`, as a value in the
  target already matched a relocation in the base.

With that build, both directions score 100%. With the default `functionRelocDiffs=name_address`, both still score
98.75%: that mode compares what relocations point at, and one side has no relocation.
