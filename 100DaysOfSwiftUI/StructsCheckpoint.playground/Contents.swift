"""
Create a struct to store information about a car, including its model, number of seats, and current gear, then add a method to change gears up or down.
"""


struct Car {
    let brand: String
    let model: String
    let numberOfSeats: Int
    let minGear = 1
    let maxGear = 6
    private(set) var currentGear = 1 {
        didSet {
            print("Current gear: \(currentGear)")
        }
    }
    
    mutating func changeGear(newGear: Int) {
        if newGear >= minGear && newGear <= maxGear{
            currentGear = newGear
        }
    }
    
    mutating func increaseGear() {
        if currentGear < maxGear {
            currentGear += minGear
        }
    }
    
    mutating func decreaseGear() {
        if currentGear > minGear {
            currentGear -= 1
        }
    }
}


var rivian = Car(brand: "Rivian", model: "R2", numberOfSeats: 5)
rivian.model
rivian.currentGear
rivian.changeGear(newGear: 5)
rivian.increaseGear()
rivian.decreaseGear()


