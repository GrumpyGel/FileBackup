param ($Config)

#   Config (optional) = Full Name of Config file, eg "E:\MyDocz\FileBackup\Bin\FileUnpackBatch.cfg.
#                       Default is FileUnpackBatch.cfg in scripts directory.

#   Config format "Item=Value"

#   Item "Store" = Location to create logs, eg "E:\MyDocz\FileBackup\Store"
#   Item "Email" = (Optional) Email settings "From*To*SmtpServer"
#   Item "EmailCredentials" = (Optional) If email is being sent, authentication for SMTP server "User*Password"
#   Item "EmailSSLPort" = (Optional) If email is being sent, if this is specified SSL will be used and the value is the Port Number to use.
#   Item "Group" = "GroupName*Duplicate*ArchiveStore


$Summary = ""
$SummaryPart = ""
$GroupQty = 0
$DoVerify = $false
$Store = $null
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
    $UseConfig = $PSScriptRoot + "\FileUnpackBatch.cfg"
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
      "verify" {
        $LineValue = $LineValue.ToLower()
        switch ($LineValue) {
          "never" {
            $DoVerify = $false
            break; }
          "always" {
            $DoVerify = $true
            break; }
          default {
            $VerifyParts = $LineValue.split("*")
            If ($VerifyParts.length -ne 2) {
              throw ("Invalid Verify Config line - " + $Line) }
            switch ($VerifyParts[0]) {
              "weekly" {
                If ((Get-Date).DayOfWeek -eq $VerifyParts[1]) {
                  $DoVerify = $true }
                Else {
                  $DoVerify = $false }
                break; }
              "monthly" {
                If ((Get-Date).Day -eq $VerifyParts[1]) {
                  $DoVerify = $true }
                Else {
                  $DoVerify = $false }
                break; }
              default {
                throw ("Invalid Verify Config line - " + $Line) } } } }
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
        If ($GroupParts.length -ne 3) {
          throw ("Invalid Group Config line - " + $Line) }
        $UnpackParams = @{Store = $Store; Duplicate = $GroupParts[1]; ArchiveStore = $GroupParts[2]}
        If ($DoVerify -eq $true) {
          $UnpackParams["Verify"] = $true }
        try {
          $Files = get-childitem -Path ($Store + "\Backup_" + $GroupParts[0] + "_*.zip") -Exclude *_Unpacked_*.* -File | Sort LastWriteTime
          foreach ($File in $Files) {
            $UnpackParams["Backup"] = $File.Name
#           $SummaryPart = & ($PSScriptRoot + "\FileUnpack.ps1") -Store $Store -Backup $File.Name -Duplicate $GroupParts[1] -ArchiveStore $GroupParts[2] -Verify $DoVerify
            $SummaryPart = & ($PSScriptRoot + "\FileUnpack.ps1") @UnpackParams
            ShowOutput $SummaryPart $true } }
        catch {
          ShowOutput ($GroupParts[0] + " : Error - " + $_.Exception.Message) $true }
        break }
      default {
        throw "Invalid Config line - " + $Line } } }
  $ConfigStream.Close()
  If ($GroupQty -eq 0) {
    throw ("no Group lines in Config") }
  ShowOutput "FileUnpackBatch: Process complete" $true }
catch {
  $ErrorMsg = "FileUnpackBatch: Processing Failed, Error = " + $_.Exception.Message
  try { $ConfigStream.Close() } catch {} }

try {
  If ($EmailParts -ne $null) {
    If ($ErrorMsg -ne "") {
      ShowOutput $ErrorMsg $false }
    If ($Summary -ne "") {
      If ($EmailCredentialsParts -eq $null) {
        If ($EmailSSLPort -eq $null) {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileUnpackBatch Processing" -Body $Summary }
        Else {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileUnpackBatch Processing" -Body $Summary -UseSsl -Port $EmailSSLPort } }
      Else {
        $Password = ConvertTo-SecureString $EmailCredentialsParts[1] -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($EmailCredentialsParts[0], $Password)
        If ($EmailSSLPort -eq $null) {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileUnpackBatch Processing" -Body $Summary -Credential $Credential }
        Else {
          Send-MailMessage -From $EmailParts[0] -To $EmailParts[1] -SmtpServer $EmailParts[2] -Subject "FileUnpackBatch Processing" -Body $Summary -UseSsl -Port $EmailSSLPort -Credential $Credential } } } } }
catch {
  If ($ErrorMsg -eq "") {
    $ErrorMsg = "FileUnpackBatch: Failed sending email, Error = " + $_.Exception.Message } }

If ($ErrorMsg -ne "") {
  throw $ErrorMsg }

