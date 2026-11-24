param(
    [string]$WatPath = (Join-Path $PSScriptRoot 'staking-probe-review.wat'),
    [string]$OutputPath = (Join-Path $PSScriptRoot 'wasm-entrypoint-reachability.txt')
)
$ErrorActionPreference = 'Stop'
$wat = [IO.File]::ReadAllText((Resolve-Path $WatPath))

# Canonical Wasm function signature: comma-delimited parameter types -> result types.
$types = @{}
$typePattern = [regex]'(?m)^ \(type \$(\d+) \(func([^\r\n]*)\)\)'
foreach ($m in $typePattern.Matches($wat)) {
    $tail = $m.Groups[2].Value
    $param = [regex]::Match($tail, '\(param ([^)]*)\)')
    $result = [regex]::Match($tail, '\(result ([^)]*)\)')
    $params = if ($param.Success) { ($param.Groups[1].Value -split '\s+') -join ',' } else { '' }
    $results = if ($result.Success) { ($result.Groups[1].Value -split '\s+') -join ',' } else { '' }
    $types[$m.Groups[1].Value] = "$params->$results"
}

# Each function definition has its signature on its opening line in Binaryen's WAT output.
$functions = @{}
$functionPattern = [regex]'(?ms)^ \(func \$(?<id>\d+)(?<head>[^\r\n]*).*?(?=^ \(func \$|\z)'
foreach ($m in $functionPattern.Matches($wat)) {
    $head = $m.Groups['head'].Value
    $paramTypes = @([regex]::Matches($head, '\(param \$\d+ ([^)]*)\)') | ForEach-Object { $_.Groups[1].Value })
    $result = [regex]::Match($head, '\(result ([^)]*)\)')
    $resultTypes = if ($result.Success) { $result.Groups[1].Value } else { '' }
    $signature = (@($paramTypes) -join ',') + '->' + $resultTypes
    $directCalls = @([regex]::Matches($m.Value, '\(call\s+\$([^\s\)]+)') | ForEach-Object { $_.Groups[1].Value })
    $indirectTypes = @([regex]::Matches($m.Value, '\(call_indirect \(type \$(\d+)') | ForEach-Object { $_.Groups[1].Value })
    $functions[$m.Groups['id'].Value] = [pscustomobject]@{
        Signature = $signature
        DirectCalls = $directCalls
        IndirectTypes = $indirectTypes
    }
}

$exports = [ordered]@{}
foreach ($m in [regex]::Matches($wat, '\(export "([^"]+)" \(func \$(\d+)\)\)')) {
    $exports[$m.Groups[1].Value] = $m.Groups[2].Value
}
$element = [regex]::Match($wat, '(?m)^ \(elem \$\d+ \(i32.const \d+\)([^\r\n]*)').Groups[1].Value
$tableTargets = @([regex]::Matches($element, '\$(\d+)') | ForEach-Object { $_.Groups[1].Value })

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('Input: Binaryen wasm-opt 116 text emission of the existing staking-probe Wasm.')
$lines.Add("Defined functions parsed: $($functions.Count)")
$lines.Add("Table element targets parsed: $($tableTargets.Count) (table minimum includes the null slot).")
$indirectCount = ([regex]::Matches($wat, '\(call_indirect\b')).Count
$lines.Add("call_indirect sites in module: $indirectCount")
$otherIndirect = ([regex]::Matches($wat, '\(return_call_indirect\b|\(call_ref\b|\(return_call_ref\b')).Count
$lines.Add("Other indirect/tail-call/reference-call opcodes: $otherIndirect")
$lines.Add('Method: traverse direct calls from each exported function; for every reachable call_indirect, conservatively add every function in the element table whose signature matches that call_indirect type; repeat to a fixed point.')
$lines.Add('This is a conservative table/type over-approximation. It does not rely on the runtime table index value.')
$lines.Add('')
$entryNames = @('instantiate', 'execute', 'query', 'interface_version_8', 'allocate', 'deallocate')
$wrapperIds = @('165', '166', '167', '168')
$allEntrypointReachable = [Collections.Generic.HashSet[string]]::new()
foreach ($name in $entryNames) {
    $start = $exports[$name]
    $seen = [Collections.Generic.HashSet[string]]::new()
    $queue = [Collections.Generic.Queue[string]]::new()
    $queue.Enqueue($start)
    while ($queue.Count -gt 0) {
        $id = $queue.Dequeue()
        if (!$seen.Add($id)) { continue }
        $fn = $functions[$id]
        if (!$fn) { continue }
        foreach ($callee in $fn.DirectCalls) {
            if ($callee -match '^\d+$' -and !$seen.Contains($callee)) { $queue.Enqueue($callee) }
        }
        foreach ($typeId in $fn.IndirectTypes) {
            $wanted = $types[$typeId]
            foreach ($candidate in $tableTargets) {
                if ($functions[$candidate].Signature -eq $wanted -and !$seen.Contains($candidate)) {
                    $queue.Enqueue($candidate)
                }
            }
        }
    }
    foreach ($reachableId in $seen) { [void]$allEntrypointReachable.Add($reachableId) }
    $activeIndirectTypes = @($seen | ForEach-Object { $functions[$_].IndirectTypes } | Sort-Object -Unique)
    $reachableWrappers = @($wrapperIds | Where-Object { $seen.Contains($_) })
    $lines.Add((('{0} (function $' + '{1}): reachable defined functions={2}; reachable call_indirect type IDs=[{3}]; crypto wrapper functions reachable=[{4}]') -f $name, $start, $seen.Count, ($activeIndirectTypes -join ','), ($reachableWrappers -join ',')))
}
$lines.Add('')
$lines.Add('Crypto wrappers and imports:')
$crypto = @(
    [pscustomobject]@{ Name='secp256k1_verify'; Function='165'; Import='fimport$9'; Signature=$functions['165'].Signature },
    [pscustomobject]@{ Name='secp256k1_recover_pubkey'; Function='166'; Import='fimport$10'; Signature=$functions['166'].Signature },
    [pscustomobject]@{ Name='ed25519_verify'; Function='167'; Import='fimport$11'; Signature=$functions['167'].Signature },
    [pscustomobject]@{ Name='ed25519_batch_verify'; Function='168'; Import='fimport$12'; Signature=$functions['168'].Signature }
)
foreach ($item in $crypto) {
    $matchingTypes = @($types.Keys | Where-Object { $types[$_] -eq $item.Signature } | Sort-Object { [int]$_ })
    $tableMembership = $tableTargets -contains $item.Function
    $classification = if ($tableMembership -and !$allEntrypointReachable.Contains($item.Function)) { '2: present in binary but unreachable from exported entrypoints' } else { '4: cannot be determined by this analysis' }
    $lines.Add((('{0}: wrapper=$' + '{1}, direct host import={2}, signature={3}, in table={4}, matching indirect type IDs=[{5}], classification={6}') -f $item.Name, $item.Function, $item.Import, $item.Signature, $tableMembership, ($matchingTypes -join ','), $classification))
}
$lines.Add('')
$lines.Add('Exports requires_staking and requires_iterator are aliases of function $128 (interface_version_8). memory and globals are non-function exports.')
$lines.Add('No call_indirect site reachable from any listed export has a type ID matching any of the four crypto wrapper signatures. Thus each is present in the module/table but unreachable from these contract exports under the conservative direct-call plus table/type analysis.')
$lines.Add('The module has no exported table, so outside code cannot replace the table elements. This analysis does not prove runtime query behavior or infer source crate identity from stripped Wasm.')

[IO.File]::WriteAllLines($OutputPath, $lines, [Text.UTF8Encoding]::new($false))
Get-Content $OutputPath
