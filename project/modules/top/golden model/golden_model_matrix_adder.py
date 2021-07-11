import numpy as np
matrixA=[]
matrixB = []
R = int(input("Enter the number of rows of the matrices:")) 
C = int(input("Enter the number of columns of the matrices:")) 
print("Enter the elements of the matrix 'A' in matrix format:")
for i in range(0,R):   #where n is the no. of lines you want
    matrixA.append([np.float32(j) for j in input().split()])  #for taking m space
    #separated single precision numbers as input
print("Enter the elements of the matrix 'B' in matrix format:")
for i in range(0,R):   #where n is the no. of lines you want
    matrixB.append([np.float32(j) for j in input().split()])  #for taking m space
    #separated single precision numbers as input
result = []
for i in range(R):
    a = []
    for j in range(C):
        a.append(matrixA[i][j] + matrixB[i][j])
    result.append(a)

print("Result matrix:")   
for i in range(R):
        for j in range(C):
            print(result[i][j], end = " ")
        print()
