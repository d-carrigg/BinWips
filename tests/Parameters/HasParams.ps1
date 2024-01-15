[CmdletBinding()]
param($Param1, [string]$Param2, $Param3)

Get-Process | Select-Object -First 5 | Format-Table -AutoSize

