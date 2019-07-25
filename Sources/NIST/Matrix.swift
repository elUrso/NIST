protocol Algebraic {
    // sumDefault is the value such that itself plus another value A equals A
    var sumDefault: Self { get }
    // multiplicationDefault is the value such that itself times another value A equals A
    var multiplicationDefault: Self { get }
    // sumComplement is the value such that when added to self equals sumDefault
    var sumComplement: Self { get }
    // multiplicationComplement is the value such that when multiplied to self equals multiplicationDefault
    var multiplicationComplement: Self { get }


    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func > (lhs: Self, rhs: Self) -> Bool
}

extension Double: Algebraic {
    var sumDefault: Double { get { return 0.0 } }
    var multiplicationDefault: Double { get { return 1.0 } }
    var sumComplement: Double { get { return -self } }
    var multiplicationComplement: Double { get { return 1.0 / self } }
}

struct Matrix<Number> where Number: Algebraic {
    var buffer: [Number]
    var rows: Int
    var columns: Int

    init(rows: Int, columns: Int, with number: Number) {
        self.rows = rows
        self.columns = columns
        self.buffer = [Number](repeating: number, count: rows * columns)
    }

    init(rows: Int, columns: Int, with generator: (Int, Int) -> Number) {
        self.init(rows: rows, columns: columns, with: generator(0,0))
        for i in 0..<rows {
            for j in 0..<columns {
                setAt(row: i, column: j, to: generator(i, j))
            }
        }
    }
    
    init(_ values: [[Number]]) {
        self.init(rows: values.count, columns: values[0].count, with: values[0][0])
        self.set(values)
    }

    mutating func setAt(row: Int, column: Int, to value: Number) {
        self.buffer[row * self.columns + column] = value
    }

    mutating func apply(with generator: (Int, Int, Number) -> Number) {
        for i in 0..<rows {
            for j in 0..<columns {
                setAt(row: i, column: j, to: generator(i, j, getAt(row: i, column: j)))
            }
        }
    }

    func map(with generator: (Int, Int, Number) -> Number) -> Matrix<Number>{
        var temp = Matrix<Number>(rows: rows, columns: columns, with: getAt(row: 0, column: 0))
        for i in 0..<rows {
            for j in 0..<columns {
                temp.setAt(row: i, column: j, to: generator(i, j, getAt(row: i, column: j)))
            }
        }

        return temp
    }

    mutating func setAt(row: Int, to values: [Number]) /*throws*/ {
        /*if values.count != self.columns {
            throw MatrixError.SizeMismatch("Row size is incompatible")
        }*/

        for j in 0..<values.count {
            self.setAt(row: row, column: j, to: values[j])
        }
    }

    mutating func setAt(column: Int, to values: [Number]) /*throws*/ {
        /*if values.count != self.rows {
            throw MatrixError.SizeMismatch("column size is incompatible")
        }*/

        for i in 0..<values.count {
            self.setAt(row: i, column: column, to: values[i])
        }
    }

    mutating func set(_ matrix: [[Number]]) {
        for i in 0..<matrix.count {
            for j in 0..<matrix[0].count {
                self.setAt(row: i, column: j, to: matrix[i][j])
            }
        }
    }

    func getAt(row: Int, column: Int) -> Number {
        return self.buffer[row * self.columns + column]
    }

    func transpose() -> Matrix<Number> {
        var ret = Matrix<Number>(rows: self.columns, columns: self.rows, with: self.buffer[0])
        for i in 0..<self.rows {
            for j in 0..<self.columns {
                ret.setAt(row: j, column: i, to: self.getAt(row: i, column: j))
            }
        }

        return ret
    }

    static func * (lhs: Matrix<Number>, rhs: Matrix<Number>) -> Matrix<Number> {
        var ret = Matrix(rows: lhs.rows, columns: rhs.columns, with: lhs.buffer[0].sumDefault)

        for i in 0..<ret.rows {
            for j in 0..<ret.columns {
                var sum: Number = lhs.buffer[0].sumDefault
                for k in 0..<lhs.columns {
                    sum = sum + (lhs.getAt(row: i, column: k) * rhs.getAt(row: k, column: j))
                }
                ret.setAt(row: i, column: j, to: sum)
            }
        }
        return ret
    }

    static func * (lhs: Matrix<Number>, rhs: Number) -> Matrix<Number> {
        var ret = Matrix(rows: lhs.rows, columns: lhs.columns, with: lhs.buffer[0].sumDefault)
        for i in 0..<ret.rows {
            for j in 0..<ret.columns {
                ret.setAt(row: i, column: j, to: lhs.getAt(row: i, column: j) * rhs)
            }
        }

        return ret
    }

    static func * (lhs: Number, rhs: Matrix<Number>) -> Matrix<Number> {
        return rhs * lhs
    }

    static func + (lhs: Matrix<Number>, rhs: Matrix<Number>) -> Matrix<Number> {
        var ret = Matrix(rows: lhs.rows, columns: lhs.columns, with: lhs.buffer[0].sumDefault)
        for i in 0..<ret.rows {
            for j in 0..<ret.columns {
                ret.setAt(row: i, column: j, to: lhs.getAt(row: i, column: j) + rhs.getAt(row: i, column: j))
            }
        }
        return ret
    }

    static func + (lhs: Matrix<Number>, rhs: Number) -> Matrix<Number> {
        let ret = Matrix(rows: lhs.rows, columns: lhs.columns, with: rhs)
        return lhs + ret
    }

    static func + (lhs: Number, rhs: Matrix<Number>) -> Matrix<Number> {
        return rhs + lhs
    }

    static func - (lhs: Matrix<Number>, rhs: Matrix<Number>) -> Matrix<Number> {
        var ret = Matrix(rows: lhs.rows, columns: lhs.columns, with: lhs.buffer[0].sumDefault)
        for i in 0..<ret.rows {
            for j in 0..<ret.columns {
                ret.setAt(row: i, column: j, to: lhs.getAt(row: i, column: j) - rhs.getAt(row: i, column: j))
            }
        }
        return ret
    }

    static func - (lhs: Matrix<Number>, rhs: Number) -> Matrix<Number> {
        let ret = Matrix(rows: lhs.rows, columns: lhs.columns, with: rhs)
        return lhs - ret
    }

    static func - (lhs: Number, rhs: Matrix<Number>) -> Matrix<Number> {
        return rhs - lhs
    }

    func maxRow(atCol column: Int) -> Int {
        var max = getAt(row: 0, column: column)
        var index = 0
        for i in 0..<rows {
            let temp = getAt(row: i, column: column)
            if temp > max {
                max = temp
                index = i
            }
        }

        return index
    }
}

extension Matrix: CustomStringConvertible {
    var description: String {
        var str = "\(self.rows) \(self.columns)\n"

        for i in 0..<self.rows {
            for j in 0..<self.columns {
                str += "\(self.getAt(row: i, column: j)) "
            }
            str += "\n"
        }
        return str
    }
}

extension Matrix {
    enum MatrixError: Error {
        case SizeMismatch(String)
    }
}
