# ios-icmp-channel
Send messages from IOS routers via ICMP payloads

Usage:
<pre>
Router#<b>tclsh flash:sender.tcl</b>
Usage: flash:sender.tcl [-v &lt;vrf&gt; | -i &lt;interface&gt;] &lt;target&gt; some message goes here
</pre>

The message is delivered one byte at a time in the payload of ICMP echo request packets. Each byte is preceeded by a sequence number. After the final byte, send 0x04 (EOM).

Running it like this:
<pre>
Router#<b>tclsh flash:sender.tcl target TEST</b>
</pre>

Produces echo requests that look like this:
<pre>
# <b>tcpdump -Xn icmp and src host router</b>
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 65535 bytes
15:54:00.266732 IP router &gt; target: ICMP echo request, id 305, seq 0, length 18
	0x0000:  4500 0026 01a7 0000 f201 1e2e xxxx xxxx  E..&............
	0x0010:  xxxx xxxx 0800 4ef4 0131 0000 0000 0000  ......N..1......
	0x0020:  b7d9 efac 0054 0000 0000 0000 0000       .....T........        <-- seq 0: T
15:54:00.514075 IP router &gt; target: ICMP echo request, id 306, seq 0, length 18
	0x0000:  4500 0026 01a8 0000 f201 1e2d xxxx xxxx  E..&.......-....
	0x0010:  xxxx xxxx 0800 4d0a 0132 0000 0000 0000  ......M..2......
	0x0020:  b7d9 f0a4 0145 0000 0000 0000 0000       .....E........        <-- seq 1: E
15:54:00.762870 IP router &gt; target: ICMP echo request, id 307, seq 0, length 18
	0x0000:  4500 0026 01a9 0000 f201 1e2c xxxx xxxx  E..&.......,....
	0x0010:  xxxx xxxx 0800 4b03 0133 0000 0000 0000  ......K..3......
	0x0020:  b7d9 f19c 0253 0000 0000 0000 0000       .....S........        <-- seq 2: S
15:54:01.010000 IP router &gt; target: ICMP echo request, id 308, seq 0, length 18
	0x0000:  4500 0026 01aa 0000 f201 1e2b xxxx xxxx  E..&.......+....
	0x0010:  xxxx xxxx 0800 4909 0134 0000 0000 0000  ......I..4......
	0x0020:  b7d9 f294 0354 0000 0000 0000 0000       .....T........        <-- seq 3: T
15:54:01.262253 IP router &gt; target: ICMP echo request, id 309, seq 0, length 18
	0x0000:  4500 0026 01ab 0000 f201 1e2a xxxx xxxx  E..&.......*....
	0x0010:  xxxx xxxx 0800 475c 0135 0000 0000 0000  ......G\.5......
	0x0020:  b7d9 f390 0404 0000 0000 0000 0000       ..............        <-- seq 4: &lt;EOM&gt;
</pre>
