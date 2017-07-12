#!/bin/sh -e
API_HOST=
SERVICE_URL="http://$API_HOST"
LOG_DIR="~/kaltura/log"
YOUR_PARTNER_ID=101
#e068809c752fb5f311217eb3da3bc74d | 9c9f8d1cbb6bab63f3ac8450fcdb33f7
YOUR_USER_SECRET=""
YOUR_ADMIN_SECRET=""
echo "Generating clientlibs.. be patient."
while read CLIENT;do php /opt/kaltura/clients-generator/exec.php $CLIENT;done < /opt/kaltura/clients-generator/config/generator.all.ini
REPO_RC_FILE=`dirname $0`/clientlib_to_git_repo.rc
if [ -r $REPO_RC_FILE ];then
	. $REPO_RC_FILE
else
	echo "Couldn't find `dirname $0`/clientlib_to_git_repo.rc && exiting:("
	exit 1
fi
TEMP_CHECKOUT=/tmp/clients_checkouts
mkdir -p $TEMP_CHECKOUT
rm -rf $TEMP_CHECKOUT/*
cd $TEMP_CHECKOUT
while read CLIENT;do 
	if `echo $CLIENT|grep -q "^#\|^$"` ;then
		continue
	fi
	REPO=`echo $CLIENT |awk -F "=" '{print $1}'`
	DIR=`echo $CLIENT |awk -F "=" '{print $2}'`
	LIB_PREFIX_DIR="/opt/kaltura/web/content/clientlibs/$DIR"
	git clone git@github.com:kaltura/$REPO.git
	cd $TEMP_CHECKOUT/$REPO
	#SERVER_BRANCH="master"
	SERVER_BRANCH=`rpm -qa kaltura-base --queryformat %{version}`
	for BRANCH in master $SERVER_BRANCH;do
		if git branch |grep -q $BRANCH ;then
			git checkout $BRANCH 
		else
			git checkout -b $BRANCH 
		fi
		mkdir -p $TEMP_CHECKOUT/$REPO/$DIR/
		cp -r $LIB_PREFIX_DIR/* $TEMP_CHECKOUT/$REPO/
		CONF_FILES=`find $TEMP_CHECKOUT/$REPO  -type f -name "*\.template*"`
		for TMPL_CONF_FILE in $CONF_FILES;do
			CONF_FILE=`echo $TMPL_CONF_FILE | sed 's@\(.*\)\.template\(.*\)@\1\2@'`
			cp  $TMPL_CONF_FILE $CONF_FILE
		done
		find $TEMP_CHECKOUT/$REPO -type f -exec sed -i -e "s#@YOUR_PARTNER_ID@#$YOUR_PARTNER_ID#g" -e "s#@PARTNER_ID@#$YOUR_PARTNER_ID#g" -e "s#@YOUR_USER_SECRET@#$YOUR_USER_SECRET#g" -e "s#@YOUR_ADMIN_SECRET@#$YOUR_ADMIN_SECRET#g" -e "s#@API_HOST@#$API_HOST#g" -e "s#@LOG_DIR@#$LOG_DIR#g" -e "s#@SERVICE_URL@#$SERVICE_URL#g" {} \;
		cd $TEMP_CHECKOUT/$REPO && git add * ; git commit -a -m "New clientlib ver" && git pull origin $BRANCH && git push origin $BRANCH
	done
	cd $TEMP_CHECKOUT
done < $REPO_RC_FILE

