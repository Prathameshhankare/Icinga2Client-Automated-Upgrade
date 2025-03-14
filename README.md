Automated Upgrade Script for Windows Icinga2 Client
================================

Overview
--------

This PowerShell script automates the process of checking, uninstalling, downloading, and installing the Icinga2 client on remote machines. It ensures that all target machines have the latest version (2.14.3) installed, logs execution details, and exports results to a CSV file.

Features
--------

-   Checks if a machine is online.

-   Determines the currently installed Icinga2 version.

-   Checks the Icinga2 service status.

-   Downloads the latest Icinga2 client (2.14.3).

-   Uninstalls any existing Icinga2 version if necessary.

-   Installs the latest Icinga2 version.

-   Logs all actions to a log file.

-   Exports a detailed report to a CSV file.

Prerequisites
-------------

-   PowerShell must be run as an Administrator.

-   The script should be executed from a system with network access to all target machines.

-   Active Directory module (if using AD-based machine discovery).

Usage
-----

### 1\. Running the Script

The script can be executed with a PowerShell terminal using the following command:

```
powershell -ExecutionPolicy Bypass -File .\Icinga2_Upgrade.ps1
```

### 2\. Expected Output

After execution, the following files will be generated:

-   **Log File:** `C:\Icinga2_Update_Log.txt` (Contains detailed logs of script execution)

-   **CSV Report:** `C:\Icinga2_Update_Report.csv` (Summary of actions taken for each machine)

### 2.1\. Example Log File (C:\Icinga2_Update_Log.txt):
```text
[2025-03-14 12:00:00] Fetched Machines: XXSUPXX01
[2025-03-14 12:00:05] Processing Machine: XXSUPXX01
[2025-03-14 12:00:06] XXSUPXX01 is Live
[2025-03-14 12:00:08] INFO: XXSUPXX01 - Icinga2 Version: 2.14.2
[2025-03-14 12:00:10] INFO: XXSUPXX01 - Icinga2 Service Status: Running
[2025-03-14 12:00:12] INFO: Attempting to Uninstall Icinga2 Client
[2025-03-14 12:00:20] XXSUPXX01 - Uninstall Status: Previously installed Icinga2 client uninstalled
[2025-03-14 12:00:25] XXSUPXX01 - New Icinga2 Client Download Status: Success
[2025-03-14 12:01:00] XXSUPXX01 - Install Status: Installed
```
### 2.2\. Example CSV Report (C:\Icinga2_Update_Report.csv):
```csv
MachineName,Status,Icinga2Version,Icinga2Service,DownloadStatus,UninstallStatus,Icinga2Client2143
XXSUPXX01,Live,2.14.2,Running,Success,Previously installed Icinga2 client uninstalled,Installed
```

Script Workflow
---------------

1.  Fetches the list of target machines (currently hardcoded to use AD queries but can be modified).

2.  For each machine:

    -   Checks if it is online.

    -   Retrieves the installed Icinga2 version and service status.

    -   If Icinga2 is not installed, or an outdated version is detected, proceeds with uninstallation.

    -   Downloads the latest Icinga2 client installer.

    -   Installs the Icinga2 client.

    -   Logs results to CSV.

Customization
-------------

-   **Modifying Target Machines:**

    -   To scan multiple machines, modify:

        ```
        $Machines = Get-ADComputer -Filter {Name -like "*SUP*"} | Select-Object -ExpandProperty Name
        ```

-   **Changing the Icinga2 Version:**

    -   Update the `Download-Icinga2` function with the latest URL.

    -   Modify the version check comparison.

License
-------

This project is open-source and available under the MIT License.

Author
------

Developed by **Prathamesh Hankare**.
