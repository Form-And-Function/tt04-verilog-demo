import RPi.GPIO as GPIO
import time
import random

GPIO.setmode(GPIO.BOARD)

cs_n = 11 # blue
mosi = 13 # green
miso = 15 # yellow
sck  = 16 # pink

GPIO.setup(cs_n, GPIO.OUT)
GPIO.setup(mosi, GPIO.OUT)
GPIO.setup(miso, GPIO.IN)
GPIO.setup(sck,  GPIO.OUT)

def send_bit(bit):
    GPIO.output(mosi, bit)
    GPIO.output(sck, GPIO.HIGH)
    GPIO.output(sck, GPIO.LOW)

def send_byte(byte):
    for _ in range(8):
        send_bit(byte & 0x80)
        byte <<= 1

def receive_byte():
    byte = 0
    for _ in range(8):
        GPIO.output(sck, GPIO.HIGH)
        byte <<= 1
        byte |= GPIO.input(miso)
        GPIO.output(sck, GPIO.LOW)
    return byte

def send_command(command, argument, size):
    GPIO.output(cs_n, GPIO.LOW)
    send_byte(command | 0x40)
    for i in range(4):
        send_byte(argument >> (24 - i * 8))
    send_byte(0x95)
    GPIO.output(mosi, GPIO.HIGH)
    while received_byte := receive_byte() != 0xFF:
        pass

    GPIO.output(cs_n, GPIO.HIGH)

def init():
    GPIO.output(cs_n, GPIO.HIGH)
    num_clock_cycles_to_wait = 74
    for _ in range(num_clock_cycles_to_wait):
        send_bit(1)
    GPIO.output(cs_n, GPIO.LOW)
    send_byte(0x40)
    send_byte(0x00)
    send_byte(0x00)
    send_byte(0x00)
    send_byte(0x00)
    send_bit(0x95)
    send_bit(0xFF)
    while receive_byte() != 0xFF:
        pass
    GPIO.output(cs_n, GPIO.HIGH)