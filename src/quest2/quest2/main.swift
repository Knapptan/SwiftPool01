//
//  main.swift
//  quest2
//
//  Created by Knapptan on 15.01.2024.
//
import Foundation

//Расширение для маски номера
extension String {
    func applyPhoneNumberMask() -> String {
        // Проверяем длину номера
        if self.count > 12 || self.count < 11 {
            return self
        }
        
        // Удаляем все символы, кроме цифр
        let digits = self.filter { $0.isNumber }
        let startIndex = digits.index(digits.startIndex, offsetBy: 1)
        let endIndex = digits.index(digits.startIndex, offsetBy: 4)
        _ = digits[startIndex..<endIndex]
        
        // Проверяем начальные цифры и формируем операторский код
        guard let firstDigit = digits.first,
              let operatorCode = Int(digits[digits.index(digits.startIndex, offsetBy: 1)..<digits.index(digits.startIndex, offsetBy: 4)]),
              operatorCode != 0 else {
            return self
        }
        
        // Формируем маску в зависимости от условий
        var mask = ""
        if digits.count == 11, firstDigit == "8" && (operatorCode == 800 || operatorCode == 495) {
            // Если код оператора 800
            mask = "8 (xxx) xxx xx xx"
        } else if digits.count == 11, (firstDigit == "7" || firstDigit == "8") {
            // Для другого оператора
            mask = "+7 xxx xxx-xx-xx"
        } else {
            // Возвращаем оригинальную строку, если не соответствует условиям
            return self
        }
        
        // Заменяем 'x' на соответствующие цифры
        var index = 1
        for i in mask.indices {
            if mask[i] == "x" {
                guard index < digits.count else {
                    break  // Выходим, если достигнут конец строки
                }
                mask.replaceSubrange(i...i, with: String(digits[digits.index(digits.startIndex, offsetBy: index)]))
                index += 1
            }
        }
        
        return mask
    }
}

// Enum для перечисления типов инцидентов
enum IncidentType: String {
    case FIRE = "fire"
    case GAS = "gas leak"
    case CAT = "cat on the tree"
}

// Класс для представления инцидента
class Incident {
    var coordinates: (Int, Int)
    var description: String
    var applicantNumber: String?
    var incidentType: IncidentType?

    init(description: String, applicantNumber: String?, incidentType: IncidentType?, coordinates: (Int, Int)) {
        self.coordinates = coordinates
        self.description = description
        self.applicantNumber = applicantNumber
        self.incidentType = incidentType
    }
}

// Enum для представления формы зоны
enum ZoneShape {
    case circle(center: (Int, Int), radius: Int)
    case triangle(points: [(Int, Int)])
    case quadrilateral(points: [(Int, Int)])
}

// Класс для представления зоны
class Zone {
    var phoneNumber: String
    var name: String
    var emergencyDeptCode: String
    var dangerLevel: String
    var shape: ZoneShape
    
    init(phoneNumber: String, name: String, emergencyDeptCode: String, dangerLevel: String, shape: ZoneShape){
        self.phoneNumber = phoneNumber
        self.name = name
        self.emergencyDeptCode = emergencyDeptCode
        self.dangerLevel = dangerLevel
        self.shape = shape
    }
    // Метод для определения, произошел ли инцидент внутри зоны
    func isIncidentInside(incident: Incident) -> Bool {
        switch shape {
        case let .circle(center, radius):
            let distanceSquared = pow(Decimal(incident.coordinates.0 - center.0), 2) + pow(Decimal(incident.coordinates.1 - center.1), 2)
            return distanceSquared < pow(Decimal(radius), 2)
        case let .triangle(points):
            // Логика для определения, находится ли инцидент внутри треугольной зоны
            let pointA = points[0]
            let pointB = points[1]
            let pointC = points[2]
            let isInsideTriangle = isPointInsideTriangle(incident.coordinates, pointA, pointB, pointC)
            return isInsideTriangle
        case let .quadrilateral(points):
            // Логика для определения, находится ли инцидент внутри четырехугольной зоны
            let pointA = points[0]
            let pointB = points[1]
            let pointC = points[2]
            let pointD = points[3]
            let isInsideQuadrilateral = isPointInsideQuadrilateral(incident.coordinates, pointA, pointB, pointC, pointD)
            return isInsideQuadrilateral
        }
    }
}

func parseCoordinates(_ input: String) -> (Int, Int)? {
    let components = input.components(separatedBy: ";")
    guard components.count == 2,
        let x = Int(components[0].trimmingCharacters(in: .whitespaces)),
        let y = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
    }
    return (x, y)
}

func parseCoordinatesCircle(_ input: String) -> ((Int, Int), Int)? {
    let components = input.components(separatedBy: " ")
    guard components.count == 2,
        let xy = parseCoordinates(components[0].trimmingCharacters(in: .whitespaces)),
        let r = Int(components[1].trimmingCharacters(in: .whitespaces)) else {
            return nil
    }
    return (xy, r)
}

func parseCoordinatesTriangle(_ input: String) -> [(Int, Int)]? {
    let components = input.components(separatedBy: " ")
    var parametrs: [(Int, Int)] = []
    
    if components.count == 3 {
        for element in components {
            if let xy = parseCoordinates(element) {
                parametrs.append(xy)
            } else {
                return nil
            }
        }
    } else {
        return nil
    }
    
    return parametrs
}

//Эта функция использует расстояние между точками и сравниввает его с радиусом
func parseCoordinatesQuadrilateral(_ input: String) -> [(Int, Int)]? {
    let components = input.components(separatedBy: " ")
    var parametrs: [(Int, Int)] = []
    
    if components.count == 4 {
        for element in components {
            if let xy = parseCoordinates(element) {
                parametrs.append(xy)
            } else {
                return nil
            }
        }
    } else {
        return nil
    }
    
    return parametrs
}

//Эта функция использует метод "барицентрических координат" для определения, находится ли точка внутри треугольника.
//Барицентрические координаты представляют собой способ описания точки относительно вершин треугольника.
func isPointInsideTriangle(_ point: (Int, Int), _ vertex1: (Int, Int), _ vertex2: (Int, Int), _ vertex3: (Int, Int)) -> Bool {
    let x = point.0
    let y = point.1

    let x1 = vertex1.0
    let y1 = vertex1.1
    let x2 = vertex2.0
    let y2 = vertex2.1
    let x3 = vertex3.0
    let y3 = vertex3.1

    let d1 = (x - x1) * (y2 - y1) - (x2 - x1) * (y - y1)
    let d2 = (x - x2) * (y3 - y2) - (x3 - x2) * (y - y2)
    let d3 = (x - x3) * (y1 - y3) - (x1 - x3) * (y - y3)

    let hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0)
    let hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0)

    return !(hasNeg && hasPos)
}
//Эта функция использует метод для треуголиника 2 раза
func isPointInsideQuadrilateral(_ point: (Int, Int), _ vertex1: (Int, Int), _ vertex2: (Int, Int), _ vertex3: (Int, Int), _ vertex4: (Int, Int)) -> Bool {
    return isPointInsideTriangle(point, vertex1, vertex2, vertex3) || isPointInsideTriangle(point, vertex1, vertex3, vertex4)
}

// Начало исполенния скрипта

print("Enter zone parameters:")
guard let zoneParameters = readLine() else {
    print("Error reading zone parameters.")
    exit(1)
}

print("Enter the shape of area:")
guard let shapeArea = readLine() else {
    print("Error reading shape of area.")
    exit(1)
}
if !(shapeArea == "circle" || shapeArea == "triangle" || shapeArea == "quadrilateral"){
    print("Error reading shape of area insert 'circle' or 'triangle', or 'quadrilateral'.")
    exit(1)
}

print("Enter the zone info:")
print("Enter phone number:")
guard let phoneNumber = readLine() else {
    print("Error reading phone number.")
    exit(1)
}

print("Enter name:")
guard let name = readLine() else {
    print("Error reading name.")
    exit(1)
}

print("Enter emergency dept:")
guard let emergencyDeptCode = readLine() else {
    print("Error reading emergency department code.")
    exit(1)
}

print("Enter danger level:")
guard let dangerLevel = readLine() else {
    print("Error reading danger level.")
    exit(1)
}

if !(dangerLevel == "low" || dangerLevel == "medium" || dangerLevel == "hight"){
    print("Error reading danger level insert 'low' or 'medium', or 'hight'.")
    exit(1)
}

var zone: Zone?

if shapeArea == "circle" {
    guard let areaParameters = parseCoordinatesCircle(zoneParameters) else {
        print("Error reading parameters of circle area")
        exit(1)
    }
    zone = Zone(phoneNumber: phoneNumber.applyPhoneNumberMask(), name: name, emergencyDeptCode: emergencyDeptCode, dangerLevel: dangerLevel, shape: .circle(center: areaParameters.0, radius: areaParameters.1))
} else if shapeArea == "triangle" {
    guard let areaParameters = parseCoordinatesTriangle(zoneParameters) else {
        print("Error reading parameters of triangle area")
        exit(1)
    }
    zone = Zone(phoneNumber: phoneNumber.applyPhoneNumberMask(), name: name, emergencyDeptCode: emergencyDeptCode, dangerLevel: dangerLevel, shape: .triangle(points: areaParameters))
} else if shapeArea == "quadrilateral" {
    guard let areaParameters = parseCoordinatesQuadrilateral(zoneParameters) else {
        print("Error reading parameters of quadrilateral area")
        exit(1)
    }
    zone = Zone(phoneNumber: phoneNumber.applyPhoneNumberMask(), name: name, emergencyDeptCode: emergencyDeptCode, dangerLevel: dangerLevel, shape: .quadrilateral(points: areaParameters))
}

print("Enter an accident coordinates:")
guard let incidentCoordinatesInput = readLine() else {
    print("Error reading coordinates.")
    exit(1)
}

let incidentCoordinates = parseCoordinates(incidentCoordinatesInput)

print("Enter the accident info:")
print("Enter description:")
guard let incidentDescription = readLine() else {
    print("Error reading description.")
    exit(1)
}

print("Enter phone number:")
let incidentPhoneNumber = readLine()

var incident: Incident?

print("Enter type:")
if let incidentTypeString = readLine(), let incidentType = IncidentType(rawValue: incidentTypeString.lowercased()) {
    incident = Incident(description: incidentDescription, applicantNumber: incidentPhoneNumber?.applyPhoneNumberMask(), incidentType: incidentType, coordinates: incidentCoordinates!)
} else {
    print("Incorrect input for incident type.")
    exit(1)
}

if zone?.isIncidentInside(incident: incident!) == true {
    print("An accident is in \(name)")
} else {
    print("An accident is not in \(name)")
    print("Switch the applicant to the common number: 8 (800) 847 38 24")
}
print("Zone phone number: \(zone?.phoneNumber ?? "N/A")")
print("Applicant number: \(incident?.applicantNumber ?? "N/A")")
