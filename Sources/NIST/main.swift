import Foundation

var a = Matrix([[1.0, 2.0], [3.0, 4.0], [1.0, 2.0]])
var b = Matrix([[1.0, 2.0, 3.0] , [4.0, 1.0, 2.0]])

print(a)
print(b)

print((a*b).transpose())
