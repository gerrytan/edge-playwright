param(
    [Parameter(Mandatory = $true)]
    [string]$Url,
    [ValidateRange(1, 65535)]
    [int]$DebuggingPort = 9222
)

$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (!(Test-Path $edge)) {
    $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
}
if (!(Test-Path $edge)) {
    throw 'Microsoft Edge was not found in either Program Files directory.'
}

Start-Process -FilePath $edge -ArgumentList @(
    "--remote-debugging-port=$DebuggingPort"
    "--user-data-dir=`"$env:LOCALAPPDATA\PlaywrightSandbox`""
    '--no-first-run' # skip welcome & initial setup screen
    '--start-maximized'
    "`"$Url`""
)
