#!/usr/bin/python

import paramiko
import getpass

SSHUSER = "mrisser"
SSHPASSWD = getpass.getpass("SSH Password: ")

TNS1 = "192.168.1.28"
TNS2 = "192.168.3.21"

PS = 'ps auxwwU root | grep "zfs:" | sed "s/\// /g"'

def get_rep_status(host):
	# Connect to the FreeNAS server
	print("Connecting to: %s") % (host)
	sshclient = paramiko.SSHClient()
	sshclient.set_missing_host_key_policy(paramiko.client.AutoAddPolicy()) 
	sshclient.connect(hostname=host, username=SSHUSER, password=SSHPASSWD, look_for_keys=False)
	
	# Get the replication status
	print("Getting replication status...")
	stats = sshclient.exec_command(PS)

	# Close the connection
	sshclient.close()
	
	# Process the returned status to make it more readable
	#stats = stats.split()
	print(stats[0])
	print(stats[1])
	print(stats[2])
	
	rep_status = ""
	return rep_status

rep1 = get_rep_status(TNS1)
