# commondbascripts
# suggest to put .hushlogin file to avoid last login messages from remote ssh
# look at the example output below, where 5432 is active port, 5433 isnt active
# Example:
## [oracle@vcentos79-oracle-ha1 fntst]$ sh postgresql_config_file_preserve_1.0.ksh vcentos79-postgres-ha1 5432,5433 OSMaintain_09 /tmp
## OS_Command_netstat_PreCheck: OK
## vcentos79-postgres-ha1 - Remote Directory Initialized
## vcentos79-postgres-ha1,/etc/hosts,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/etc/sysctl.conf,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/etc/default/grub,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/etc/security/limits.conf,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/etc/passwd,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1 - Postgresql Specific OS config file copy finished
## vcentos79-postgres-ha1 - Postgresql Specific OS Command Output preserved
## vcentos79-postgres-ha1 - 5432 - port active: OK
## vcentos79-postgres-ha1 - 5432 - Postgresql Psql Command Output preserved
## vcentos79-postgres-ha1 - 5432 - Postgresql Config File Details collected
## vcentos79-postgres-ha1,/pgdata/14/data/pg_hba.conf,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/pgdata/14/data/pg_ident.conf,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/pgdata/14/data/postgresql.auto.conf,filefound: OK,filecoped: OK, backupverify: OK
## vcentos79-postgres-ha1,/pgdata/14/data/postgresql.conf,filefound: OK,filecoped: OK, backupverify: OK
## ServiceFileCopy_OK
## vcentos79-postgres-ha1 - 5432 - Postgresql Service File Preserved
## vcentos79-postgres-ha1 - 5433 - port active: NOK
## vcentos79-postgres-ha1 - Config Files are dumped in /tmp/OSMaintain_09_vcentos79-postgres-ha1_27032319362023.
## vcentos79-postgres-ha1 - All Steps are completed.Thanks
## [oracle@vcentos79-oracle-ha1 fntst]$ 
