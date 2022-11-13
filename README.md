# Bulk initial config script

This script is meant to create data packages on the TAKserver for initial configuration of connected devices.

# Usage
Copy the script to the `/opt/tak/certs` folder on the takserver (ensure you have execute permissions on the script)
Run the script by entering `.\bulk-client-certificates.sh` as the tak user (`sudo su tak`)

# Changelog:

05-10-2022: Built first script to generate bulk user certificates
21-10-2022: Added parts of [Cloud-RF datapackage script](https://github.com/Cloud-RF/tak-server/blob/main/scripts/certDP.sh) to bulk generate data packages with connection details for the TAK server. Also added a part for user generation.
22-10-2022: Added a feature where the user is automatticaly added to a group instead of the default `__ANON__` group.
23-10-2022: Added Hostname variable for the takserver name and pull IP Address from hostname
27-10-2022: Created separate folders for user certificates en data packages.
28-10-2022: Changed the user creation from flat file to certificate based
08-11-2022: Changed the user-certificate and datapackage folder locations.
13-11-2022: Added XML parsing from the CoreConfig file.

# Future features
- Parse CSV for Username, group(s) & EUD
- Build option for multiple groups
- Build option for difference in ATAK/WINTAK
- Add TAKchat plugin to data package
- Configure TAKchat plugin
- Separate package for certificate enrollment