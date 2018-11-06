Cerinte de rulare:
1. vivado 2017.04 ubuntu 16.04
https://techmuse.in/installing-uninstalling-vivado-2017-4-in-ubuntu-16-04/
2. socat
sudo apt-get install socat
3. pip
sudo apt-get install python-pip
4. pil
pip install pillow
5. numpy
pip install numpy
6. pyserial
pip install pyserial

Comanda pentru deschiderea porturilor virtuale de seriala (rulata de doua ori)
socat -d -d pty,raw,echo=0 pty,raw,echo=0

Fisierele python
temp_process.py - proceseaza harta de temperatura in functie de informatile primite pe seriala
test_uart_bridge.py - testeaza temp_process cu data dummy
uart_bridge.py - citeste datele despre senzori si scrie in fisiere hartiile de temperatura sub forma de matrici
image_process.py - genereaza o imagine cu harta de temperatura
