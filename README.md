# Bulk initial config script

This script is meant to create data packages on the TAKserver for initial configuration of connected devices.

# Usage
Copy the scripts to the `/opt/tak/certs` folder on the takserver (ensure you have execute permissions on the script). Edit the `users.csv` per example with at the end a blank line.
Run the script by entering `.\BulkUsers.sh` in the terminal.

# Changelog:

| Date | Change  |
| --- | --- |
| 05-10-2022 | Built first script to generate bulk user certificates |
| 21-10-2022 | Added parts of [Cloud-RF datapackage script](https://github.com/Cloud-RF/tak-server/blob/main/scripts/certDP.sh) to bulk generate data packages with connection details for the TAK server. Also added a part for user generation. |
| 22-10-2022 | Added a feature where the user is automatticaly added to a group instead of the default `__ANON__` group. |
| 23-10-2022 | Added Hostname variable for the takserver name and pull IP Address from hostname |
| 27-10-2022 | Created separate folders for user certificates en data packages. |
| 28-10-2022 | Changed the user creation from flat file to certificate based |
| 08-11-2022 | Changed the user-certificate and datapackage folder locations. |
| 13-11-2022 | Added XML parsing from the CoreConfig file. |
| 14-11-2022 | Added CSV parsing from users.csv |
| 09-12-2022 | Added a script to set the connection name or IP address to be used in the creation of data packages. |

# Future features
- Add TAKchat plugin to data package
- Configure TAKchat plugin
- Separate package for certificate enrollment