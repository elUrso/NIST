import Foundation

public class NIST {
    enum NISTError: Error {
        case InvalidHeader
    }
    
    public class Image {
        let source: ImageData
        
        public init(_ pic: ImageData) {
            source = pic
        }
        
        public var asFloatArray: [Float] {
            get {
                var floatArray = [Float]()
                for i in 0..<source.count {
                    floatArray.append(Float(source[i]) / 255)
                }
                
                return floatArray
            }
        }

        var asVector: Matrix<Double> {
            get {
                var matrix = Matrix<Double>(rows: source.count, columns: 1, with: 0.0)

                for i in 0..<source.count {
                    matrix.setAt(row: i, column: 0, to: Double(source[i]) / 255)
                }
                
                return matrix
            }
        }

        public func toString() -> String {
            var str = ""
            for i in 0..<28 {
                for j in 0..<28 {
                    str += "\(source[i*28+j].asColorChar)"
                }
                str += "\n"
            }
            return str
        }
    }
    
    public typealias ImageData = [UInt8]
    
    public static func readLabels(_ path: String) throws -> [Int8]  {
        
        let rawLabels = try Data(contentsOf: URL(fileURLWithPath: path))
        
        var ret = [Int8]()
        
        // Check Header
        if rawLabels.subdata(in: 0..<4) != Data([0,0,8,1]) {
            throw NISTError.InvalidHeader
        }
        
        let size = rawLabels.subdata(in: 4..<8).asBigUInt32!

        var i = 0
        while i < size {
            ret.append(rawLabels.subdata(in: (8+i)..<(9+i)).asInt8!)
            i += 1
        }
        
        return ret
    }
    
    public static func readImages(_ path: String) throws -> [Image]  {
        
        let rawImages = try Data(contentsOf: URL(fileURLWithPath: path))
        
        var ret = [Image]()
        
        // Check Header
        if rawImages.subdata(in: 0..<4) != Data([0,0,8,3]) {
            throw NISTError.InvalidHeader
        }
        
        let size = rawImages.subdata(in: 4..<8).asBigUInt32!
        var i = 0
        while i < size {
            var tmp = ImageData()
            for j in 0..<784 {
                tmp.append(rawImages[16 + i * 784 + j])
            }
            ret.append(Image(tmp))
            i += 1
        }
        
        return ret
    }
}

extension UInt8 {
    var asColorChar: String {
        get {
            if self > 240 {
                return "#"
            }
            if self > 200 {
                return "0"
            }
            if self > 150 {
                return "x"
            }
            if self > 100 {
                return "o"
            }
            if self > 50 {
                return "*"
            }
            if self > 20 {
                return "."
            }
            return " "
        }
    }
}

extension Int8 {
    var asVector: Matrix<Double> {
        get {
            return Matrix<Double>(rows:10, columns: 1, with: {row, _ in
                    return (row == Int(self)) ? 0.0 : 1.0
                })
        }
    }
}

extension Data {
    var asInt8: Int8? {
        get {
            if self.count < 1 { return nil}
            return Int8(self[0])
        }
    }
    
    var asBigUInt32: UInt32? {
        get {
            if self.count < 4 { return nil }
            
            let number =
                UInt32(self[0]) << 24 +
                UInt32(self[1]) << 16 +
                UInt32(self[2]) << 8 +
                UInt32(self[3])
            
            /*let bigUInt32 = self[0..<4].withUnsafeBytes {
                (pointer: UnsafeRawBufferPointer) -> UInt32 in
                return pointer.load(as: UInt32.self)
            }*/
            return number
        }
    }
}
