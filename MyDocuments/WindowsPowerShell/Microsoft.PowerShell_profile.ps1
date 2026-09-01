#######################################
### $PROFILE per Windows Powershell ###
#######################################

# Se siamo in una sessione Windows terminal:
if ($env:wt_SESSION) {

	$ps7Profile = ([Environment]::GetFolderPath([Environment+SpecialFolder]::MyDocuments) + "\PowerShell\Microsoft.PowerShell_profile.ps1")

	# Se esiste il $PROFILE di PowerShell 7, allora lo carico anche in Windows PowerShell:
	if (Test-Path $ps7Profile) { 
		
		. $ps7Profile 

	}

}
 