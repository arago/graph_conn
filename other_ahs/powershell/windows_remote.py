import winrm
import os
import sys

def main():
# Read command line arguments passed by HIRO
    host = sys.argv[1]                     # FQDN of a target system
    transport = sys.argv[2]                # use plain HTTP or HTTPS [PLAIN|SSL]
    command_type = sys.argv[3]             # Command type [CMD|PS]
    command_line = sys.argv[4:]                  # Command line to execute

    username = os.environ.get('WINRM_USERNAME') # Windows username used for remote access. Read from System export as set in ActionHandler.env
    password = os.environ.get('WINRM_PASSWORD') # Windows user's password. Read from System export as set in ActionHandler.env

# Create a WinRM session.
# TODO: Certificate validation

    if transport.lower() == "plain":
        s = winrm.Session(host, auth=(username, password))
    elif transport.lower() == "ssl":
        s = winrm.Session(host, auth=(username, password),transport='ssl',server_cert_validation='ignore')

    # commands for windows cmd shell
    if command_type.lower() == "cmd":
        command = command_line[0]
        arguments = ' '.join(command_line[1:])
        r = s.run_cmd(command, arguments)
    # commands for windows powershell
    elif command_type.lower() == "ps":
        command = ' '.join(command_line)
        r = s.run_ps(command)
    # get result
    if r.status_code == 0:
        print(r.std_out.decode(encoding="utf-8"))
    else:
        print('Action failed with:', r.std_err)

def usage():
    print(sys.argv[0] + " hostname plain|ssl cmd|ps command_line ...")

if __name__ == "__main__":
    if len(sys.argv) > 4:
        main()
    else:
        usage()

