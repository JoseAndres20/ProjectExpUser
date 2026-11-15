[CmdletBinding()]
param(
    [string]$Project,
    [ValidateSet('jar', 'test', 'run')][string]$Target = 'jar',
    [string]$NetBeansHome,
    [string]$JavaHome
)
$ErrorActionPreference = 'Stop'
$config = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'local-projects.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if ($Project) {
    $selected = @($config.java | Where-Object { $_ -eq $Project })
    if ($selected.Count -eq 0) { throw "Unknown project. Choose one of: $($config.java -join ', ')" }
} else {
    $selected = @($config.java)
    if ($Target -eq 'run' -and $selected.Count -ne 1) { throw 'Choose one project with -Project before running an application.' }
}
if (-not $NetBeansHome) {
    $roots = @($env:ProgramFiles, ${env:ProgramFiles(x86)}, 'D:\Program Files') | Where-Object { $_ -and (Test-Path -LiteralPath $_) }
    $candidates = @($env:NETBEANS_HOME)
    foreach ($root in $roots) {
        $candidates += Get-ChildItem -LiteralPath $root -Directory -Filter 'NetBeans*' -ErrorAction SilentlyContinue | ForEach-Object { Join-Path $_.FullName 'netbeans' }
    }
    $NetBeansHome = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'extide\ant\lib\ant-launcher.jar')) } | Sort-Object -Descending | Select-Object -First 1
}
if (-not $NetBeansHome) { throw 'Set -NetBeansHome to the NetBeans installation containing extide\ant, or define NETBEANS_HOME.' }
if (-not $JavaHome) {
    $candidates = @()
    foreach ($root in @($env:ProgramFiles, 'D:\Program Files')) {
        if ($root -and (Test-Path -LiteralPath (Join-Path $root 'Java'))) {
            $candidates += Get-ChildItem -LiteralPath (Join-Path $root 'Java') -Directory -Filter 'jdk-*' | Sort-Object { [int]($_.Name -replace '^jdk-(\d+).*', '$1') } -Descending | ForEach-Object FullName
        }
    }
    $candidates += $env:JAVA_HOME
    $JavaHome = $candidates | Where-Object { $_ -and (Test-Path -LiteralPath (Join-Path $_ 'bin\javac.exe')) } | Select-Object -First 1
}
if (-not $JavaHome) { throw 'Set -JavaHome or JAVA_HOME to a JDK compatible with the selected project.' }
$java = Join-Path $JavaHome 'bin\java.exe'
$antHome = Join-Path $NetBeansHome 'extide\ant'
$copyLibs = Get-ChildItem -LiteralPath $NetBeansHome -Filter '*copylibstask*.jar' -Recurse -File | Select-Object -First 1 -ExpandProperty FullName
$env:JAVA_HOME = $JavaHome
$env:ANT_HOME = $antHome
$local = Join-Path $PSScriptRoot '.local-build'
New-Item -ItemType Directory -Path $local -Force | Out-Null
$properties = Join-Path $local 'user.properties'
if (-not (Test-Path -LiteralPath $properties)) { '# Project-local Ant configuration.' | Set-Content -LiteralPath $properties -Encoding ascii }
foreach ($item in $selected) {
    $file = Join-Path $PSScriptRoot $item
    $arguments = @("-Dant.home=$antHome", '-cp', (Join-Path $antHome 'lib\ant-launcher.jar'), 'org.apache.tools.ant.launch.Launcher', '-f', $file, "-Duser.properties.file=$properties")
    if ($copyLibs) { $arguments += '-Dlibs.CopyLibs.classpath=' + $copyLibs }
    $arguments += $Target
    & $java @arguments
    if ($LASTEXITCODE -ne 0) { throw "Ant failed for $item (exit $LASTEXITCODE)." }
}
