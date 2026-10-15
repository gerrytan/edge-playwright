# Edge for Playwright

Start Microsoft Edge on Windows with remote debugging enabled for Playwright connections. This is useful for AI agents
accessing browser experiences that require authentication and authorization.

## Start Edge

```powershell
.\Start-EdgeForPlaywright.ps1 -Url 'https://portal.azure.com' -DebuggingPort 9222
```

After going through the authentication flow, you can send AI prompts such as "use playwright to connect to edge at http://localhost:9222 and investigate the validation behaviour of AKS cluster creation form".

## Connecting via WSL

Firstly, a one off WSL NAT networking has to be setup, run this separately in an **Administrator Windows PowerShell**:

```powershell
# Forward Windows port 9223 to Edge's localhost debugging port 9222.
netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=9223 connectaddress=127.0.0.1 connectport=9222

# Get the current IPv4 address of the default WSL distribution.
# Add '-d <DistroName>' after wsl.exe if you use a different distribution.
$wslIp = ((wsl.exe -- hostname -I).Trim() -split '\s+')[0]
$ruleName = 'Edge-Debugging-WSL'
$rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
if ($rule) {
    $rule | Set-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Any
    $rule | Get-NetFirewallAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $wslIp
    $rule | Get-NetFirewallPortFilter | Set-NetFirewallPortFilter -Protocol TCP -LocalPort 9223
} else {
    New-NetFirewallRule -Name $ruleName -DisplayName 'Edge debugging from WSL' `
        -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9223 `
        -RemoteAddress $wslIp -Profile Any
}
```

Trigger AI prompt in WSL similar to: "use playwright to connect to edge at port 9223 on the Windows host and ..."

Both the Windows gateway and WSL address can change after WSL shutdown/restart or a Windows reboot. Rediscover the
gateway and rerun the firewall setup when the WSL address changes. With WSL mirrored networking, Windows services can
generally be reached using localhost; the NAT gateway lookup and port forwarding may not be needed.

## Build a taskbar shortcut

Run the following in **Windows PowerShell**, from the repository directory. It
creates `Edge for Playwright.lnk` in that directory and uses the same arguments
and default URL as the script. Change `$url` to choose another starting page.

```powershell
$edge = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (!(Test-Path $edge)) {
    $edge = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"
}
if (!(Test-Path $edge)) {
    throw 'Microsoft Edge was not found in either Program Files directory.'
}

$url = 'https://portal.azure.com'
$profile = "$env:LOCALAPPDATA\PlaywrightSandbox"
$shortcutPath = Join-Path $PWD.Path 'Edge for Playwright.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $edge
$shortcut.Arguments = "--remote-debugging-port=9222 --user-data-dir=`"$profile`" --no-first-run --start-maximized `"$url`""
$shortcut.IconLocation = "$edge,0"
$shortcut.Description = 'Start Edge with remote debugging for Playwright'
$shortcut.Save()
```

Right-click the shortcut and select **Pin to taskbar**.
