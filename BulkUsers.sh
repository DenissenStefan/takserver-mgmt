#!/bin/bash
# Created by: Stefan
# Created on: 5-10-2022
# Note: this only works when the server certificate name is the same as the hostname

# Files are defined here:
XML_FILE="/opt/tak/CoreConfig.xml"

# Variables below are automatically pulled from the config:
IP=$(<"/opt/tak/certs/ConnectionName.txt")
HostName=$HOSTNAME

if [ $HostName == "localhost.localhost" ]; then
	echo "Hostname not set, please set hostname followed by a reboot of the server."
	exit 1
fi

#This is to remove the trailing space after the variable
IP=`echo $IP | sed -e 's/^[[:space:]]*//'`

# This outputs the CoreConfig node:
CaPass=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='security']/*[local-name()='tls']/@keystorePass" $XML_FILE)
ClientPass=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='security']/*[local-name()='tls']/@truststorePass" $XML_FILE)
intermediateCert=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='certificateSigning']/*[local-name()='TAKServerCAConfig']/@keystoreFile" $XML_FILE)
ServerCert=$(xmllint --xpath "//*[local-name()='Configuration']/*[local-name()='security']/*[local-name()='tls']/@keystoreFile" $XML_FILE)

# This extracts the entry from the CoreConfig node:
CaPass=${CaPass#*'"'}; CaPass=${CaPass%'"'*}
ClientPass=${ClientPass#*'"'}; ClientPass=${ClientPass%'"'*}
ServerCert=${ServerCert#*'"'}; ServerCert=${ServerCert%'"'*}
intermediateCert=${intermediateCert#*'"'}; intermediateCert=${intermediateCert%'"'*}

if

	[ -z "$intermediateCert" ]

then

	TrustStoreCert=$ServerCert
	TrustStoreCert=$(echo $TrustStoreCert | cut -c13- | rev | cut -c5- | rev)
else

	TrustStoreCert=$intermediateCert
	TrustStoreCert=$(echo $TrustStoreCert | cut -c13- | rev | cut -c13- | rev)
	TrustStoreCert="truststore-$TrustStoreCert"
fi

######################################################################

# Create a directory for storage of the user certificates & data-packages
mkdir -p "/opt/takdata/user-certificates"
mkdir -p "/opt/takdata/data-packages"

# Read the header entries from the CSV file
while IFS="," read -r Username Group1 Group2

do

	if
		# Without this the script will skip the last line.
    	[[ $Username != "" ]] ;

	then
		
		# User Certificates
		echo "Creating certificate for $Username"
		/opt/tak/certs/makeCert.sh client $Username

		# Without this wait functions certificate generation won't finish and the certificates won't be usable.
		wait
		
		if
			
			# This checks if CSV entry of group 2 is empty
			[ -z "$Group2" ] ;

		then

			# creating a user account with a single group
			echo "Creating user account for $Username"
			java -jar /opt/tak/utils/UserManager.jar certmod -g $Group1 /opt/tak/certs/files/$Username.pem

			# The same as the wait function before, this makes sure the process will finish before the script continues.
			wait

		else

			# creating a user account with two groups
			echo "Creating user account for $Username"
			java -jar /opt/tak/utils/UserManager.jar certmod -g $Group1 -g $Group2 /opt/tak/certs/files/$Username.pem

			# The same as the wait function before, this makes sure the process will finish before the script continues.
			wait

		fi

		# server.pref

		echo "Creating server.pref file for $Username"

		echo "<?xml version='1.0' encoding='ASCII' standalone='yes'?>" > /opt/tak/certs/server.pref
		echo "<preferences>" >> /opt/tak/certs/server.pref
		echo "  <preference version=\"1\" name=\"cot_streams\">" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"count\" class=\"class java.lang.Integer\">1</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"description0\" class=\"class java.lang.String\">$HostName</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"enabled0\" class=\"class java.lang.Boolean\">true</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"connectString0\" class=\"class java.lang.String\">$IP:8089:ssl</entry>" >> /opt/tak/certs/server.pref
		echo "  </preference>" >> /opt/tak/certs/server.pref
		echo "  <preference version=\"1\" name=\"com.atakmap.app_preferences\">" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"displayServerConnectionWidget\" class=\"class java.lang.Boolean\">true</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"caLocation\" class=\"class java.lang.String\">$TrustStoreCert.p12</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"caPassword\" class=\"class java.lang.String\">$CaPass</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"clientPassword\" class=\"class java.lang.String\">$ClientPass</entry>" >> /opt/tak/certs/server.pref
		echo "    <entry key=\"certificateLocation\" class=\"class java.lang.String\">$Username.p12</entry>" >> /opt/tak/certs/server.pref
		echo "  </preference>" >> /opt/tak/certs/server.pref
		echo "</preferences>" >> /opt/tak/certs/server.pref


		# manifest.xml

		echo "Creating manifest.xml file for $Username"

		echo "<MissionPackageManifest version=\"2\">" > /opt/tak/certs/manifest.xml
		echo "  <Configuration>" >> /opt/tak/certs/manifest.xml
		echo "    <Parameter name=\"uid\" value=\"af6f9606-4e37-4d85-b14e-3d0a99705a9d\"/>" >> /opt/tak/certs/manifest.xml
		echo "    <Parameter name=\"name\" value=\"$HostName\"/>" >> /opt/tak/certs/manifest.xml
		echo "    <Parameter name=\"onReceiveDelete\" value=\"false\"/>" >> /opt/tak/certs/manifest.xml
		echo "  </Configuration>" >> /opt/tak/certs/manifest.xml
		echo "  <Contents>" >> /opt/tak/certs/manifest.xml
		echo "    <Content zipEntry=\"server.pref\" ignore=\"false\" />" >> /opt/tak/certs/manifest.xml
		echo "    <Content zipEntry=\"$TrustStoreCert.p12\" ignore=\"false\" />" >> /opt/tak/certs/manifest.xml
		echo "    <Content zipEntry=\"$Username.p12\" ignore=\"false\" />" >> /opt/tak/certs/manifest.xml
		echo "  </Contents>" >> /opt/tak/certs/manifest.xml
		echo "</MissionPackageManifest>" >> /opt/tak/certs/manifest.xml

		echo "zipping files for $Username"

		# Zip files into a datapackage
		zip -j "/opt/takdata/data-packages/dp-$Username-$HostName.zip" "/opt/tak/certs/manifest.xml" "/opt/tak/certs/server.pref" "/opt/tak/certs/files/$TrustStoreCert.p12" "/opt/tak/certs/files/$Username.p12"

		wait

		# Create a subdirectory for the user certificates
		mkdir -p "/opt/takdata/user-certificates/$Username"

		# This will move all files for the user to the user-certificates folder created above
		find /opt/tak/certs/. -name "$Username*.*" -exec mv '{}' "/opt/takdata/user-certificates/$Username/" \;

		echo "-------------------------------------------------------------"
		echo "Created certificate data package for $Username @ $HostName as takdata/data-packages/dp-$Username-$HostName.zip"

	fi

# This makes sure the script starts from the second line of the CSV file.
done < <(tail -n +2 users.csv)

# Cleanup of server.pref & manifest.xml
rm "/opt/tak/certs/manifest.xml"
rm "/opt/tak/certs/server.pref"

./ManagementConsole.sh