import sys, os
import subprocess, shlex

menu_actions  = [
    { 'label': 'hostname', 'command': 'hostname' },
    { 'label': 'date', 'command': 'date' },
]
 
def clear():
    os.system('clear')

def main(curr_menu):
    while True:
        print 'Menu'
        for i in range(0, len(curr_menu)):
            print '%2d %s' % (i + 1, curr_menu[i]['label'])
        print '\n0/q quit'
        command_raw = raw_input('--> ')
        if command_raw == '0' or command_raw == 'q' or command_raw == 'Q':
            return
        run_command(curr_menu, command_raw)
 
def run_command(menu, menu_input):
    index = -1
    try:
        index = int(menu_input) - 1
    except:
        print >>sys.stderr, 'Error: invalid input '' + menu_input + '''
    if index < 0 or index >= len(menu):
        print >>sys.stderr, 'Error: invalid menu choice '' + index + '''
    try:
        entry = menu[index]
        command = entry['command']
        run_with_output(command)
    except:
        print 'Error running command'

def run_with_output(command):
    print "run_with_output '%s'" % (command)
    try:
        p = subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        print p.communicate()[0]
    except CalledProcessError as cpe:
        print "Error: CalledProcessError code=" + cpe.returncode
        print cpe.output

if __name__ == '__main__':
    main(menu_actions)
