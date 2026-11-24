#!/usr/bin/env python3
"""Read-only section/limit inventory for the built staking probe Wasm."""

from pathlib import Path


def uleb(data: bytes, pos: int) -> tuple[int, int]:
    value = shift = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        if byte < 0x80:
            return value, pos
        shift += 7


def sleb(data: bytes, pos: int) -> tuple[int, int]:
    shift = value = 0
    while True:
        byte = data[pos]
        pos += 1
        value |= (byte & 0x7F) << shift
        shift += 7
        if byte < 0x80:
            if byte & 0x40:
                value |= -(1 << shift)
            return value, pos


def wasm_string(data: bytes, pos: int) -> int:
    size, pos = uleb(data, pos)
    return pos + size


def limits(data: bytes, pos: int) -> tuple[int, int]:
    flags, pos = uleb(data, pos)
    minimum, pos = uleb(data, pos)
    if flags & 1:
        _, pos = uleb(data, pos)
    return minimum, pos


def const_expr_end(data: bytes, pos: int) -> int:
    while True:
        op = data[pos]
        pos += 1
        if op == 0x0B:  # end
            return pos
        if op == 0x41:  # i32.const
            _, pos = sleb(data, pos)
        elif op == 0x42:  # i64.const
            _, pos = sleb(data, pos)
        elif op == 0x23:  # global.get
            _, pos = uleb(data, pos)
        elif op == 0xD0:  # ref.null
            _, pos = sleb(data, pos)
        elif op == 0xD2:  # ref.func
            _, pos = uleb(data, pos)
        else:
            raise ValueError(f"unexpected const-expression opcode 0x{op:02x}")


wasm = Path("artifacts/contracts/qorelease_staking_probe.wasm").read_bytes()
if wasm[:8] != b"\x00asm\x01\x00\x00\x00":
    raise SystemExit("invalid Wasm magic/version")

metrics = {
    "bytes": len(wasm),
    "custom_section_bytes": 0,
    "function_types": 0,
    "imported_functions": 0,
    "defined_functions": 0,
    "exports": 0,
    "globals": 0,
    "element_segments": 0,
    "element_entries": 0,
    "data_segments": 0,
    "initial_memory_pages": 0,
    "table_minimum": 0,
}

pos = 8
while pos < len(wasm):
    section_id = wasm[pos]
    pos += 1
    size, pos = uleb(wasm, pos)
    end = pos + size
    if end > len(wasm):
        raise SystemExit("section extends past module end")
    if section_id == 0:
        metrics["custom_section_bytes"] += size
    elif section_id == 2:
        count, cur = uleb(wasm, pos)
        for _ in range(count):
            cur = wasm_string(wasm, cur)  # module
            cur = wasm_string(wasm, cur)  # import name
            kind = wasm[cur]
            cur += 1
            if kind == 0:
                _, cur = uleb(wasm, cur)
                metrics["imported_functions"] += 1
            elif kind == 1:
                cur += 1  # reference type
                _, cur = limits(wasm, cur)
            elif kind == 2:
                _, cur = limits(wasm, cur)
            elif kind == 3:
                cur += 2  # value type and mutability
            else:
                raise SystemExit(f"unknown import kind {kind}")
    elif section_id == 3:
        metrics["defined_functions"], _ = uleb(wasm, pos)
    elif section_id == 4:
        count, cur = uleb(wasm, pos)
        if count:
            cur += 1  # reference type
            metrics["table_minimum"], cur = limits(wasm, cur)
    elif section_id == 5:
        count, cur = uleb(wasm, pos)
        if count:
            metrics["initial_memory_pages"], cur = limits(wasm, cur)
    elif section_id == 6:
        metrics["globals"], _ = uleb(wasm, pos)
    elif section_id == 7:
        metrics["exports"], _ = uleb(wasm, pos)
    elif section_id == 9:
        count, cur = uleb(wasm, pos)
        metrics["element_segments"] = count
        for _ in range(count):
            flags, cur = uleb(wasm, cur)
            if flags == 0:
                cur = const_expr_end(wasm, cur)
                entries, cur = uleb(wasm, cur)
                metrics["element_entries"] += entries
                for _ in range(entries):
                    _, cur = uleb(wasm, cur)
            elif flags == 1:
                cur += 1  # elemkind
                entries, cur = uleb(wasm, cur)
                metrics["element_entries"] += entries
                for _ in range(entries):
                    _, cur = uleb(wasm, cur)
            else:
                raise SystemExit(f"non-MVP element flags {flags}; manual review needed")
    elif section_id == 11:
        count, cur = uleb(wasm, pos)
        metrics["data_segments"] = count
        for _ in range(count):
            flags, cur = uleb(wasm, cur)
            if flags == 0:
                cur = const_expr_end(wasm, cur)
            elif flags == 2:
                _, cur = uleb(wasm, cur)
                cur = const_expr_end(wasm, cur)
            elif flags != 1:
                raise SystemExit(f"non-MVP data flags {flags}; manual review needed")
            size, cur = uleb(wasm, cur)
            cur += size
    elif section_id == 12:  # data-count section
        pass
    elif section_id == 1:
        metrics["function_types"], _ = uleb(wasm, pos)
    pos = end

metrics["functions"] = metrics["imported_functions"] + metrics["defined_functions"]
for key, value in metrics.items():
    print(f"{key}: {value}")
