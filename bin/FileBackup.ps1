param ($Store, $Name, $Path, $FtpHost, $FtpUser, $FtpPassword, $FtpPath, $Ignore)

#   Store = Location to create logs, eg "E:\MyDocz\FileBackup\Store"
#   Name = Name of file group, eg "SiteNet"
#   Path = Folder containing file to log, eg "E:\Web\wwwroot\SiteNet"
#   FtpHost = Host name to upload a copy of the backup to, eg "192.168.1.1"
#   FtpUser = Ftp Login User name
#   FtpPassword = Ftp Login Password
#   FtpPath = Path on Ftp Server to upload backup to, eg "Backups"
#   Ignore = List of Folders, separated by ; to ignore and not add to log eg "Temp;Work\Old;Work\Temp"

#   Currently included log file in Backup Zip.  This adds to Ftp Upload and not really required on uploaded server.
#   So should it be included?
#   As it and the Dif log are included in Backup Zip, should it be deleted afterwards and subsequent backups extract it from Zip?


function AbortRun() {
  try { $DifStream.Close() } catch {}
  try { $Zip.Dispose() } catch {}
  try { If (Test-Path $TempLogFileFull) { Remove-Item $TempLogFileFull } } catch {}
  try { If (Test-Path $TempDifFileFull) { Remove-Item $TempDifFileFull } } catch {}
  try { If (Test-Path $TempZipFileFull) { Remove-Item $TempZipFileFull } } catch {}
}


try {
  If ($Store -eq $null -OR $Name -eq $null -OR $Path -eq $null) {
    throw "Must provide Store, Name and Path parameters" }

  If ($FtpHost -ne $null) {
    If ($FtpUser -eq $null -OR $FtpPassword -eq $null) {
      throw "Must provide FtpUser and FtpPassword parameters if FtpHost specified" } }

  If (!(Test-Path $Store -PathType Container)) {
    throw "Store folder not found - " + $Store }

  $Now = (Get-Date).ToString("yyyyMMddHHmm")
  $FileID = $Name + "_" + $Now

  $TempLogFile = "Temp_" + $FileID + ".log"
  $TempDifFile = "Temp_" + $FileID + ".dif"
  $TempZipFile = "Temp_" + $FileID + ".zip"
  $TempLogFileFull = $Store + "\" + $TempLogFile
  $TempDifFileFull = $Store + "\" + $TempDifFile
  $TempZipFileFull = $Store + "\" + $TempZipFile

  $LogFile = "Backup_" + $FileID + ".log"
  $DifFile = "Backup_" + $FileID + ".dif"
  $ZipFile = "Backup_" + $FileID + ".zip"
  $LogFileFull = $Store + "\" + $LogFile
  $DifFileFull = $Store + "\" + $DifFile
  $ZipFileFull = $Store + "\" + $ZipFile

  $UsingInitial = $false
  $RenameError = $false
  $Response = "FileBackup: " + $Name + " Backup complete " + $ZipFileFull

  $OldFiles = get-childitem -Path ($Store + "\" + "Backup_" + $Name + "_*.zip") -File | Sort LastWriteTime  -Descending
  If ($OldFiles.Length -eq 0) {
    $UsingInitial = $true
    $OldName = "Backup_" + $Name + "_Initial.log"
    $OldLog = $Store + "\" + $OldName
    If ((Test-Path $OldLog) -eq $false) {
      throw "No previous backup found" } }
  Else {
    $OldName = $OldFiles[0].Name
    $OldLog = $OldFiles[0].FullName }

  If (Test-Path $LogFileFull) {
    throw "Log File '" + $LogFile + "' already exists" }
  If (Test-Path $TempLogFileFull) {
    throw "Temporary Log File '" + $TempLogFile + "' already exists" } }
catch {
  throw ("FileBackup: " + $Name + " Failed initialisation, Error = " + $_.Exception.Message) }


try {
  & ($PSScriptRoot + "\FileLog.ps1") -Path $Path -LogFile $TempLogFileFull -Ignore $Ignore
  If ($UsingInitial -eq $true) {
    & ($PSScriptRoot + "\FileLogCompare.ps1") -OldLog $OldLog -NewLog $TempLogFileFull -LogFile $TempDifFileFull }
  Else {
    & ($PSScriptRoot + "\FileLogCompare.ps1") -OldBackup $OldLog -NewLog $TempLogFileFull -LogFile $TempDifFileFull } }
catch {
  $ErrMsg = $_.Exception.Message
  try { AbortRun } catch {}
  throw "FileBackup: " + $Name + " Failed Log processing, Error = " + $ErrMsg }


try {
  Add-Type -As System.IO.Compression.FileSystem
  [System.IO.Compression.CompressionLevel]$Compression = "Optimal"
 
  $Zip = [System.IO.Compression.ZipFile]::Open($TempZipFileFull, "Create")

  $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, $TempLogFileFull, $LogFile, $Compression)
  $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, $TempDifFileFull, $DifFile, $Compression)

  $AnyChanges = $false
  $DifStream = New-Object System.IO.StreamReader($TempDifFileFull)
  while (-NOT($DifStream.EndOfStream)) {
    $AnyChanges = $true
    $Line = $DifStream.ReadLine()
    $Parts = $Line.split("*")
    If ($Parts[0] -ne "D" -AND $Parts[1] -eq "F") {
      $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($Zip, ($Path + "\" + $Parts[2]), $Parts[2], $Compression) } }
  $DifStream.Close()
  $Zip.Dispose()

  Remove-Item $TempLogFileFull
  Remove-Item $TempDifFileFull

  If ($AnyChanges -eq $false) {
    Remove-Item $TempZipFileFull
    write-output ("FileBackup: " + $Name + " No changes to files")
    return } }
catch {
  $ErrMsg = $_.Exception.Message
  try { AbortRun } catch {}
  throw "FileBackup: " + $Name + " Failed creating Backup file, Error = " + $ErrMsg }


try {
  If ($FtpHost -ne $null) {
    $Ftp = New-Object System.Net.WebClient 
    $Ftp.Credentials = New-Object System.Net.NetworkCredential($FtpUser,$FtpPassword)  
    $FtpFilePath = $ZipFile
    If ($FtpPath -ne $null) {
      $FtpFilePath = $FtpPath + "/" + $ZipFile }
    $Uri = New-Object System.Uri("ftp://" + $FtpHost + ":21/" + $FtpFilePath)
    $Ftp.UploadFile($Uri, $TempZipFileFull) } }
catch {
  throw "FileBackup: " + $Name + " Failed uploading backup, Error = " + $_.Exception.Message }


try {
  If ($UsingInitial -eq $true) {
    Rename-Item -Path $OldLog -NewName $OldName.Replace("Initial.", "Original.") } }
  catch { $RenameError = $true }
try { Rename-Item -Path $TempZipFileFull -NewName $ZipFile } catch { $RenameError = $true }
try { If ($FtpHost -ne $null) { $Response = $Response.Replace("Backup complete", "Backup complete and uploaded") } } catch {}
try { If ($RenameError -eq $true) { $Response = $Response + " : *Warning* File renaming failed." } } catch {}

write-output $Response

# Get-Content -Path $LogFile
# write-output ("***")
# Get-Content -Path $DifFile


# ./FileBackup.ps1 -Store E:\MyDocz\FileBackup\Store -Name TestGroup -Path E:\MyDocz\FileBackup\TestGroup\Live -Ignore "Temp"
# ./FileBackup.ps1 -Store E:\MyDocz\FileBackup\Store -Name TestGroup -Path E:\MyDocz\FileBackup\TestGroup\Live -Ignore "Temp" -FtpHost 192.168.1.6 -FtpUser BackupDyn -FtpPassword r=j42uka -FtpPath BackupStore

# ./FileBackup.ps1 -Store E:\Backups -Name BBHWebSite -Path E:\BBH\WebSite -Ignore "WebSiteMedia\Temp;WebSiteLogs\DiscountReminders;WebSiteLogs\ArchiveBookings;WebSiteMedia\BookingArchive"
# ./FileBackup.ps1 -Store E:\Backups -Name Camera -Path E:\Moull\Camera
# ./FileBackup.ps1 -Store E:\Backups -Name SiteNet -Path E:\Web\wwwroot\SiteNet
# ./FileBackup.ps1 -Store E:\Backups -Name SiteNet -Path E:\Web\wwwroot\SiteNet -FtpHost 192.168.1.6 -FtpUser BackupDyn -FtpPassword r=j42uka
