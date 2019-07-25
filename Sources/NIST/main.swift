import Foundation

assert(CommandLine.arguments.count >= 2, "Missing Bundle Path")

let pathToResource = CommandLine.arguments[1]

let pathTrainImages = "\(pathToResource)/train-images.idx3-ubyte"
let pathTrainLabels = "\(pathToResource)/train-labels.idx1-ubyte"
let pathTestImages = "\(pathToResource)/t10k-images.idx3-ubyte"
let pathTestLabels = "\(pathToResource)/t10k-labels.idx1-ubyte"

let trainLabels = try! NIST.readLabels(pathTrainLabels)
let trainImages = try! NIST.readImages(pathTrainImages)
let testLabels = try! NIST.readLabels(pathTestLabels)
let testImages = try! NIST.readImages(pathTestImages)

var network = Network(layersSize: [784,30,10])

print(network.feedForward(with: Matrix<Double>(rows: 3, columns: 1, with: 1)))

network.SGD(    input: trainImages.map{ return $0.asVector },
                output: trainLabels.map{ return $0.asVector },
                epochs: 30,
                batchSize: 10,
                eta: 3.0,
                testInput: testImages.map{ return $0.asVector },
                testOutput: testLabels.map{ return $0.asVector })