#
# This script will be located on S3 to be downloaded and run by an EC2
# app server instance to set up the server and start the application.
#

cd /root/


# Init swap memory

fallocate -l 2048M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50


# Download web application update script

aws s3 cp "${s3_deployment_url}/ec2-appupdate" .
if [ ! -f "ec2-appupdate" ]; then
	echo "Deployment script \"ec2-appupdate\" not found!"
	exit 1
fi

chmod 0700 ec2-appupdate


# Download and install NewRelic Java Agent (optional)

if [ "$install_newrelic_agent" = true ]; then
	aws s3 cp "${s3_deployment_url}/newrelic-java.zip" .

	if [ -f "newrelic-java.zip" ]; then
		unzip newrelic-java.zip
		rm -f newrelic-java.zip

		aws s3 cp "${s3_deployment_url}/newrelic.yml" newrelic/newrelic.yml
		if [ ! -f "newrelic/newrelic.yml" ]; then
			echo "newrelic.yml not found!"
		fi
	else
		echo "newrelic-java.zip not found!"
	fi
fi


# Download and install NewRelic Server Monitor

if [ ! -z "${url_newrelic_monitor}" ]; then
	curl -O "${url_newrelic_monitor}"
	tar xzvf newrelic-sysmond-*.tar.gz
	rm -f newrelic-sysmond-*-linux.tar.gz
	mv newrelic-sysmond-*-linux newrelic-sysmond-linux

	if [ -d "newrelic-sysmond-linux" ]; then
		cp newrelic-sysmond-linux/daemon/nrsysmond.x64 /usr/local/bin/nrsysmond
		cp newrelic-sysmond-linux/scripts/nrsysmond-config /usr/local/bin
		if [ ! -d /etc/newrelic ]; then
			mkdir -p /etc/newrelic
		fi
		if [ ! -d /var/log/newrelic ]; then
			mkdir -p /var/log/newrelic
		fi

		aws s3 cp "${s3_deployment_url}/nrsysmond.cfg" /etc/newrelic/nrsysmond.cfg
		if [ -f /etc/newrelic/nrsysmond.cfg ]; then
			/usr/local/bin/nrsysmond -c /etc/newrelic/nrsysmond.cfg
		else
			echo "nrsysmond.cfg not found!"
		fi
	else
		echo "Could not install ${url_newrelic_monitor}!"
	fi
fi


# Run deploy update script

./ec2-appupdate
