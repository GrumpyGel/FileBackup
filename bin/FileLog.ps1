param ($Path, $LogFile, $Ignore)

#   Path = Folder containing files to log, eg "E:\Web\wwwroot\SiteNet"
#   LogFile = Name of Log file to create, eg "SiteNet.log"
#   Ignore = List of Folders, separated by ; to ignore and not add to log eg "Temp;Work\Old;Work\Temp"


function CreateLog_Directory($LogFile, $IgnoreList, $BaseDir, $FullName) {
  If ($FullName.substring(0, $BaseDir.length) -ne $BaseDir) {
    return }

  $LocalDir = ""
  if ($FullName -ne $BaseDir) {
    $LocalDir = $FullName.substring($BaseDir.length + 1) }

  If ($IgnoreList.contains(";" + $LocalDir + ";")) {
    return; }

  $Log = "D*" + $LocalDir
  $Files = get-childitem -Path $FullName -File | Sort Name
  foreach ($File in $Files) {
    $TimeText = $File.LastWriteTime.ToString("yyyyMMddHHmmss")
    $TimeObj = [DateTime]::ParseExact($TimeText, "yyyyMMddHHmmss", $null)
    $Log += "`r`n" + "F*" + $File.Name + "*" + $File.Length + "*" + $File.LastWriteTime.ToString("yyyyMMddHHmmss") }
  If ($LogFile -eq $null) {
    write-output ($Log) }
  else {
    Add-Content $LogFile $Log }
  $Dirs = get-childitem -Path $FullName -Directory | Sort FullName
  foreach ($Dir in $Dirs) {
    CreateLog_Directory $LogFile $IgnoreList $BaseDir $Dir.FullName }
}


try {
  If ($Path -eq $null) {
    throw "Must provide Path parameter, name of folder to Log" }
  If ((Test-Path -Path $Path -PathType container) -eq $false) {
    throw "Path not found" }

  If ($LogFile -ne $null) {
    $null = New-Item -ItemType "file" -Path $LogFile }

  $IgnoreList = ""
  If ($Ignore -ne $null) {
    $IgnoreLog = "I*" + $Ignore
    If ($LogFile -eq $null) {
      write-output ($IgnoreLog) }
    else {
      Add-Content $LogFile $IgnoreLog }
    $IgnoreList = ";" + $Ignore + ";" }

  CreateLog_Directory $LogFile $IgnoreList $Path $Path }
catch {
  throw "FileLog: " + $_.Exception.Message }


# ./FileLog.ps1 -Path E:\MyDocz\FileBackup\TestGroup\Live -LogFile E:\MyDocz\FileBackup\Store\Backup_TestGroup_Initial.log -Ignore "Temp"
# ./FileLog.ps1 -Path E:\MyDocz\FileBackup\TestGroup\Duplicate -LogFile E:\MyDocz\FileBackup\Store\Duplicate_TestGroup.log -Ignore "Temp"
# ./FileLog.ps1 -Path E:\MyDocz\FileBackup\TestGroup\Live -LogFile E:\MyDocz\FileBackup\Store\Backup_TestGroup_Temp.log -Ignore "Temp"

# ./FileLog.ps1 -Path E:\BBH\WebSite -LogFile E:\Backups\BBHWebSite\Backup_BBHWebSite_Initial.log -Ignore "WebSiteMedia\Temp;WebSiteLogs\DiscountReminders;WebSiteLogs\ArchiveBookings;WebSiteMedia\BookingArchive"
# ./FileLog.ps1 -Path E:\Moull\Camera -LogFile E:\Backups\Camera\Backup_Camera_Initial.log
