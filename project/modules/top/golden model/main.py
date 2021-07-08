import numpy as np
import random


def binaryOfFraction(fraction):
    binary = str()
    while fraction:
        fraction *= 2
        if fraction >= 1:
            int_part = 1
            fraction -= 1
        else:
            int_part = 0
        binary += str(int_part)
    return binary


def floatingPoint(real_no):
    sign_bit = 0
    if real_no < 0:
        sign_bit = 1
    real_no = abs(real_no)
    int_str = bin(int(real_no))[2:]
    fraction_str = binaryOfFraction(real_no - int(real_no))
    ind = int_str.index('1')
    exp_str = bin((len(int_str) - ind - 1) + 127)[2:]
    mant_str = int_str[ind + 1:] + fraction_str
    mant_str = mant_str + ('0' * (23 - len(mant_str)))
    return sign_bit, exp_str, mant_str


def converter(number):
    sign_bit, exp_str, mant_str = floatingPoint(number)
    string = str(sign_bit) + ' ' + exp_str + ' ' + mant_str
    return string


maxSize = 3

ARowSize = random.randint(1, maxSize)
AColumnSize = random.randint(1, maxSize)
BRowSize = AColumnSize
BColumnSize = random.randint(1, maxSize)

A = np.random.random((ARowSize, AColumnSize))
B = np.random.random((BRowSize, BColumnSize))

print(ARowSize, AColumnSize)
print(A)
print(BRowSize, BColumnSize)
print(B)
C = np.dot(A, B)
print(C)
