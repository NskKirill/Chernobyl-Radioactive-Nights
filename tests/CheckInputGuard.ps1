param(
    [Parameter(Mandatory)]
    [string] $Luau
)

$ErrorActionPreference = 'Stop'
$sourcePath = Join-Path $PSScriptRoot '../src/ServerScriptService/Night1.server.lua'
$source = Get-Content -LiteralPath $sourcePath -Raw -Encoding utf8
$pattern = '(?s)local now = os.clock\(\)\s*(.*?)\s*if command == "StartNight"'
$guard = [regex]::Match($source, $pattern).Groups[1].Value
if (-not $guard) {
    throw 'Server input guard not found'
}

$test = @'
local actionTimes = {}
local function accept(player, command, now)
__GUARD__
    return true
end

assert(accept("A", "Camera1", 1), "first camera input")
assert(accept("A", "LeftDoor", 1), "camera must not suppress left door")
assert(accept("A", "RightDoor", 1), "doors must be independent")
assert(not accept("A", "Camera1", 1.05), "camera spam must be limited")
assert(not accept("A", "LeftDoor", 1.05), "door spam must be limited")
assert(accept("B", "Camera1", 1), "players must have independent limits")
assert(accept("A", "Camera1", 1.13), "camera cooldown expires")
assert(accept("A", "LeftDoor", 1.13), "door cooldown expires")
print("PASS 8 assertions against the input guard extracted from server source")
'@

$temporaryPath = Join-Path ([IO.Path]::GetTempPath()) ('CRN-input-' + [guid]::NewGuid().ToString('N') + '.luau')
try {
    [IO.File]::WriteAllText($temporaryPath, $test.Replace('__GUARD__', $guard))
    & $Luau $temporaryPath
    if ($LASTEXITCODE -ne 0) {
        throw 'Input guard regression failed'
    }
} finally {
    Remove-Item -LiteralPath $temporaryPath
}
