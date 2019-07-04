import Foundation

assert(CommandLine.arguments.count >= 2)

let pathToResource = CommandLine.arguments[1]

let pathTrainImages = "\(pathToResource)/train-images.idx3-ubyte"
let pathTrainLabels = "\(pathToResource)/train-labels.idx1-ubyte"
let pathTestImages = "\(pathToResource)/t10k-images.idx3-ubyte"
let pathTestLabels = "\(pathToResource)/t10k-labels.idx1-ubyte"

let trainLabels = try! NIST.readLabels(pathTrainLabels)
let trainImages = try! NIST.readImages(pathTrainImages)
let testLabels = try! NIST.readLabels(pathTestLabels)
let testImages = try! NIST.readImages(pathTestImages)
