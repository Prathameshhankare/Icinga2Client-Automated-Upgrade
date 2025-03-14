Icinga2 Automated Upgrade Script
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

-   Ensure that WinRM is enabled on remote machines.

-   The script should be executed from a system with network access to all target machines.

-   Active Directory module (if using AD-based machine discovery).

Usage
-----

### 1\. Running the Script

The script can be executed with a PowerShell terminal using the following command:

```
powershell -ExecutionPolicy Bypass -File .\Icinga2_Upgrade.ps1
```

### 2\. Parameters

| Parameter | Description |
| `CsvFilePath` | (Optional) Path to the output CSV file. Default: `C:\Icinga2_Update_Report.csv`. |

### 3\. Expected Output

After execution, the following files will be generated:

-   **Log File:** `C:\Icinga2_Update_Log.txt` (Contains detailed logs of script execution)

-   **CSV Report:** `C:\Icinga2_Update_Report.csv` (Summary of actions taken for each machine)

Script Workflow
---------------

1.  Fetches the list of target machines (currently hardcoded but can be modified to use AD queries).

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

    -   The script currently processes a single machine (`INSUPLTITPH`).

    -   To scan multiple machines, modify:

        ```
        $Machines = Get-ADComputer -Filter {Name -like "*SUP*"} | Select-Object -ExpandProperty Name
        ```

-   **Changing the Icinga2 Version:**

    -   Update the `Download-Icinga2` function with the latest URL.

    -   Modify the version check comparison.

Troubleshooting
---------------

| Issue | Possible Cause | Solution |
| Script fails to connect to a machine | WinRM not enabled | Enable WinRM using `Enable-PSRemoting -Force` |
| Uninstall fails | Incorrect registry keys | Manually uninstall Icinga2 and rerun the script |
| Download fails | Network issues | Ensure the system has internet access |
| Installation fails | Corrupt MSI file | Re-download the MSI and rerun the script |

License
-------

This project is open-source and available under the MIT License.

Author
------

Developed by **[Your Name]**.
