import Foundation

func zip<T>(_ lhs: [T], _ rhs: [T]) -> [(T, T)] {
    var out = [(T, T)]()
    for i in 0..<lhs.count {
        out.append((lhs[i], rhs[i]))
    }
    return out
}

func makeBatch<T>(of source: [T], withSize size: Int) -> [[T]] {
    var out = [[T]]()
    var temp = [T]()
    for i in source {
        if temp.count == size {
            out.append(temp)
            temp = [T]()
        }
        temp.append(i)
    }

    if temp.count > 0 {
        out.append(temp)
    }

    return out
}

class Network {
    let numberOfLayers: Int
    let sizes: [Int]
    var biases: [Matrix<Double>] // Biases for col i+1
    var weights: [Matrix<Double>] // Weight for b <- a, i+2, i+1



    init(layersSize: [Int]) {
        let generator: (Int, Int) -> Double  = { _, _ in
            return Double.random(in: 0.0...1.0)
        }

        numberOfLayers = layersSize.count
        sizes = layersSize
        biases = [Matrix<Double>]()
        weights = [Matrix<Double>]()

        for i in 1..<sizes.count {
            biases.append(Matrix(rows: sizes[i], columns: 1, with: generator))
            weights.append(Matrix(rows: sizes[i], columns: sizes[i-1], with: generator))
        }
    }

    func feedForward(with input: Matrix<Double>) -> Matrix<Double>{
        var vec = input

        let generator: (Int, Int, Double) -> Double = { _, _, i in
            return i.sigmoid
        }

        for i in 0..<weights.count {
            vec = weights[i] * vec
            vec = vec + biases[i]
            vec.apply(with: generator)
        }

        return vec
    }

    func getLoss(from: Matrix<Double>, expect: Matrix<Double>) -> Double {
        let out = feedForward(with: from)
        return out.maxRow(atCol: 0) == out.maxRow(atCol: 0) ? 0 : 1
    }

    func SGD(input: [Matrix<Double>], output: [Matrix<Double>], epochs: Int = 2, batchSize: Int, eta: Double, testInput: [Matrix<Double>] = [Matrix<Double>](), testOutput: [Matrix<Double>] = [Matrix<Double>]()) {
        var trainPack: [(input: Matrix<Double>, output: Matrix<Double>)] = zip(input, output)
        let testPack: [(input: Matrix<Double>, output: Matrix<Double>)] = zip(testInput, testOutput)

        for epoch in 0..<epochs {
            print("BEGIN epoch: \(epoch)")
            trainPack.shuffle()

            let batches = makeBatch(of: trainPack, withSize: batchSize)

            for batch in batches {
                SGD(batch: batch, eta: eta)
            }

            evaluate(testPack)

            print("END epoch: \(epoch)")
        }
    }

    func SGD(batch: [(input: Matrix<Double>, output: Matrix<Double>)], eta: Double) {
        var `dBiases`: [Matrix<Double>] = [Matrix<Double>]()
        var `dWeights`: [Matrix<Double>] = [Matrix<Double>]()

        for i in 1..<sizes.count {
            dBiases.append(Matrix(rows: sizes[i], columns: 1, with: 0.0))
            dWeights.append(Matrix(rows: sizes[i], columns: sizes[i-1], with: 0.0))
        }

        for (input, output) in batch {
            let (ddBiases, ddWeights) = backpropagate(input, output)
            dBiases = zip(dBiases, ddBiases).map { return $0 + $1 }
            dWeights = zip(dWeights, ddWeights).map { return $0 + $1 }
        }

        biases = zip(biases, dBiases).map { return $0 + ((-eta/Double(batch.count)) * $1) }
        weights = zip(weights, dWeights).map { return $0 + ((-eta/Double(batch.count)) * $1) }
    }

    func backpropagate(_ input: Matrix<Double>, _ output: Matrix<Double>) -> ([Matrix<Double>], [Matrix<Double>]){
        var dBiases: [Matrix<Double>] = [Matrix<Double>]()
        var dWeights: [Matrix<Double>] = [Matrix<Double>]()

        for i in 1..<sizes.count {
            dBiases.append(Matrix(rows: sizes[i], columns: 1, with: 0.0))
            dWeights.append(Matrix(rows: sizes[i], columns: sizes[i-1], with: 0.0))
        }

        // FeedFoward

        var activation = input
        var activations = [input]
        var zVector = [Matrix<Double>]()

        for (bias, weight) in zip(biases, weights) {
            let z = (weight * activation) + bias
            zVector.append(z)
            activation = z
            activation.apply(with: { return $2.sigmoid })
            activations.append(activation)
        }

        var delta = costDerivative(activations.last!, output) * zVector.last!.map(with: { return $2.sigmoidPrime })
        dBiases[dBiases.count - 1] = delta
        dWeights[dWeights.count - 1] = delta * activations[activations.count - 2].transpose()

        for l in (2..<numberOfLayers-1).reversed() {
            let z = zVector[l]
            let sp = z.map(with: { return $2.sigmoidPrime })
            delta = weights[l+1].transpose() * delta * sp
            dBiases[l] = delta
            dWeights[l] = delta * activations[l - 1].transpose()
        }

        return (dBiases, dWeights)
    }

    func evaluate(_ batch: [(input: Matrix<Double>, output: Matrix<Double>)]) {
        var test: Double = 0
        var loss: Double = 0
        for i in batch {
            test += 1
            loss += getLoss(from: i.input, expect: i.output)
        }

        print("Loss/Test = \(loss / test)")
    }

    func costDerivative(_ output: Matrix<Double>, _ expected: Matrix<Double>) -> Matrix<Double> {
        return output - expected
    }
}

extension Double {
    var sigmoid: Double {
        get {
            return 1.0/(1.0 + exp(-self))
        }
    }

    var sigmoidPrime: Double {
        get {
            return self.sigmoid * (1 - self.sigmoid)
        }
    }
}