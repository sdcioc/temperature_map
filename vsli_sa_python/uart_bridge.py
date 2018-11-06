import serial
import json
import time

#portul pe care se trimit datele despre senzori
sending_serial = serial.Serial(port='/dev/pts/23', baudrate=115200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None, exclusive=None);

#portul pe care ses receptioneaza harta de temperatura
receiving_serial = serial.Serial(port='/dev/pts/24', baudrate=115200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None, exclusive=None);

#variabile definitie
MAX_SENSOR_NUMBERS = 10;
MAX_WIDTH = 20;
MAX_HEIGHT = 20;

#harta de temperatura si initializarea ei
tempMap = [];
for i in xrange(0, MAX_WIDTH):
	tempMap.append([]);
	for j in xrange(0, MAX_HEIGHT):
		tempMap[i].append(0);

# numarul de senzori
sensors_number = 5;

#descriptori pentru fisierele cu datele sensorilor
files_d = [];


#deschiderea fisierelor cu datele senzorilor
for i in xrange(0, sensors_number):
	files_d.append(open("./"+str(i+1)+".json","r"));
# fisierul inc are sunt scrise rezultatele
write_fd = open("./out.json","w");

#timpul petrecut in trimiterea datelor sensorilor
total_sending_time = 0;
#pot sa functioneze cat gaseste date in fisere sau in cazul de fata 111 iteratii
#while True:
for counter in xrange(0,111):
	sensors_x_position = [];
	sensors_y_position = [];
	sensors_temp = [];
	minx = 1000;
	maxx = -1000;
	miny = 1000;
	maxy = -1000;
	#citeste datele despre senzori
	for i in xrange(0, sensors_number):
		line = files_d[i].readline();
		line = line.strip();
		file_json_dict = json.loads(line);
		sensors_x_position.append(file_json_dict['x']);
		sensors_y_position.append(file_json_dict['y']);
		sensors_temp.append(file_json_dict['temp']);
		if(file_json_dict['x'] < minx):
			minx = file_json_dict['x'];
		if(file_json_dict['x'] > maxx):
			maxx = file_json_dict['x'];
		if(file_json_dict['y'] < miny):
			miny = file_json_dict['y'];
		if(file_json_dict['y'] > maxy):
			maxy = file_json_dict['y'];
	#trimite datele despre senzori	
	dx = maxx-minx;
	dy = maxy-miny;
	start_sending_time = time.time();
	sending_serial.write(bytearray([sensors_number]))
	sending_serial.flush()
	for i in xrange(0, sensors_number):
		poz_x = (sensors_x_position[i]-minx) * (MAX_WIDTH - 1) / dx;
		sending_serial.write(bytearray([int(poz_x)]))
		sending_serial.flush()
		poz_y = (sensors_y_position[i]-miny) * (MAX_WIDTH - 1) / dy;
		sending_serial.write(bytearray([int(poz_y)]))
		sending_serial.flush()
		sending_serial.write(bytearray([int(sensors_temp[i])]))
		sending_serial.flush()
	end_sending_time = time.time();
	total_sending_time = total_sending_time + (end_sending_time - start_sending_time);
	
	#receptioneaza harta de temeratura si o scrie in fisier
	for i in xrange(0, MAX_WIDTH):
		for j in xrange(0, MAX_HEIGHT):
			response = receiving_serial.read(1);
			tempMap[i][j] = int(response.encode('hex'), 16);

	write_fd.write(json.dumps(tempMap) + "\n");
#termina conexiunea si inchide fisierele
sending_serial.write(bytearray([0]))
sending_serial.flush()

for i in xrange(0, sensors_number):
	files_d[i].close();
write_fd.close();

#receptionarea hartii de temperatura
#for i in xrange(0, MAX_WIDTH):
#	for j in xrange(0, MAX_HEIGHT):
#		response = receiving_serial.read(1);
#		tempMap[i][j] = int(response.encode('hex'), 16);
#		print str(tempMap[i][j]) + " ";
#	print '\n';
#trimitea mesajul de terminare a programului
print total_sending_time;
print total_sending_time/111;
