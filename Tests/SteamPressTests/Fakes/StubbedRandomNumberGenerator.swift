import SteamPress
import Vapor

struct StubbedRandomNumberGenerator: SteamPressRandomNumberGenerator {
    func `for`(_ request: Request) -> SteamPressRandomNumberGenerator {
        return StubbedRandomNumberGenerator(numberToReturn: self.numberToReturn)
    }
    
    let numberToReturn: Int
    
    init(numberToReturn: Int) {
        self.numberToReturn = numberToReturn
    }

    func getNumber() -> Int {
        return numberToReturn
    }
}
