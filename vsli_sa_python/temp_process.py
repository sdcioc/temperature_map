import serial
import math
import time

#port-ul serial pe care trimite rezultatul
sending_serial = serial.Serial(port='/dev/pts/25', baudrate=115200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None, exclusive=None);

#port-ul serial pe care primeste infromatii despre senzori
receiving_serial = serial.Serial(port='/dev/pts/22', baudrate=115200, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE, stopbits=serial.STOPBITS_ONE, timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None, exclusive=None);

#variabile definitie
MAX_SENSOR_NUMBERS = 10;
MAX_WIDTH = 20;
MAX_HEIGHT = 20;
#pozitia senzorilor pe axa ox
sensors_x_position = [];
#pozitia senzorilor pe axa oy
sensors_y_position = [];
#valoarea sensorilor
sensors_temp = [];
#harta cu temperaturi
tempMap = [];
#distantele de la punctul curent la senzori
distances = [];
#parametrii
params = [];
#numarul de senzori
sensors_number = 0;

#initializarea vectoriilor si a matricelor
for i in xrange(0, MAX_SENSOR_NUMBERS):
	sensors_x_position.append(0);
	sensors_y_position.append(0);
	sensors_temp.append(0);
	distances.append(0);
	params.append(0);

for i in xrange(0, MAX_WIDTH):
	tempMap.append([]);
	for j in xrange(0, MAX_HEIGHT):
		tempMap[i].append(0);
#timpul petrecut in procesare
total_processing_time  = 0;
#timpul petrecut in transmiterea hartii de temperatura
total_sending_time = 0;
#rularea procesului
while True:
	#receptionarea numarul de sonzri si a valorilor specifice fiecarui senzor	
	response = receiving_serial.read(1);
	sensors_number = int(response.encode('hex'), 16)
	if(sensors_number == 0):
		break;
	for i in xrange(0, sensors_number):
		response = receiving_serial.read(1);
		val = int(response.encode('hex'), 16)
		sensors_x_position[i] = val;
		response = receiving_serial.read(1);
		val = int(response.encode('hex'), 16)
		sensors_y_position[i] = val;
		response = receiving_serial.read(1);
		val = int(response.encode('hex'), 16)
		sensors_temp[i] = val;
	
	start_procesing_time = time.time();
	#calcularea hartii de temperatura
	#prosudul distantelor
	total_product = 1;
	#suma parametrilor
	total_sum_parametres = 0;
	#valoare auxiliara pentru temperatura
	tmp_temp = 0;
	for i in xrange(0, MAX_WIDTH):
		for j in xrange(0, MAX_HEIGHT):
			tmp_temp = 0;
			total_product = 1;
			total_sum_parametres = 0;
			for k in xrange(0, sensors_number):
				distances[k] = math.pow(i + 1 - sensors_x_position[k] ,2) + math.pow(j + 1 - sensors_y_position[k] ,2)
				total_product = total_product * distances[k];
			for k in xrange(0, sensors_number):
				if(distances[k] > 0.0001):
					params[k] = total_product / distances[k];
				else:
					params[k] = 1;
				total_sum_parametres = total_sum_parametres + params[k];
			for k in xrange(0, sensors_number):
				tmp_temp = tmp_temp + params[k] * sensors_temp[k];
			tempMap[i][j] = tmp_temp / total_sum_parametres;
	end_procesing_time = time.time();
	total_processing_time = total_processing_time + (end_procesing_time - start_procesing_time);
	start_sending_time = time.time();
	#scrie pe seriala a hartii de temperatura
	for i in xrange(0, MAX_WIDTH):
		for j in xrange(0, MAX_HEIGHT):
			sending_serial.write(bytearray([int(tempMap[i][j])]))
			sending_serial.flush()
	end_sending_time = time.time();
	total_sending_time = total_sending_time + (end_sending_time - start_sending_time);

print total_processing_time;
print total_processing_time/111;
print total_sending_time;
print total_sending_time/111;
