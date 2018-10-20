#!/bin/bash

# Comment any download url below to skip install #
PKG_URL="https://go.microsoft.com/fwlink/?linkid=525133"
MAU_URL="https://go.microsoft.com/fwlink/?linkid=830196"
APP_URLS=( \
	# Word 
	"https://go.microsoft.com/fwlink/?linkid=525134" \
	# Excel
	"https://go.microsoft.com/fwlink/?linkid=525135" \
	# Powerpoint
	"https://go.microsoft.com/fwlink/?linkid=525136" \
	# Outlook
	#"https://go.microsoft.com/fwlink/?linkid=525137" \
)

MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
SECOND_MAU_PATH="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app/Contents/MacOS/Microsoft AU Daemon.app"
INSTALLER_TARGET="LocalSystem"

echo "MSOFFICE - Starting Download/Install sequence."

# make it a function
for downloadUrl in "${DOWNLOAD_URLS[@]}"
do
	finalDownloadUrl=$(curl "$downloadUrl" -s -L -I -o /dev/null -w '%{url_effective}')
	pkgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
	pkgPath="/tmp/$pkgName"
	echo "MSOFFICE - Downloading $pkgName"

	# modified to attempt restartable downloads and prevent curl output to stderr
	until curl --retry 1 --retry-max-time 180 --max-time 180 --fail --silent -L -C - "$finalDownloadUrl" -o "$pkgPath"; do
		# Retries if the download takes more than 3 minutes and/or times out/fails
		echo "MSOFFICE - Preparing to re-try failed download: $pkgName"
		sleep 10
	done
	echo "MSOFFICE - Installing $pkgName"
	# run installer with stderr redirected to dev null
	installerExitCode=1
	while [ "$installerExitCode" -ne 0 ]; do
		sudo /usr/sbin/installer -pkg "$pkgPath" -target "$INSTALLER_TARGET" > /dev/null 2>&1
		installerExitCode=$?
		if [ "$installerExitCode" -ne 0 ]; then
			echo "MSOFFICE - Failed to install: $pkgPath"
			echo "MSOFFICE - Installer exit code: $installerExitCode"
		fi
	done
	rm "$pkgPath"

done

if [[ ! -d $MAU_PATH ]]; then
	# Install Office
	# call function to download PKG
else
	# Update Office
	# call function to download MAU
fi

echo "MSOFFICE - Registering Microsoft Auto Update (MAU)"
if [ -e "$MAU_PATH" ]; then
	/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "$MAU_PATH"
	if [ -e "$SECOND_MAU_PATH" ]; then
		/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -R -f -trusted "$SECOND_MAU_PATH"
	fi
fi

echo "MSOFFICE - INSTALL COMPLETE"

