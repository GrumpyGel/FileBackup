# FileBackup Tutorial

This tutorial takes you through the processes of setting up FileBackup and making an initial backup and then unpacking those changes into a duplicate structure.  This covers the basics of FileBackup and how it operates.

It then moves on to implementing a practical Backup and Unpack process for ongoing backups.


## Table of Contents

Setting up FileBackup and making an initial backup and then unpacking those changes into a duplicate structure.

<ul>
  <li><a href="#1-prepare-filebackup">1. Prepare FileBackup</a></li>
  <li><a href="#2-create-initial-log-file">2. Create Initial Log file</a></li>
  <li><a href="#3-ensure-duplicate-is-up-to-date">3. Ensure Duplicate is up-to-date</a></li>
  <li><a href="#4-show-filecompare-detecting-changes">4. Show FileCompare detecting changes</a></li>
  <li><a href="#5-create-a-backup">5. Create a BackUp</a></li>
  <li><a href="#6-unpack-backup-into-duplicate">6. UnPack BackUp into Duplicate</a></li>
</ul>

Implementing a practical Backup and Unpack process

<ul>
  <li><a href="#create-an-initial-log-file">Create an Initial Log file</a></li>
  <li><a href="#installation--usage">Installation &amp; Usage</a></li>
  <li><a href="#documentation">Documentation</a></li>
  <li><a href="#license">License</a></li>
  <li><a href="#contact">Contact</a></li>
  <li><a href="#acknowledgements">Acknowledgements</a></li>
</ul>


## 1. Prepare FileBackup

The first step is to download and install FileBackup.  See intructions at [https://github.com/GrumpyGel/FileBackup](https://github.com/GrumpyGel/FileBackup).

This tutorial assumes that FileBackup has been installed in a directory "E:\\FileBackup". If installed in a different directory, modify the insructions as appropriate.

The directory "E:\\FileBackup\\TestGroup\\Master" contains a set of files that we will use for this tutorial and will be our Group that we are to back up.

To prepare for the tutorial perform the following:

<ol>
  <li>Copy the "E:\FileBackup\TestGroup\Master" directory to "E:\FileBackup\TestGroup\Live" - the 'Live' directory then becomes our Group that we are to backup.</li>
  <li>Make a directory "E:\FileBackup\TestGroup\Store" - this will be the Store directory where backups are created/held.</li>
  <li>Copy the "E:\FileBackup\TestGroup\Live" directory to "E:\FileBackup\TestGroup\Duplicate" - the 'Duplicate' directory then becomes our Duplicate that we will replicate Live into.  Normally this would be on a different disk or server.</li>
  <li>Make a directory "E:\FileBackup\TestGroup\Archive" - this will be the ArchiveStore where replaced/removed files from the Duplicate are placed when backups are unpacked into the Duplicate.</li>
</ol>

When implementing FileBackup in a live environment, the first step above would not need to be performed - you already have the Group you wish to back up.  The remaining steps would need to be taken though so that you have an environment for FileBackup to operate within.

  
## 2. Create Initial Log file

To initiate a FileBackup process, an "Initial" Log file must be created.  This is the "known state" before your incremental backups begin.  It is performed as follows:

```
E:\FileBackup\Bin\FileLog.ps1 -Path E:\FileBackup\TestGroup\Live -LogFile E:\FileBackup\Store\Backup_TestGroup_Initial.log -Ignore "Temp"
```

This creates the Initial Log file for the Group of files residing in the 'Live' directory. We are ignoring the Temp directory as this will contain work files not needed to be BackedUp. The created Log file will list all directories and folders in Live and should look as follows:

```
D*
F*default.aspx*687*20210526134806
F*mydocz.css*102*20210526134823
F*mydocz.js*82*20210526134857
D*images
F*RegentStreet_1.jpg*47492*20200821172137
F*SudokuScreen.png*16770*20201022151135
D*images\Template
F*LogoMyDocz.jpg*25469*20210223114527
```

The date and time stamp will look different as these will be as when you downloaded the repository.

When implementing in a Live environment, you would need to perform this step.


## 3. Ensure Duplicate is up-to-date

If using FileBackup and FileUnpack to maintain a complete up-to-date Duplicate directory for the Group, the Duplicate must be identical to the main Group directory before initiating the first BackUp.

We can check this by creating a Log of the Duplicate and then running FileCompare to compare it against the Initial Log created above. This is performed as follows: 
  
```
E:\FileBackup\Bin\FileLog.ps1 -Path E:\FileBackup\TestGroup\Duplicate -LogFile E:\FileBackup\Store\Duplicate_TestGroup.log -Ignore "Temp"
E:\FileBackup\Bin\FileLogCompare.ps1 -OldLog E:\FileBackup\Store\Backup_TestGroup_Initial.log -NewLog E:\FileBackup\Store\Duplicate_TestGroup.log -LogFile E:\FileBackup\Store\Duplicate_TestGroup.dif
```

In the Store directory, this will create the Log file Duplicate_TestGroup.log and the Differences file Duplicate_TestGroup.dif. The Differences file should be 0 btyes long indicating there are no differences between the logs.

You can deleted the Duplicate_TestGroup.log and Duplicate_TestGroup.dif files to tidy up the Store directory.

When implementing in a Live environment, you should perform this step to ensure you have the environment set up correctly.

  
## 4. Show FileCompare detecting changes

To show FileCompare detecting changes we can modify a file, produce a new Log file and create a Differences file for this new Log against the Initial.
  
This also demonstrates how changes are found and provides changes for the FileBackup tutorial below to process.

In the "E:\\FileBackup\\TestGroup\\Live directory is a file called default.aspx. Load this file into a text editor (for example Notepad) edit it in some way (it does not matter what the change is) and save the file. Now that it has been changed, performed the following:

```
E:\FileBackup\Bin\FileLog.ps1 -Path E:\FileBackup\TestGroup\Live -LogFile E:\FileBackup\Store\Test_TestGroup.log -Ignore "Temp"
E:\FileBackup\Bin\FileLogCompare.ps1 -OldLog E:\FileBackup\Store\Backup_TestGroup_Initial.log -NewLog E:\FileBackup\Store\Test_TestGroup.log -LogFile E:\FileBackup\Store\Test_TestGroup.dif
```

In the Store directory, this will create the Log file Test_TestGroup.log and the Differences file Test_TestGroup.dif. The content of the Differences file should show the modified default.aspx file as follows:

```
M*F*default.aspx
```
  
You can delete the Test_TestGroup.log and Test_TestGroup.dif files to tidy up the Store directory.

When implementing in a Live environment, you should perform this step so that you can subsequently ensure the backup is working correctly.

  
## 5. Create a BackUp

Having made the above change to a file, we can now create a BackUp of it using the following command:

```
E:\FileBackup\Bin\FileBackup.ps1 -Store E:\FileBackup\Store -Name TestGroup -Path E:\FileBackup\TestGroup\Live -Ignore "Temp"
```

As there is no previous Backup file to extract a Log file from, the FileBackup process will read the Backup_TestGroup_Initial.log file we created above to compare to and looks for changes.  The above command should return the following message:

```
FileBackup: TestGroup Backup complete E:\FileBackup\Store\Backup_TestGroup_{TimeStamp}.zip
```

In the Store directory, this will create the BackUp file named Backup_TestGroup_{TimeStamp}.zip. If you open this compressed folder, you will see it contains 3 files:

```
Backup_TestGroup_{TimeStamp}.dif
Backup_TestGroup_{TimeStamp}.log
default.aspx
```

These files are the BackUp Differences and Log files together with the modified default.aspx file.

The Initial Log file created above in the Store will also have been renamed from Backup_TestGroup_Initial.log to Backup_TestGroup_Original.log.

When implementing in a Live environment, this will be your first 'real' backup.  You can add this command to a Task Scheduler process to regularly backup your Group.  However, you may wish to include other options - such as uploading to an FTP server or as running as part of a FileBackupBatch to include other Groups and/or email confirmation.


## 6. UnPack BackUp into Duplicate

Having created the BackUp, we can now UnPack it into the Duplicate.  This will maintain it in sync with the Live Group, as follows:

```
E:\FileBackup\Bin\FileUnpack.ps1 -Store E:\FileBackup\Store -Backup Backup_TestGroup_{TimeStamp}.zip -Duplicate E:\FileBackup\TestGroup\Duplicate -ArchiveStore E:\FileBackup\TestGroup\ArchiveStore
```

Replace {TimeStamp} with the name generated by the BackUp above. The above command should return the following message:

```
FileUnpack: Backup_TestGroup_{TimeStamp}.zip unpack complete
```

The default.aspx file in the Duplicate directory should now match the change made in the Live directory.

In the ArchiveStore directory (E:\\FileBackup\\TestGroup\\ArchiveStore) an Archive named Archive_{TimeStamp} will have been created. This will contain the default.aspx file that was overwritten in the Duplicate directory.

In the Store directory (E:\\FileBackup\\Store) the BackUp file Backup_TestGroup_{TimeStamp}.zip will have been renamed Backup_TestGroup_Unpacked_{TimeStamp}.zip.


## 7. Create a BackUp Batch

A live implementation is likely to be a BackUp Batch.  This allows us to easily configure FTP, BackUp multiple Groups and send a confirmation e-Mails of the BackUp's results.

The command executed below can be added to Task Scheduler to create an ongoing backup of 1 or more Groups.  Multiple tasks can also be created if Groups are to be backed up independently, for example they are to be backed up at different times.

Our tutorial will perform the same backup as the "5. Create a Backup" step above.  It will also FTP the backup onto another server and send an email notification. It assumes you have run the above steps so that you have made an Initial log, made sure the Duplicate.  If you have run a previous backup, that is fine, this will simply add incremental backups to it.

Create a file "MyBackup.cfg" in the E:\FileBackup\TestGroup directory and paste the following as its content...

```
Email = filebackup@mydocz.com*admin@mydocz.com*services.mydocz.com
EmailCredentials = filebackup@mydocz.com*EmailPassword
EmailSSLPort = 587
Ftp = backup.mydocz.com*filebackup*FtpPassword*
Store = E:\FileBackup\Store
Group = TestGroup*E:\FileBackup\TestGroup\Live*Temp
```

If you do not wish the send email notification, remove the 3 lines beginning "Email", otherwise... Set the email From address, To address and SMTP server name on the line beginning "Email =".  Set the email server login user name and password on the line beginning "EmailCredentials =" and the SSL port to use on the line beginning "EmailSSLPort =".

If you do not have an FTP server to upload the backups to, remove the line beginning "Ftp = ".  If you do have an FTP server, change "backup.mydocz.com" to the host name or IP address for it.  I have created a login on my FTP server under the user name "filebackup" which has its root directory set to the Store on the remote host.  Therefore no directory is set in the "Ftp = " line, if your Store directory is not the root of the login, it should be included at the end of the line, after the last '*'.  Change the username and password appropriate to your server.

As stated, this will perform the same backup as used previously, therefore the Store is set to E:\FileBackup\Store, we give it a name of "TestGroup", it is backing up the contents of the E:\FileBackup\TestGroup\Live directory but ignoring the Temp subdirectory.  In live implementation, change these as appropriate.

The BackupBatch can be executed with the following command:

```
E:\FileBackup\bin\FileBackupBatch.ps1 -Config E:\FileBackup\TestGroup\MyBackup.cfg
```

As we have not made any changes since the previous backup, no backup file should be created and the command should display the following results:

```
FileBackup: TestGroup No changes to files
FileBackupBatch: Process complete
```

If an email was configured to be sent, one should be received as follows:

```
Subject : FileBackupBatch Processing

FileBackup: TestGroup No changes to files
FileBackupBatch: Process complete
```

We can then make a change to a file and test a backup being created.  Modify the E:\FileBackup\TestGroup\Live\default.aspx file again (for example add a blank line and save the file) and then reissue the above command.  This time, a backup file should be created in the Store and uploaded to the FTP server store if configured.  The command should display the following results:

```
FileBackup: TestGroup Backup complete and uploaded E:\FileBackup\TestGroup\Store\Backup_TestGroup_{TimeStamp}.zip
FileBackupBatch: Process complete
```

If an email was configured to be sent, one should be received as follows:

```
Subject : FileBackupBatch Processing

FileBackup: TestGroup Backup complete and uploaded E:\MyDocz\FileBackup\TestGroup\Store\Backup_TestGroup_{TimeStamp}.zip
FileBackupBatch: Process complete
```

If a live implementation is backing up multiple Groups, the following Config file shows multiple Groups (TestGroup and AppNo2) being backed up into the same Store (Store):

```
Email = filebackup@mydocz.com*admin@mydocz.com*services.mydocz.com
EmailCredentials = filebackup@mydocz.com*EmailPassword
EmailSSLPort = 587
Ftp = backup.mydocz.com*filebackup*FtpPassword*
Store = E:\FileBackup\Store
Group = TestGroup*E:\FileBackup\TestGroup\Live*Temp
Group = AppNo2*E:\AppNo2Dir*
```

The following shows multiple Groups (TestGroup and AppNo2) being backed up into different Stores (StoreTestGroup and StoreAppNo2):

```
Email = filebackup@mydocz.com*admin@mydocz.com*services.mydocz.com
EmailCredentials = filebackup@mydocz.com*EmailPassword
EmailSSLPort = 587
Ftp = backup.mydocz.com*filebackup*FtpPassword*StoreTestGroup
Store = E:\FileBackup\StoreTestGroup
Group = TestGroup*E:\FileBackup\TestGroup\Live*Temp
Ftp = backup.mydocz.com*filebackup*FtpPassword*StoreAppNo2
Store = E:\FileBackup\StoreAppno2
Group = AppNo2*E:\AppNo2Dir*
```





