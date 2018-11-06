from PIL import Image
import numpy as np
import json

#deschiderea imaginii cu harta si transformarea datelor in imaginii intr-o matrice
i = Image.open('./submap_0.pgm');
iar = np.asarray(i);

# se creaza noua matrice
h, w = iar.shape;
data = np.zeros((h, w, 3), dtype=np.uint8);

MAX_WIDTH = 20;
MAX_HEIGHT = 20;

minx = 47;
maxx = 2044;
miny = 380;
maxy = 3108;
dx = maxx-minx;
dy = maxy-miny;

#se deschide fisierul cu hartile de temperatura si se coloreaza harta conform datelor
tempMap_fd = open("./out.json","r");
tempMap = json.loads(tempMap_fd.readline().strip());
for i in xrange(0,w):
	for j in xrange(0,h):
		if(iar[j][i] == 205):
			data[j][i] = [128, 128, 128];
		else:
			poz_x = int((i-minx) * (MAX_WIDTH - 1) / dx);
			poz_y = int((j-miny) * (MAX_WIDTH - 1) / dy);
			data[j][i] = [255, 180 - (tempMap[poz_x][poz_y] - 15) *9, 0];

img = Image.fromarray(data, 'RGB');
img.save('./my.png');
