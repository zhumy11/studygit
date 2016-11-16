strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2")
Set colItems = objWMIService.ExecQuery("SELECT SerialNumber FROM Win32_BIOS")
For Each objItem In colItems
      WScript.Echo "SerialNumber: " & objItem.SerialNumber
Next