#!/bin/ksh
# The script can be used by postgresql dba to preserve config files before a server maintenance
# Script version 1.0
# Script name: postgresql_config_file_preserve_1.0.ksh
# Version 1.0 - 26 Mar 2023 - svrajadba
# Script capability
#           1. Preserve OS config file relevant to the postgresql setup
#           2. Preserve Postgresql config files relevant to the postgresql setup
#           3. Preserve last postgresql logfile
# Inputs needed:
#           1. Hostname where the data needs to be collected
#           2. Port # of the postgresql service we needed the data collected. If more than one, please list them comma seperated
#           3. The prefix we wanted to use for the backup directory, which can be the activity name or so
#           4. Directory where the backup directory with 777 permission created
# Script Assumptions:
#           1. The postgres user exists on the host
#           2. The postgres user is trusted to login without password using psql on the port number listed

if [ $# -ne 4 ]; then
    echo -e "Please enter the below input variables:\n 1. Hostname in which the config files needs to be preserved.\n 2. The port list of the postgresql service we need the data preserved.\n 3. The backup directory prefix you want to use.\n 4. The directory where the backup directory needs to be preserved."
    exit 1;
fi

# Input variable validations
export hstndmn=$(echo $1|cut -d '.' -f 1);
export pstgrsprtlst=$2;
export gpfix=$3;
export bkpdir=$4;
export dt=$(date '+%d%m%y%H%M%Y');

# directory definations
basdir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )";
export basdir;
export cfgfldir=${basdir}/cfgfl

die()
{
if [ $1 -eq 101 ];
then
    echo "The program failed for server ${hstndmn} exception reason: $2";
    exit 1;
fi
}

initializedir()
{
rbkpdir=$1
rpfix=$2;
if ! [ -d ${rbkpdir} ];
then
    exit 1;
else
    mkdir ${rbkpdir}/${rpfix};
    chmod 777 ${rbkpdir}/${rpfix};
    exit 0;
fi
}

commonflcpyflow()
{
rbkpdir=$1
rpfix=$2;
rdt=$(echo ${rpfix}|rev|cut -d '_' -f 1|rev);
fnm=$3;
sfnm=$(echo ${fnm}|rev|cut -d '/' -f 1|rev);
funnm=${FUNCNAME[0]};
sfix=$(echo ${funnm}_${rdt});
rhstndmn=$(uname -n|cut -d '.' -f 1);
flprsnc=$(ls -altr ${fnm} >/dev/null 2>&1 && echo "OK" || echo "NOK");
if [[ "${flprsnc}" == "OK" ]]; then
    flcpy=$(cp ${fnm} ${rbkpdir}/${rpfix}/${sfnm}_${sfix} >/dev/null 2>&1 && echo "OK" || echo "NOK");
    if [[ "${flcpy}" == "OK" ]]; then
        bkpflprsnc=$(ls -altr ${rbkpdir}/${rpfix}/${sfnm}_${sfix} >/dev/null 2>&1 && echo "OK" || echo "NOK");
    fi
fi
echo "${rhstndmn},${fnm},filefound: ${flprsnc},filecoped: ${flcpy}, backupverify: ${bkpflprsnc}";
}

oscommandflow()
{
rbkpdir=$1
rpfix=$2;
rdt=$(echo ${rpfix}|rev|cut -d '_' -f 1|rev);
funnm=${FUNCNAME[0]};
sfix=$(echo ${funnm}_${rdt});
export PATH=$PATH:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:;
echo $PATH >${rbkpdir}/${rpfix}/pathvar_${sfix};
date >${rbkpdir}/${rpfix}/cudt_${sfix};
uname -a >${rbkpdir}/${rpfix}/serverkernelinfo_${sfix};
# error rerouted in case if the os isnt redhat or oracle or centos
cat /etc/redhat-release >${rbkpdir}/${rpfix}/etcrelease_${sfix} 2>/dev/null;
cat /etc/oracle-release >${rbkpdir}/${rpfix}/etcrelease_${sfix} 2>/dev/null;
cat /etc/centos-release >${rbkpdir}/${rpfix}/etcrelease_${sfix} 2>/dev/null;
ip a >${rbkpdir}/${rpfix}/ipdetails_${sfix};
df -h >${rbkpdir}/${rpfix}/fsinfo_${sfix};
free -k >${rbkpdir}/${rpfix}/memswapinfo_${sfix};
grep -i huge /proc/meminfo >${rbkpdir}/${rpfix}/cuhugepageinfo_${sfix};
# error rerouted in case root has no cron
crontab -l >${rbkpdir}/${rpfix}/rootcron_${sfix} 2>/dev/null;
id postgres >${rbkpdir}/${rpfix}/postgresusr_${sfix};
id barman >${rbkpdir}/${rpfix}/barmanusr_${sfix} 2>/dev/null;
rpm -qa|grep -i postgres >${rbkpdir}/${rpfix}/rpmlistpostgres_${sfix};
rpm -qa|grep -i barman >${rbkpdir}/${rpfix}/rpmlistbarman_${sfix};
}

psqlflow()
{
rbkpdir=$1
rpfix=$2;
rdt=$(echo ${rpfix}|rev|cut -d '_' -f 1|rev);
rprtn=$3;
rpstgrsprcid=$4;
funnm=${FUNCNAME[0]};
sfix=$(echo ${funnm}_${rdt});
PATH=${PATH}:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:;
PGBIN=$(ps -ef|grep -v grep|grep ${rpstgrsprcid}|grep postgres|grep -- "-D"|awk '{print $8}'|rev|cut -d '/' -f 3-|rev);
export PATH=${PATH}:${PGBIN}:${PGBIN}/lib:${PGBIN}/bin;
psql -p ${rprtn} -q -e <<EOFPSQL >${rbkpdir}/${rpfix}/psql_${rprtn}_${sfix}.out 2>&1
\pset pager off
show server_version;
select version();
select pg_is_in_recovery();
show data_directory;
show config_file;
show hba_file;
show ident_file;
\l+
\du+
\x
select * from pg_stat_replication;
select * from pg_stat_activity order by datname,state,pid;
select * from pg_hba_file_rules order by 1;
select * from pg_stat_wal_receiver;
EOFPSQL
}

pgcfgcoll()
{
rbkpdir=$1
rpfix=$2;
rdt=$(echo ${rpfix}|rev|cut -d '_' -f 1|rev);
rprtn=$3;
rpstgrsprcid=$4;
funnm=${FUNCNAME[0]};
sfix=$(echo ${funnm}_${rdt});
PATH=${PATH}:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:;
PGBIN=$(ps -ef|grep -v grep|grep ${rpstgrsprcid}|grep postgres|grep -- "-D"|awk '{print $8}'|rev|cut -d '/' -f 3-|rev);
export PATH=${PATH}:${PGBIN}:${PGBIN}/lib:${PGBIN}/bin;
psql -p ${rprtn} -q -b -t <<EOFPSQL >${rbkpdir}/${rpfix}/psql_${rprtn}_${sfix}.out 2>${rbkpdir}/${rpfix}/psql_${rprtn}_${sfix}.err
show config_file;
show hba_file;
show ident_file;
select distinct(sourcefile) from pg_settings order by 1;
EOFPSQL
lncnt=$(cat ${rbkpdir}/${rpfix}/psql_${rprtn}_${sfix}.err|wc -l);
if [ ${lncnt} -gt 0 ];
then
    echo "${funnm} has errors";
else
    awk 'NF' ${rbkpdir}/${rpfix}/psql_${rprtn}_${sfix}.out|sort|uniq;
fi
}

pstgrsflcpyflow()
{
rbkpdir=$1
rpfix=$2;
rdt=$(echo ${rpfix}|rev|cut -d '_' -f 1|rev);
rprtn=$3;
fnm=$4;
sfnm=$(echo ${fnm}|rev|cut -d '/' -f 1|rev);
funnm=${FUNCNAME[0]};
sfix=$(echo ${funnm}_${rdt});
rhstndmn=$(uname -n|cut -d '.' -f 1);
flprsnc=$(ls -altr ${fnm} >/dev/null 2>&1 && echo "OK" || echo "NOK");
if [[ "${flprsnc}" == "OK" ]]; then
    flcpy=$(cp ${fnm} ${rbkpdir}/${rpfix}/${sfnm}_${rprtn}_${sfix} >/dev/null 2>&1 && echo "OK" || echo "NOK");
    if [[ "${flcpy}" == "OK" ]]; then
        bkpflprsnc=$(ls -altr ${rbkpdir}/${rpfix}/${sfnm}_${rprtn}_${sfix} >/dev/null 2>&1 && echo "OK" || echo "NOK");
    fi
fi
echo "${rhstndmn},${fnm},filefound: ${flprsnc},filecoped: ${flcpy}, backupverify: ${bkpflprsnc}";
}

srvflcpy()
{
rbkpdir=$1
rpfix=$2;
rdt=$(echo ${rpfix}|rev|cut -d '_' -f 1|rev);
rprtn=$3;
rpstgrsprcid=$4;
funnm=${FUNCNAME[0]};
sfix=$(echo ${funnm}_${rdt});
PATH=${PATH}:/usr/local/bin:/bin:/usr/bin:/usr/local/sbin:/usr/sbin:;
PGBIN=$(ps -ef|grep -v grep|grep ${rpstgrsprcid}|grep postgres|grep -- "-D"|awk '{print $8}'|rev|cut -d '/' -f 3-|rev);
export PATH=${PATH}:${PGBIN}:${PGBIN}/lib:${PGBIN}/bin;
pmstcnt=$(ps -ef|grep -v grep|grep postmaster|grep -- "-D"|grep ${rpstgrsprcid}|wc -l);
if [ ${pmstcnt} -gt 0 ]; then
    pgvrvsn=$(ps -ef|grep -v grep|grep ${rpstgrsprcid}|grep postgres|grep -- "-D"|awk '{print $8}'|cut -d '/' -f 2-3|cut -d '-' -f 2);
    if [ -f /usr/lib/systemd/system/postgresql-${pgvrvsn}.service ];
    then
        cp /usr/lib/systemd/system/postgresql-${pgvrvsn}.service ${rbkpdir}/${rpfix}/postgresql-${pgvrvsn}.service_${rprtn}_${sfix} >/dev/null 2>&1 && echo "ServiceFileCopy_OK" || echo "ServiceFileCopy_NOK";
    else
        echo "ServiceFileNotFound_NOK";
    fi
else
    echo "ServiceNotConfigured_OK";
fi
}

# main function routine
# verify if basic os commands are installed
ssh postgres@${hstndmn} "which netstat" >/dev/null 2>&1 && echo "OS_Command_netstat_PreCheck: OK" || die 101 oscommand_netstat_availability_failed;

# verify if osconfig_file.lst file is found; which includes all the os config list to be preserved
if ! [ -f ${cfgfldir}/osconfig_file.lst ];
then
    die 101 osconfig_file.lst_not_found;
fi

# initialize the directory to preserve the settings
ssh postgres@${hstndmn} "$(typeset -f initializedir); initializedir ${bkpdir} ${gpfix}_${hstndmn}_${dt}"
if [ $? -ne 0 ];
then
    die 101 "initializedir_failed";
else
    echo "${hstndmn} - Remote Directory Initialized";
fi

# fixed os config file copy routine
while read line
do
ssh postgres@${hstndmn} "$(typeset -f commonflcpyflow); commonflcpyflow ${bkpdir} ${gpfix}_${hstndmn}_${dt} ${line}" </dev/null;
done < ${cfgfldir}/osconfig_file.lst

echo "${hstndmn} - Postgresql Specific OS config file copy finished";

# fixed os command outputs preserve
ssh postgres@${hstndmn} "$(typeset -f oscommandflow); oscommandflow ${bkpdir} ${gpfix}_${hstndmn}_${dt}"
# skipping failure check here; since the command overall carries forward all the commands within's exit status using && operation; which is robust. But we expect some failures due to some non-existent object or setup.

echo "${hstndmn} - Postgresql Specific OS Command Output preserved";

for prtn in $(echo ${pstgrsprtlst}|tr ',' '\n')
do
    ssh postgres@${hstndmn} "netstat -plantu|grep ${prtn}|grep LISTEN" >/dev/null 2>&1;
    if [ $? -eq 0 ];
    then
        echo "${hstndmn} - ${prtn} - port active: OK";
    else
        echo "${hstndmn} - ${prtn} - port active: NOK";
        continue;
    fi
    pstgrsprcid=$(ssh postgres@${hstndmn} "netstat -plantu 2>/dev/null|grep ${prtn}|grep -v tcp6|grep tcp|awk '{print \$7}'|cut -d '/' -f 1");
    ssh postgres@${hstndmn} "$(typeset -f psqlflow); psqlflow ${bkpdir} ${gpfix}_${hstndmn}_${dt} ${prtn} ${pstgrsprcid}";
    if [ $? -ne 0 ];
    then
        die 101 "psqlflow_${prtn}_failed";
    else
        echo "${hstndmn} - ${prtn} - Postgresql Psql Command Output preserved";
    fi
    # prepare postgresql filelist to copy
    psgcfgfile=$(ssh postgres@${hstndmn} "$(typeset -f pgcfgcoll); pgcfgcoll ${bkpdir} ${gpfix}_${hstndmn}_${dt} ${prtn} ${pstgrsprcid}");
    echo "${hstndmn} - ${prtn} - Postgresql Config File Details collected";
    # use pstgrsflcpyflow routine to preserve postgresql config files
    for fl in ${psgcfgfile}
    do
        ssh postgres@${hstndmn} "$(typeset -f pstgrsflcpyflow); pstgrsflcpyflow ${bkpdir} ${gpfix}_${hstndmn}_${dt} ${prtn} ${fl}" </dev/null;
    done
    # Copy Postgres Service File
    ssh postgres@${hstndmn} "$(typeset -f srvflcpy); srvflcpy ${bkpdir} ${gpfix}_${hstndmn}_${dt} ${prtn} ${pstgrsprcid}";
    echo "${hstndmn} - ${prtn} - Postgresql Service File Preserved";
done
echo "${hstndmn} - All Steps are completed.Thanks"
