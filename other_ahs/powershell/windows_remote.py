import winrm
import os
import sys

def main():
	# Read command line arguments passed by HIRO
        host = sys.argv[1]				# FQDN of a target system
        command_type = sys.argv[2]			# Command type [CMD|PS] 
        command = sys.argv[3]				# Cmd-let/Command to execute
        arguments = sys.argv[4:len(sys.argv)]		# Space separated list of arguments

        username = os.environ.get('WINRM_USERNAME')	# Windows username used for remote access. Read from System export as set in ActionHandler.env
        password = os.environ.get('WINRM_PASSWORD')	# Windows user's password. Read from System export as set in ActionHandler.env

	# Create a WinRM session. 
	# TODO: Ignores SSL certificate validity issues
	# TODO: Hardcoded SSL transport
        s = winrm.Session(host, auth=(username, password),transport='ssl',server_cert_validation='ignore')

        if command_type == "CMD" or command_type == "cmd":
             r = s.run_cmd(command, sys.argv[3:len(sys.argv)])
        if command_type == "PS" or command_type == "ps":
                for argument in arguments:
                        command += " "
                        command += argument
                r = s.run_ps(command)
        if r.status_code == 0:
                print(r.std_out.decode(encoding="utf-8"))
        else:
                print('Action failed with:', r.std_err)

def usage():
        print(sys.argv[0] + " hostname cmd|ps command arguments...")

if __name__ == "__main__":
        if len(sys.argv) > 3:
                main()
        else:
                usage()
