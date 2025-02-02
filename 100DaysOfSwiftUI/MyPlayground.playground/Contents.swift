let team = ["Gloria", "Suzanne", "Piper", "Tiffany", "Tasha"]


let captainFirstTeam = team.sorted { (name1, name2) -> Bool in
    if name1 == "Suzanne" {
        return true
    } else if name2 == "Suzanne" {
        return false
    }
    
    return name1 < name2
}

let shorterClosure = team.sorted {
    if $0 == "Suzanne" {
        return true
    } else if $1 == "Suzanne" {
        return false
    }
    
    return $0 < $1
}

captainFirstTeam
