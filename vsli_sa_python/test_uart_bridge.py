import serial

#portul pe care se trimit datele despre senzori
sending_serial = serial.Serial(port='/dev/pts/23', baudrate=115200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None, exclusive=None);

#portul pe care ses receptioneaza harta de temperatura
receiving_serial = serial.Serial(port='/dev/pts/25', baudrate=115200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None, exclusive=None);

# se trimit date despre 2 senzori si se asteapta rezultatul
sending_serial.write(bytearray([2]))
sending_serial.flush()
sending_serial.write(bytearray([5]))
sending_serial.flush()
sending_serial.write(bytearray([5]))
sending_serial.flush()
sending_serial.write(bytearray([5]))
sending_serial.flush()
sending_serial.write(bytearray([10]))
sending_serial.flush()
sending_serial.write(bytearray([10]))
sending_serial.flush()
sending_serial.write(bytearray([10]))
sending_serial.flush()

#variabile predefinite
MAX_WIDTH = 20;
MAX_HEIGHT = 20;
#harta de temperatura si initializarea ei
tempMap = [];
for i in xrange(0, MAX_WIDTH):
	tempMap.append([]);
	for j in xrange(0, MAX_HEIGHT):
		tempMap[i].append(0);
#receptionarea hartii de temperatura
for i in xrange(0, MAX_WIDTH):
	for j in xrange(0, MAX_HEIGHT):
		response = receiving_serial.read(1);
		tempMap[i][j] = int(response.encode('hex'), 16);
		print str(tempMap[i][j]) + " ";
	print '\n';
#trimitea mesajul de terminare a programului
sending_serial.write(bytearray([0]))
sending_serial.flush()
