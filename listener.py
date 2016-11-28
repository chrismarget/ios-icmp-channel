#!/usr/bin/env python
import sys

class message(object):
    def add(self, idx, b):
        self.message[idx] = b
        if (b == '\x04') and self.is_complete():
            self.print_message()
    def get_eom_idx(self):
        for i in sorted(self.message.keys()):
            if self.message[i] == '\x04':
                return i 
        return False 
    def is_complete(self):
        eom_idx = self.get_eom_idx()
        if not eom_idx:
            return False
        received = self.message.keys()
        for i in range(0,eom_idx):
            if not (i in received):
                return False
        return True
    def print_message(self):
        print self.sender + "\t" + self.get_message()
    def get_message(self):
        out = ''
        eom_idx = self.get_eom_idx()
        for i in range(0,eom_idx):
            out+=self.message[i]
        return out
    def __init__(self, sender, idx, b):
        self.sender = sender
        self.message = {}
        self.add(idx, b)

def open_icmp_sniffer():
    import socket, sys
    import struct
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_RAW,
                socket.IPPROTO_ICMP)
    except socket.error, msg:
        print 'Socket create failed: '+str(msg[0])+' Message ' + msg[1]
        sys.exit()
    s.setsockopt(socket.IPPROTO_IP, socket.IP_HDRINCL, 1)
    s.bind(('', 0))
    return s

s = open_icmp_sniffer()
messages = {}

while True:
    p = s.recvfrom(65565)
    sender = p[1][0]
    sequence = ord(p[0][-2])
    payload =  p[0][-1]
    if sender not in messages.keys():
        messages[sender] = message(sender, sequence, payload)
    else:
        messages[sender].add(sequence, payload)
