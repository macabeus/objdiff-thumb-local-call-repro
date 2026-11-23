#!/bin/sh
# objdiff scores `caller` below 100% with functionRelocDiffs=none, although both objects link to the same bytes.
# Needs GNU binutils for ARM (arm-none-eabi-*), jq, and objdiff-cli (set OBJDIFF to its path).
set -eu
cd "$(dirname "$0")"
OBJDIFF="${OBJDIFF:-objdiff-cli}"
mkdir -p build

echo "== 1. Assemble caller.s twice"
arm-none-eabi-as -mcpu=arm7tdmi -o build/local.o caller.s
arm-none-eabi-as -mcpu=arm7tdmi --defsym GLOBAL=1 -o build/global.o caller.s

echo
echo "== 2. The call before linking"
echo "local.o:";  arm-none-eabi-objdump -dr build/local.o  | grep -A1 '	bl	'
echo "global.o:"; arm-none-eabi-objdump -dr build/global.o | grep -A1 '	bl	'

echo
echo "== 3. After linking, the code is the same"
for o in local global; do
  arm-none-eabi-ld -e caller -o "build/$o.elf" "build/$o.o"
  arm-none-eabi-objcopy -O binary "build/$o.elf" "build/$o.bin"
done
cmp build/local.bin build/global.bin && echo "identical: $(xxd -p build/local.bin)"

echo
echo "== 4. objdiff's score for caller, relocation diffs off (functionRelocDiffs=none)"
score() {
  "$OBJDIFF" diff -1 "build/$1.o" -2 "build/$2.o" -c functionRelocDiffs=none -o - caller 2>/dev/null \
    | jq -r '.left.symbols[] | select(.name == "caller") | .match_percent'
}
echo "target local.o,  base global.o: $(score local global)%"
echo "target global.o, base local.o:  $(score global local)%"
