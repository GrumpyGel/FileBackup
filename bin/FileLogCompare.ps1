param ($OldLog, $OldBackup, $NewLog, $LogFile)

#   OldLog = Name of older Log file, eg "E:\Backups\SiteNet\Backup_SiteNet_202105021200.log".
#   OldBackup = Name of older Backup file containing old Log, eg "E:\Backups\Store\Backup_TestGroup_202105021200.zip".
#   NewLog = Name of newer Log file, eg "E:\Backups\SiteNet\Backup_SiteNet_202105031200.log".
#   LogFile = Name of Log file to create, eg "E:\Backups\SiteNet\Backup_Compare.log"

#   Must provide NewLog and either OldLog or OldBackup.

#   Output format "Change*Ttype*Name"
#
#   Change = 'D'eleted, 'N'ew or 'M'odified
#   Type = 'D'irectory or 'F'ile
#   Name = Name of directory or file (file includes path).


function Log_Clear($Log) {
  $Log.Type = ""
  $Log.Dir = ""
  $Log.File = ""
  $Log.Len = 0
  $Log.Date = $null
}


function Log_ShowOutput($Log) {
  If ($Log.OutputQty -eq 0) {
    return }
  If ($Log.OutputLog -eq $null) {
    write-output ($Log.Output) }
  else {
    Add-Content $Log.OutputLog $Log.Output }
  $Log.OutputQty = 0
  $Log.Output = ""
}


function Log_Close($Log) {
  $Log.Open = $false
  try { $Log.Stream.Close() } catch {}
  try { $Log.Stream.Dispose() } catch {}
  If ($Log.IsZip -eq $true) {
    try { $Log.ZipEntryStream.Dispose() } catch {}
    try { $Log.Zip.Dispose() } catch {} }
  Log_Clear($Log)
}


function Log_Read($Log) {

# Skip any Ignore line to only return directory or File lines.

  Do { 
    If ($Log.Stream.EndOfStream) {
      Log_Close $Log
      return }
    $Log.LineNo += 1
    $Line = $Log.Stream.ReadLine()
    $Parts = $Line.split("*") } While ($Parts[0] -eq "I")

  If ($Parts[0] -eq "D") {
    Log_Clear($Log)
    $Log.Type = "D"
    $Log.Dir = $Parts[1]
    return }
  If ($Parts[0] -ne "F") {
    Log_Close $Log $LogFile
    return }
  $Log.Type = "F"
  $Log.File = $Parts[1]
  $Log.Len = [int] $Parts[2]
  $Log.Date = [DateTime]::ParseExact($Parts[3], "yyyyMMddHHmmss", $null)
# $Log.Date = [DateTime]::ParseExact($Parts[3].substring(0, 12), "yyyyMMddHHmm", $null)
}


function Log_Open($Log, $FileName) {
  If (!(Test-Path $FileName)) {
    throw "Log '" + $FileName + "' not found" }

  try {
    $Log.Open = $true
    $Log.IsZip = $false
    $Log.Zip = $null
    $Log.ZipEntry = $null
    $Log.ZipEntryStream = $null
    $Log.Stream = New-Object System.IO.StreamReader($FileName)
    $Log.OutputQty = 0
    $Log.Output = ""
    Log_Clear($Log)
    Log_Read($Log) }
  catch {
    $ErrMsg = $_.Exception.Message
    try { Log_Close($Log) } catch {}
    throw $ErrMsg }
}


function Log_OpenFromBackup($Log, $FileName) {
  If (!(Test-Path $FileName)) {
    throw "Backup '" + $FileName + "' not found" }

  $BackupLogFile = Split-Path -Path $FileName -Leaf
  $BackupLogFile = $BackupLogFile.Replace(".zip", ".log")
  $BackupLogFile = $BackupLogFile.Replace("_Unpacked_", "_")

  Add-Type -As System.IO.Compression.FileSystem
  [System.IO.Compression.CompressionLevel]$Compression = "Optimal"
 
  try {
    $Log.Open = $true
    $Log.IsZip = $true
    $Log.Zip = [System.IO.Compression.ZipFile]::OpenRead($FileName)
    $Log.ZipEntry = $Log.Zip.GetEntry($BackupLogFile)
    $Log.ZipEntryStream = $Log.ZipEntry.Open()
    $Log.Stream = New-Object System.IO.StreamReader($Log.ZipEntryStream)
    $Log.OutputQty = 0
    $Log.Output = ""
    Log_Clear($Log)
    Log_Read($Log) }
  catch {
    $ErrMsg = $_.Exception.Message
    try { Log_Close($Log) } catch {}
    throw $ErrMsg }
}


function Log_Output($Log, $Change, $Type, $Dir, $File) {
  $Text = $Change + "*" + $Type + "*" + $Dir
  If ($Type -eq "F") {
    If ($Dir -eq "") {
      $Text += $File }
    Else {
      $Text += "\" + $File } }

  If ($Log.OutputQty -eq 0) {
    $Log.OutputQty = 1
    $Log.Output = $Text
    return }

  $Log.OutputQty++
  $Log.Output += "`r`n" + $Text
}


function Log_FileName($Dir, $File) {
  If ($Dir -eq "") {
    return $File }
  return ($Dir + "\" + $File)
}


function Log_SkipDirectory($Log) {
  $SkipDir = $Log.Dir
  while ($Log.Open -eq $true -And $Log.Dir.StartsWith($SkipDir)) {
    Log_Read($Log) }
}


function Log_Compare($Old, $New) {

# Old is Deleted files at end of directory or deleted directory

  If ($New.Open -eq $false -Or ($Old.Open -eq $true -and $Old.Dir -lt $New.Dir)) {
    If ($Old.Type -eq "F") {
      Log_Output $New "D" "F" $Old.Dir $Old.File
      Log_Read $Old }
    Else {
      Log_Output $New "D" "D" $Old.Dir
      Log_SkipDirectory $Old }
    return }

# New is New files at end of directory or a new directory and its files

  If ($Old.Open -eq $false -or ($New.Open -eq $true -and $New.Dir -lt $Old.Dir)) {
    If ($New.Type -eq "F") {
      Log_Output $New "N" "F" $New.Dir $New.File }
    Else {
      Log_Output $New "N" "D" $New.Dir }
    Log_Read $New
    return }

# Is for same directory

  If ($Old.Type -ne $New.Type) {
    throw ("Directory Mismatch '" + $Old.Type + ":" + $Old.Dir + ":" + $Old.File + "' and '" + $New.Type + ":" + $New.Dir + ":" + $New.File + "'") }

  If ($Old.Type -eq "D") {
    Log_Read $Old
    Log_Read $New
    return }

  If ($Old.File -eq $New.File) {
    $TimeDiff = ($Old.Date - $New.Date).TotalSeconds
    If (-NOT($Old.Len -eq $New.Len -AND $TimeDiff -lt 3 -AND $TimeDiff -gt -3)) {
      Log_Output $New "M" "F" $Old.Dir $Old.File }
    Log_Read $Old
    Log_Read $New
    return }

  If ($Old.File -lt $New.File) {
    Log_Output $New "D" "F" $Old.Dir $Old.File
    Log_Read $Old }
  Else {
    Log_Output $New "N" "F" $New.Dir $New.File
    Log_Read $New }
}



function Log_Compare_Old($Old, $New) {

# Past end of Old  

  If ($Old.Open -eq $false) {
    If ($New.Open -eq $false) {
      return }
    If ($New.Type -eq "D") {
      Log_Output $New "N" "D" $New.Dir
#     do {
#       Log_Read $New } until ($New.Open -eq $false -OR $New.Type -eq "D")
      Log_Read $New
      return }
    Log_Output $New "N" "F" $New.Dir $New.File
    Log_Read $New
    return }

# Past end of New 

  If ($New.Open -eq $false) {
    If ($Old.Type -eq "D") {
      Log_Output $New "D" "D" $Old.Dir
      do {
        Log_Read $Old } until ($Old.Open -eq $false -OR $Old.Type -eq "D")
      return }
    Log_Output $New "D" "F" $Old.Dir $Old.File
    Log_Read $Old
    return }

#     Old is a Directory

  If($Old.Type -eq "D") {
    If ($New.Type -eq "D") {
      If ($Old.Dir -eq $New.Dir) {
        Log_Read $Old
        Log_Read $New
        return }
      If ($Old.Dir -lt $New.Dir) {
        Log_Output $New "D" "D" $Old.Dir
        do {
          Log_Read $Old } until ($Old.Open -eq $false -OR $Old.Type -eq "D")
        return }
      Log_Output $New "N" "D" $New.Dir
      do {
        Log_Read $New
        If ($New.Type -eq "F") {
          Log_Output $New "N" "F" $New.Dir $New.File } } until ($New.Open -eq $false -OR $New.Type -eq "D")
      return }
    else {
      If (-NOT($Old.Dir -gt $New.Dir)) {
        Log_Close $Old
        Log_Close $New
        throw ("FileLogCompare: Directory Mismatch '" + $Old.Dir + "' and '" + $New.Dir + "' on new file '" + $New.File + "'") }
      Log_Output $New "N" "F" $New.Dir $New.File
      Log_Read $New
      return } }

#     Old is a File

  If ($New.Type -eq "D") {
    If (-NOT($New.Dir -gt $Old.Dir)) {
      Log_Close $Old
      Log_Close $New
      throw ("FileLogCompare: Directory Mismatch '" + $Old.Dir + "' and '" + $New.Dir + "' on old file '" + $Old.File + "'") }
    Log_Output $New "D" "F" $Old.Dir $Old.File
    Log_Read $Old
    return }

  If ($Old.File -eq $New.File) {
    $TimeDiff = ($Old.Date - $New.Date).TotalSeconds
    If (-NOT($Old.Len -eq $New.Len -AND $TimeDiff -lt 3 -AND $TimeDiff -gt -3)) {
      Log_Output $New "M" "F" $Old.Dir $Old.File }
    Log_Read $Old
    Log_Read $New
    return }

  If ($Old.File -lt $New.File) {
    Log_Output $New "D" "F" $Old.Dir $Old.File
    Log_Read $Old
    return }
          
  Log_Output $New "N" "F" $New.Dir $New.File
  Log_Read $New
}


try {
  If (($OldLog -eq $null -AND $OldBackup -eq $null) -OR $NewLog -eq $null) {
    throw "Must provide NewLog and either OldLog or OldBackup parameters" }

  $LogClass = @{ Open = $false; Stream = $null; LineNo = 0; Type = ""; Dir = ""; File = ""; Len = 0; Date = $null; OutputLog = $null; OutputQty = 0; Output = ""; IsZip = $false; Zip = $null; ZipEntry = $null ; ZipEntryStream = $null }

  $Old = New-Object psobject -Property $LogClass
  $New = New-Object psobject -Property $LogClass

  If ($OldLog -eq $null) {
    Log_OpenFromBackup $Old $OldBackup }
  Else {
    Log_Open $Old $OldLog }
  Log_Open $New $NewLog

  If ($LogFile -ne $null) {
    $null = New-Item -ItemType "file" -Path $LogFile
    $New.OutputLog = $LogFile }

  while ($Old.Open -eq $true -OR $New.Open -eq $true) {
    Log_Compare $Old $New }

  Log_ShowOutput $New }
catch {
  $ErrMsg = $_.Exception.Message
  try {
    If ($Old.Open -eq $true) {
      Log_Close $Old } } catch {}
  try {
    If ($New.Open -eq $true) {
      Log_Close $New } } catch {}
  throw "FileLogCompare: " + $ErrMsg }


# ./FileLogCompare.ps1 -OldLog E:\MyDocz\FileBackup\Store\Backup_TestGroup_Initial.log -NewLog E:\MyDocz\FileBackup\Store\Backup_TestGroup_Test.log -LogFile E:\MyDocz\FileBackup\Store\Backup_TestGroup_Test.dif
# ./FileLogCompare.ps1 -OldLog E:\MyDocz\FileBackup\Store\Backup_TestGroup_Initial.log -NewLog E:\MyDocz\FileBackup\Store\Duplicate_TestGroup.log -LogFile E:\MyDocz\FileBackup\Store\Duplicate_TestGroup.dif

# ./FileLogCompare.ps1 -OldLog E:\Backups\BBHWebSite\Shindig_BBHWebSite_Initial.log -NewLog E:\Backups\BBHWebSite\Backup_BBHWebSite_initial.log -LogFile E:\Backups\BBHWebSite\Backup_BBHWebSite_Compare.log
# ./FileLogCompare.ps1 -OldLog E:\Backups\Camera\Backup_Camera_Initial.log -NewLog E:\Backups\Camera\Shindig_Camera_initial.log -LogFile E:\Backups\Camera\Backup_Camera_Compare.log
