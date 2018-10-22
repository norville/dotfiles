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

MAU_APP="/Library/Application Support/Microsoft/MAU2.0/Microsoft AutoUpdate.app"
LS_REG_DIR="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/"
INSTALLER_TARGET="LocalSystem"

function install_pkg () {
	echo "MSOFFICE - Starting Download/Install sequence."
	for downloadUrl in "$1"; do
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
		while [[ "$installerExitCode" -ne 0 ]]; do
			sudo /usr/sbin/installer -pkg "$pkgPath" -target "$INSTALLER_TARGET" > /dev/null 2>&1
			installerExitCode=$?
			if [[ "$installerExitCode" -ne 0 ]]; then
				echo "MSOFFICE - Failed to install: $pkgPath"
				echo "MSOFFICE - Installer exit code: $installerExitCode"
			fi
		done
		rm "$pkgPath"
		echo "MSOFFICE - Registering Microsoft Auto Update (MAU)"
		if [[ -e "$MAU_APP" ]]; then
			"$LS_REG_DIR"/lsregister -R -f -trusted "$MAU_APP"
			if [[ -e "$MAU_APP/Contents/MacOS/Microsoft AU Daemon.app" ]]; then
					"$LS_REG_DIR"/lsregister -R -f -trusted "$MAU_APP/Contents/MacOS/Microsoft AU Daemon.app"
			fi
		fi
	done
}

if [[ ! -e "$MAU_APP" ]]; then
	# Install Office
	install_pkg "$PKG_URL"
else
	# Update Office
	"$MAU_APP"/Contents/MacOS/msupdate --install
fi

echo "MSOFFICE - INSTALL COMPLETE"

