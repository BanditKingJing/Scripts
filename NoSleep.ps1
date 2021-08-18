write-host Please wait...
while (1) {
$wsh = New-Object -ComObject WScript.shell
# Key to randomly tap. Shift F15. Doesn't exist on the keyboard. Won't bother you while working.
$wsh.SendKeys('+{F15}')
Start-Sleep -seconds 59
}
