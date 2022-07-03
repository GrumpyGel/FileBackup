param ($Store, $Backup, $Duplicate, $ArchiveStore, [Switch] $Verify)

#   Store = Path to Backup file, eg "E:\MyDocz\FileBackup\Store"
#   Backup = Name of Backup file, eg "Backup_TestGroup_20210101.zip"
#   Duplicate = Folder containing Duplicate files, eg "E:\MyDocz\FileBackup\TestGroup\Duplicate"
#   ArchiveStore = Folder containing Archives for this Group overwritten or removed, eg "E:\MyDocz\FileBackup\TestGroup\Archive"
#   Verify = If the Verify flag is set, once unpacked, the Duplicate will be Verified to match the BackUp Log

#  Everything is alphabetic order, so problems should not occur, but there may be manual changes or
#  previous aborted runs that can leave files or already place files into archives.
#  Therefore an aborted run can duplicate things, restarts (archive already exists) will always create a new archive.

$Archive = ""
$ArchiveFull = ""

function CheckDirectory($Name, $MoveToArchive, $Create) {

#  $Name : Name of directory in Duplicate to check.
#  $MoveToArchive : If found in Duplicate then move to Archive, for example if Directory is to be deleted.
#  $Create : If directory not found in Dupicate then create, for example a new Directory or to contain New/modified File (although directory should already exist).

# Skip if root of content.

  If ($Name -eq "") {
    return }

# Check if file exists with this name, if it does, move to it to Archive.

  If (Test-Path ($Duplicate + "\" + $Name) -PathType Leaf) {
    $ArchiveLoc = Split-Path -Path ($script:ArchiveFull + "\" + $Name) -Parent
    If ((Test-Path $ArchiveLoc) -eq $false) {
      $null = New-Item $ArchiveLoc -ItemType Directory }
    If (Test-Path ($ArchiveFull + "\" + $Name)) {
      throw ("Moving unexpected file, already exists in Archive - " + $ArchiveFull + "\" + $Name) }
    $null = Move-Item -Path ($Duplicate + "\" + $Name) -Destination $ArchiveLoc }

# Check if directory exists

  If (Test-Path ($Duplicate + "\" + $Name) -PathType Container) {
    If ($MoveToArchive -eq $true) {
      $ArchiveLoc = Split-Path -Path ($ArchiveFull + "\" + $Name) -Parent
      If ((Test-Path $ArchiveLoc) -eq $false) {
        $null = New-Item $ArchiveLoc -ItemType Directory }
      If (Test-Path ($ArchiveFull + "\" + $Name)) {
        throw ("Moving Directory, already exists in Archive - " + $ArchiveFull + "\" + $Name) }
      Move-Item -Path ($Duplicate + "\" + $Name) -Destination $ArchiveLoc
      If ($Create -eq $true) {
        $null = New-Item ($Duplicate + "\" + $Name) -ItemType Directory } }
    return }

  If ($Create -eq $true) {
    $null = New-Item ($Duplicate + "\" + $Name) -ItemType Directory }
}


try {
  If ($Store -eq $null -OR $Backup -eq $null -OR $Duplicate -eq $null -OR $Archive -eq $null) {
    throw "Must provide Store, Backup, Duplicate and Archive parameters" }

  $BackupFull = $Store + "\" +$Backup
  $DifFile = $Backup.replace(".zip", ".dif")
  $UnpackedName = ""
  $UnpackedFull = ""
  $AnyChanges = $false
  $Response = "FileUnpack: " + $Backup + " unpack complete"

  If (!(Test-Path $Store)) {
    throw "Store '" + $Store + "' not found" }
  If (!(Test-Path $BackupFull)) {
    throw "Backup file '" + $BackupFull + "' not found" }
  If (!(Test-Path $Duplicate)) {
    throw "Duplicate '" + $Duplicate + "' not found" }
  If (!(Test-Path $ArchiveStore)) {
    throw "ArchiveStore '" + $ArchiveStore + "' not found" }

  $PosU = $Backup.LastIndexOf("_")
  $UnpackedName = $Backup.Substring(0, $PosU) + "_Unpacked" + $Backup.Substring($PosU)
  $UnpackedFull = $Store + "\" + $UnpackedName
  $Archive = $Backup.Substring($PosU)
  $Archive = "Archive" + $Archive.Replace(".zip", "")
  $Sub = 0
  while (Test-Path ($ArchiveStore + "\" + $Archive)) {
    If ($Sub -eq 0) {
      $Archive = $Archive + "_2"
      $Sub = 2 }
    else {
      $Sub++
      $Archive = $Archive.Substring(0, $Archive.LastIndexOf("_")) + "_" + $Sub } }
  $null = New-Item -Path $ArchiveStore -Name $Archive -ItemType "directory"
  $ArchiveFull = $ArchiveStore + "\" + $Archive }
catch {
  throw "FileUnpack: " + $Backup + " Failed initialisation, Error = " + $_.Exception.Message }


try {
  Add-Type -As System.IO.Compression.FileSystem
# [System.IO.Compression.CompressionLevel]$Compression = "Optimal"
 
  $Zip = [System.IO.Compression.ZipFile]::OpenRead($BackupFull)

  $DifEntry = $Zip.GetEntry($DifFile)
  $DifEntryStream = $DifEntry.Open()
  $DifStream = New-Object System.IO.StreamReader($DifEntryStream)

  while (-NOT($DifStream.EndOfStream)) {
    $AnyChanges = $true
    $Line = $DifStream.ReadLine()
    $Parts = $Line.split("*")
    If ($Parts[1] -eq "D") {
      If ($Parts[0] -eq "N") {
        CheckDirectory $Parts[2] $true $true }
      ElseIf ($Parts[0] -eq "D") {
        CheckDirectory $Parts[2] $true $false }
      Else {
        throw ("Unknown Difference file change type - " + $Parts[0]) }
      Continue }
    If ($Parts[1] -ne "F") {
      throw ("Unknown Difference file item type - " + $Parts[1]) }
    If ($Parts[0] -ne "N" -AND $Parts[0] -ne "M" -AND $Parts[0] -ne "D") {
      throw ("Unknown Difference file change type - " + $Parts[0]) }
    $Sub = $Parts[2].LastIndexOf("\")
    If ($Sub -ne -1) {
      If ($Parts[0] -eq "D") {
        CheckDirectory $Parts[2].Substring(0, $Sub) $false $false }
      Else {
        CheckDirectory $Parts[2].Substring(0, $Sub) $false $true } }
    If (Test-Path ($Duplicate + "\" + $Parts[2])) {
      If ($Sub -ne -1) {
        $ArchiveLoc = Split-Path -Path ($ArchiveFull + "\" + $Parts[2]) -Parent
        If ((Test-Path $ArchiveLoc) -eq $false) {
          $null = New-Item $ArchiveLoc -ItemType Directory } }
      If (Test-Path ($ArchiveFull + "\" + $Parts[2])) {
        throw ("Moving File, already exists in Archive - " + $ArchiveFull + "\" + $Parts[2]) }
      Move-Item -Path ($Duplicate + "\" + $Parts[2]) -Destination ($ArchiveFull + "\" + $Parts[2]) }
    If ($Parts[0] -eq "N" -OR $Parts[0] -eq "M") {
      $Entry = $Zip.GetEntry($Parts[2])
      [System.IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, ($Duplicate + "\" + $Parts[2]), $true) } }
  try { $DifStream.Close() } catch {}
  try { $DifStream.Dispose() } catch {}
  try { $DifEntryStream.Dispose() } catch {}
  try { $Zip.Dispose() } catch {}
  Rename-Item -Path $BackupFull -NewName $UnpackedName

  If ($AnyChanges -eq $false) {
    $Response = "FileUnpack: " + $Backup + " no changes found" } }
catch {
  $ErrMsg = $_.Exception.Message
  try { $DifStream.Close() } catch {}
  try { $DifStream.Dispose() } catch {}
  try { $DifEntryStream.Dispose() } catch {}
  try { $Zip.Dispose() } catch {}
  throw "FileUnpack: " + $Backup + " Failed extracting Backup file, Error = " + $ErrMsg }


try {
  If ($Verify -ne $true) {
    write-output $Response
    return }

  $VerifyLogFile = $Backup.Replace("Backup_", "Verify_").Replace(".zip", ".log")
  $VerifyLogFull = $ArchiveStore + "\" + $VerifyLogFile
  $VerifyDifFile = $VerifyLogFile.Replace(".log", ".dif")
  $VerifyDifFull = $ArchiveStore + "\" + $VerifyDifFile

# Find any Ignore to use.

  $Ignore = ""
  $BackupLogFile = $Backup.Replace(".zip", ".log").Replace("_Unpacked_", "_")
# Add-Type -As System.IO.Compression.FileSystem
# [System.IO.Compression.CompressionLevel]$Compression = "Optimal"
  $Zip = [System.IO.Compression.ZipFile]::OpenRead($UnpackedFull)
  $ZipEntry = $Zip.GetEntry($BackupLogFile)
  $ZipEntryStream = $ZipEntry.Open()
  $Stream = New-Object System.IO.StreamReader($ZipEntryStream)
  $Line = $Stream.ReadLine()
  $Parts = $Line.split("*")
  If ($Parts[0] -eq "I") {
    $Ignore = $Parts[1] }
  try { $Stream.Close() } catch {}
  try { $Stream.Dispose() } catch {}
  try { $ZipEntryStream.Dispose() } catch {}
  try { $Zip.Dispose() } catch {}

  & ($PSScriptRoot + "\FileLog.ps1") -Path $Duplicate -LogFile $VerifyLogFull -Ignore $Ignore

  & ($PSScriptRoot + "\FileLogCompare.ps1") -OldBackup $UnpackedFull -NewLog $VerifyLogFull -LogFile $VerifyDifFull

  Remove-Item $VerifyLogFull
  If ((Get-Item $VerifyDifFull).length -eq 0) {
    Remove-Item $VerifyDifFull
    $Response = $Response + ", Verified OK" }
  Else {
    $Response = $Response + ", Verify Failed " + $VerifyDifFile }

  write-output $Response }
catch {
  $Response = $Response + ", Verify Error : " + $_.Exception.Message
  write-output $Response }


# ./FileUnpack.ps1 -Store E:\MyDocz\FileBackup\Store -Backup Backup_TestGroup_202105211336.zip -Duplicate E:\MyDocz\FileBackup\TestGroup\Duplicate -ArchiveStore E:\MyDocz\FileBackup\TestGroup\ArchiveStore

# ./FileUnpack.ps1 -Store E:\Backups\TestGroup -Backup Backup_TestGroup_202105121515.zip -ContentPath E:\Backups\Temp\TestGroup_Backup -ArchivePath E:\Backups\Temp\TestGroup_Archive
