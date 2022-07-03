param ($Config)

#   Config (optional) = Full Name of Config file, eg "E:\MyDocz\FileBackup\Bin\FileBackupBatch.cfg.
#                       Default is FileBackupBatch.cfg in scripts directory.

#   Config format "Item=Value"

#   Item "Store" = Location to create logs, eg "E:\MyDocz\FileBackup\Store"
#   Item "Ftp" = (Optional) Ftp settings "FtpHost*FtpUser*FtpPassword*FtpPath"
#   Item "Email" = (Optional) Email settings "From*To*SmtpServer"
#   Item "EmailCredentials" = (Optional) If email is being sent, authentication for SMTP server "User*Password"
#   Item "EmailSSLPort" = (Optional) If email is being sent, if this is specified SSL will be used and the value is the Port Number to use.
#   Item "Group" = "GroupName*Path*Ignore" (Ignore Optional)

$Summary = ""
$SummaryPart = ""
$GroupQty = 0
$Store = $null
$DoFtp = $false
$FtpParts = $null
$EmailParts = $null
$EmailCredentialsParts = $null
$EmailSSLPort = $null
$ErrorMsg = ""


function ShowOutput($Msg, $Display) {
  If ($script:Summary -ne "") {
    $script:Summary = $script:Summary + "`r`n" }
  $script:Summary = $script:Summary + $Msg
  If ($Display -eq $true) {
    write-output $Msg }
}


try {
  $UseConfig = $Config
  If ($UseConfig -ne $null) {
    If (!(Test-Path $UseConfig)) {
      throw "Config '" + $Config + "' not found" } }
  Else {
    $UseConfig = $PSScriptRoot + "\FileBackupBatch.cfg"
    If (!(Test-Path $UseConfig)) {
      throw "Config file not found" } }

  $ConfigStream = New-Object System.IO.StreamReader($UseConfig)
  while (-NOT($ConfigStream.EndOfStream)) {
    $Line = $ConfigStream.ReadLine()
    $Pos = $Line.IndexOf("=")
    If ($Pos -eq -1) {
      throw ("Invalid Config line - " + $Line) }
    $LineItem = $Line.Substring(0, $Pos).ToLower().Trim()
    $LineValue = $Line.Substring($Pos + 1).Trim()
    switch ($LineItem) {
      "store" {
        $Store = $LineValue
        If (!(Test-Path $Store)) {
          throw "Store '" + $Store + "' not found" }
        break }
      "ftp" {
        If ($LineValue.ToLower() -eq "none") {
          $DoFtp = $false }
        Else {
          $DoFtp = $true
          $FtpParts = $LineValue.split("*")
          If ($FtpParts.length -ne 4) {
            throw ("Invalid Ftp Config line - " + $Line) } }
        break }
      "email" {
        If ($EmailParts -ne $null) {
          throw "Multiple Email definitions in Config" }
        If ($GroupQty -ne 0) {
          throw "Email definitions in Config can not come after Group lines" }
        $EmailParts = $LineValue.split("*")
        If ($EmailParts.length -ne 3) {
          throw ("Invalid Email Config line - " + $Line) }
        break }
      "emailcredentials" {
        If ($EmailCredentialsParts -ne $null) {
          throw "Multiple EmailCredentials definitions in Config" }
        $EmailCredentialsParts = $LineValue.split("*")
        If ($EmailCredentialsParts.length -ne 2) {
          throw ("Invalid EmailCredentials Config line - " + $Line) }
        break }
      "emailsslport" {
        If ($EmailSSLPort -ne $null) {
          throw "Multiple EmailSSLPort definitions in Config" }
        $EmailSSLPort = $LineValue
        break }
      "group" {
        If ($Store -eq $null) {
          throw "Store not specified in Config" }
        $GroupQty = $GroupQty + 1
        $GroupParts = $LineValue.split("*")
        $Ignore = ""
        If ($GroupParts.length -eq 3) {
          $Ignore = $GroupParts[2] }
        Else {
          If ($GroupParts.length -ne 2) {
            throw ("Invalid Group Config line - " + $Line) } }
        try {
          If ($DoFtp -eq $false) {
             $SummaryPart = & ($PSScriptRoot + "\FileBackup.ps1") -Store $Store -Name $GroupParts[0] -Path $GroupParts[1] -Ignore $Ignore }
          Else {
             $SummaryPart = & ($PSScriptRoot + "\FileBackup.ps1") -Store $Store -Name $GroupParts[0] -Path $GroupParts[1] -FtpHost $FtpParts[0] -FtpUser $FtpParts[1] -FtpPassword $FtpParts[2] -FtpPath $FtpParts[3] -Ignore $Ignore }
          ShowOutput $SummaryPart $true }
        catch {
          ShowOutput ($GroupParts[0] + " : Error - " + $_.Exception.Message) $true }
         break }
      default {
        throw ("Invalid Config line - " + $Line) } } }
  $ConfigStream.Close()
  ShowOutput "FileBackupBatch: Process complete" $true }
catch {
  $ErrorMsg = "FileBackupBatch: Processing Failed, Error = " + $_.Exception.Message
  try { $ConfigStream.Close() } catch {} }


try {
  If ($EmailParts -ne $null) {
    If ($ErrorMsg -ne "") {
      ShowOutput $ErrorMsg $false }
    If ($Summary -ne "") {
      If ($EmailCredentialsParts -eq $null) {
        If ($EmailSSLPort -eq $null) {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileBackupBatch Processing" -Body $Summary }
        Else {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileBackupBatch Processing" -Body $Summary -UseSsl -Port $EmailSSLPort } }
      Else {
        $Password = ConvertTo-SecureString $EmailCredentialsParts[1] -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($EmailCredentialsParts[0], $Password)
        If ($EmailSSLPort -eq $null) {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileBackupBatch Processing" -Body $Summary -Credential $Credential }
        Else {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileBackupBatch Processing" -Body $Summary -UseSsl -Port $EmailSSLPort -Credential $Credential } } } } }
catch {
  If ($ErrorMsg -eq "") {
    $ErrorMsg = "FileBackupBatch: Failed sending email, Error = " + $_.Exception.Message } }

If ($ErrorMsg -ne "") {
  throw $ErrorMsg }


# ./FileBackupBatch.ps1 -Config E:\MyDocz\FileBackup\TestGroup\FileBackupBatch.cfg
