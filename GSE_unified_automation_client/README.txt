Welcome to use the GSE Unified Automation Client.
First, you need to install the InnoSetup on your computer. It's a free installer for Windows programs.
You can download it from-- http://www.jrsoftware.org/download.php/is-unicode.exe?site=1

When you have installed Inno Setup then you can get started with the GSE Unified Automation.

1.Open "GSE_unified_automation_client.iss" with Inno Setup.

2.Turn to line 9th and configure your current folder path.
For example, if you clone the files to your Desktop, you need to modify this line into
#define MyAppPath "C:\Users\YourName\Desktop\GSE_unified_automation_client"  where "YourName" is your computer name.

3.Click Project--> Compile to compile the source file.

4.The "GSE_unified_automation_client_v1.0.0.exe" will be generated in current folder.

5.Just Run the .exe and input configurations as shows in the dialog.

Then the deployment will automatically run.