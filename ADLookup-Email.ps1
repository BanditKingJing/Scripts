### Active Directory Lookup Script by BKJ
###		Changelog
###		2020-10-19		Added password reset
###						Started research into account unlocks
###						Unlock powershell command not allows. Access rights issue.
###		2021-03-22		Added AD LDS Install on fail load for win10 1900+
###						
###		2021-04-07		commented out some lookup fields and cleaned up asthetics
###						Added rerun lockcheck scripts after fix.

$host.ui.RawUI.WindowTitle = "AD Scripts - Email Lookup"

import-module activedirectory

$importedList = @(
	"DisplayName",
	"SamAccountName",
	"LockedOut",
	"Enabled",
	"PasswordExpired",
	"PasswordLastSet",
	"Company",
	"Department",
	"Description",
	"whenCreated",
#	"WhenChanged",
	"Division",
	"Manager",
	"Office",
	"OfficePhone",
	"telephoneNumber",
	"EmailAddress",
	"LastLogonDate",
#	"BadLogonCount",
#	"LastBadPasswordAttempt",
#	"badPasswordTime",
#	"badPwdCount",
	"HomeDirectory"
)


###  Use the following command to get the full list of property fields:
###  Get-ADUser -Identity LANID -Properties *


### Leave the rest alone.

	Write-Host
	Write-Host   **************************************************************
	Write-Host   *  Active Directory POWERSHELL SCRIPTS 
	Write-Host   **************************************************************
	Write-Host   *  Look up users in Active Directory.                        *
	Write-Host   **************************************************************

	$ADPassEmail = {
	Write-Host
	$ADEMAIL = Read-host "Enter the Email Address of the user you want look up"
	
# HELP!
# Needs check for valid lookup.
# Something like 
# if (Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties enabled) = TRUE 
# continue. Else. Restart

	Write-Host
	Write-Host   Looking up $ADEMAIL ...
	Write-Host

	$ADUSER = Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties SamAccountName
	Write-Host  Found $ADUSER
			
	ForEach ($i in $importedList)
		{
		Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties $i | ForEach-Object {
			Write-Host $i :  -NoNewline 
			Write-Host  $_.$i
			}
		}

	Write-Host

### Check for account lock.
&$CheckLocked

### Check for expired password
&$CheckExpired

###	Start over
&$ADPassEmail
}



### Password Reset Tool
$ResetPassword = {
	Write-Host
	Write-Host   **************************************************************
	$doublecheck = Read-host "Are you sure you want to reset this User's password? [Y]es?"
	#$doublecheck = "Y"
	Write-Host   **************************************************************
	Write-Host
	if ($doublecheck -eq "Y"){
		
		#	$TempPass = Read-host "Enter the new password:"
		#	## PASSWORD RESET COMMAND GO HERE
		#	$NewPass = ConvertTo-SecureString -AsPlainText $TempPass -Force
		#	Set-ADAccountPassword -Identity $AUSER -NewPassword $NewPass -Reset -PassThru
		Write-Host
		Write-Host   **************************************************************
		#	$TempPass = Read-host "Enter the new password:"
		$TempPass = Read-host "Enter the new password to use"
		# PASSWORD RESET COMMAND GO HERE
		$NewPass = ConvertTo-SecureString -AsPlainText $TempPass -Force
		Set-ADAccountPassword -Identity $ADUSER -NewPassword $NewPass -Reset -PassThru
		
		Write-Host   *  User password has been reset if no errors.
		Write-Host   *  Dont forget to have user change password in AIM.
		Write-Host   **************************************************************
		Write-Host

	} ELSE {
			Write-Host
			Write-Host   **************************************************************
			Write-Host   *  Aborting ...
		#	Write-Host   *  Stopping Password Reset.
			Write-Host   **************************************************************
			Write-Host

		}
	}

$CheckExpired = {
Write-Host
### $ADEMAIL = Read-host "Enter the Email Address of the user you want look up"
#$AUSER = Read-host "Enter the LAN-ID of the user you want to password reset"

$PasswordExpired = ($Verify = Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties PasswordExpired | Select-Object -ExpandProperty PasswordExpired)
#$PasswordExpired = ($Verify = Get-ADUser -Identity $AUSER -Properties * | Select-Object -ExpandProperty PasswordExpired)
#$ADUser = (Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties * | Select-Object -ExpandProperty SamAccountName)

Write-Host   Checking for expired password.
if ($PasswordExpired -eq "True") {
	Write-Host   "PASSWORD IS EXPIRED." -ForegroundColor Red
	Write-Host
	Write-Host   Starting Password Reset for $ADUser
	&$ResetPassword
	&$CheckExpired
	} ELSE {
	Write-Host   "Password is not expired." -ForegroundColor Green
	Write-Host
}
}

$CheckLocked = {
### $ADEMAIL = Read-host "Enter the Email Address of the user you want look up"
#$AUSER = Read-host "Enter the LAN-ID of the user you want to password reset"

$LockedStatus = ($Verify = Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties LockedOut | Select-Object -ExpandProperty LockedOut)
#$PasswordExpired = ($Verify = Get-ADUser -Identity $AUSER -Properties * | Select-Object -ExpandProperty PasswordExpired)
#$ADUser = (Get-ADUser -Filter {EmailAddress -eq $ADEMAIL} -Properties * | Select-Object -ExpandProperty SamAccountName)

Write-Host   Checking for account lock.
if ($LockedStatus -eq "True") {
	Write-Host   "Account is locked." -ForegroundColor Red
	Write-Host
	Write-Host   Starting Account Unlock for $ADUser
	Write-Host
	Write-Host   **************************************************************
	$doublecheck = Read-host "Are you sure you want to unlock this User's account? [Y]es?"
	#$doublecheck = "Y"
	Write-Host   **************************************************************
	Write-Host
	if ($doublecheck -eq "Y"){
		Write-Host   Feature not working for Win7. Please perform in AD if errors.
		Unlock-ADAccount -Identity $ADUser
		&$CheckLocked
		} ELSE {
			Write-Host   **************************************************************
			Write-Host   *  Aborting ...
		#	Write-Host   *  Stopping Password Reset.
			Write-Host   **************************************************************

	}} ELSE {
	Write-Host   "Account is not locked." -ForegroundColor Green
}
}

# start function
&$ADPassEmail
