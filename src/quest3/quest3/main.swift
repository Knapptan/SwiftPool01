//
//  main.swift
//  quest3
//
//  Created by Knapptan on 16.01.2024.
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
    // Метод для получения информации об инциденте
    func getIncidentInfo() -> String {
        return """
        The accident info:
          Description: \(description)
          Phone number: \(applicantNumber ?? "N/A")
          Type: \(incidentType?.rawValue ?? "N/A")
        """
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
    
    // Метод для получения информации о зоне
    func getZoneInfo() -> String {
        return """
        The zone info:
          The shape of area: \(getShapeDescription())
          Phone number: \(phoneNumber)
          Name: \(name)
          Emergency dept: \(emergencyDeptCode)
          Danger level: \(dangerLevel)
        """
    }

    // Вспомогательный метод для получения описания формы зоны
    private func getShapeDescription() -> String {
        switch shape {
        case .circle:
            return "circle"
        case .triangle:
            return "triangle"
        case .quadrilateral:
            return "quadrilateral"
        }
    }
}

// Класс для представления города
class City {
    var name: String
    var commonNumber: String
    var zones: [Zone]
    
    init(name: String, commonNumber: String, zones: [Zone]) {
        self.name = name
        self.commonNumber = commonNumber
        self.zones = zones
    }
    
    func determineIncidentLocation(incident: Incident) -> String {
        for zone in zones {
            if zone.isIncidentInside(incident: incident) {
                return """
The incident is in the \(zone.name)
 \(zone.getZoneInfo())
"""
            }
        }
        
        // Если инцидент не соответствует ни одной зоне, найдем ближайшую зону
        var nearestZone: Zone?
        var minDistanceSquared = Int.max
        
        for zone in zones {
            let distanceSquared = distanceSquaredFromIncidentToZone(incident: incident, zone: zone)
            if distanceSquared < minDistanceSquared {
                minDistanceSquared = distanceSquared
                nearestZone = zone
            }
        }
        
        guard let nearest = nearestZone else {
            return "The incident didn't match with any zone, and no nearest zone found."
        }
        
        return """
The incident didn't match with any zone.
The nearest zone is \(nearest.name)
\(nearest.getZoneInfo())
"""
    }
    
    private func distanceSquaredFromIncidentToZone(incident: Incident, zone: Zone) -> Int {
        // Расстояние между центром зоны и координатами инцидента
        let zoneCenter = getZoneCenter(zone: zone)
        let distanceSquared = pow(Double(incident.coordinates.0 - zoneCenter.0), 2) + pow(Double(incident.coordinates.1 - zoneCenter.1), 2)
        return Int(distanceSquared)
    }
    
    private func getZoneCenter(zone: Zone) -> (Int, Int) {
        switch zone.shape {
        case let .circle(center, _):
            return center
        case let .triangle(points), let .quadrilateral(points):
            // Логика для определения центра многоугольника (может потребоваться другой метод)
            let xValues = points.map { $0.0 }
            let yValues = points.map { $0.1 }
            let centerX = xValues.reduce(0, +) / points.count
            let centerY = yValues.reduce(0, +) / points.count
            return (centerX, centerY)
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

//Сам процесс
let zones: [Zone] = [
    Zone(phoneNumber: "82345678900".applyPhoneNumberMask(), name: "Market", emergencyDeptCode: "123", dangerLevel: "hight", shape: .circle(center: (0, 0), radius: 5)),
    Zone(phoneNumber: "89156543211".applyPhoneNumberMask(), name: "Pasture", emergencyDeptCode: "456", dangerLevel: "low", shape: .triangle(points: [(5, 5), (10, 5), (10, 10)])),
    Zone(phoneNumber: "88006543211".applyPhoneNumberMask(), name: "Farm", emergencyDeptCode: "336", dangerLevel: "medium", shape: .quadrilateral(points: [(-5, -5), (-10, -5), (-10, -10), (-15, -15)]))
    ,]

let city = City(name: "Novobobrovsk", commonNumber: "8 (800) 555 35 35", zones: zones)

// Ввод координат инцидента
print("Enter an accident coordinates:")
guard let incidentCoordinatesInput = readLine() else {
    print("Error reading coordinates.")
    exit(1)
}
guard let incidentCoordinates = parseCoordinates(incidentCoordinatesInput)else {
    print("Error parsing coordinates.")
    exit(1)
}
let incidentDescription = "the woman said her cat can't get off the tree"
let incidentPhoneNumber = "89347362826".applyPhoneNumberMask()
var incident: Incident?
let incidentTypeString = "cat on the tree"
let incidentType = IncidentType(rawValue: incidentTypeString.lowercased())
incident = Incident(description: incidentDescription, applicantNumber: incidentPhoneNumber.applyPhoneNumberMask(), incidentType: incidentType, coordinates: incidentCoordinates)

let result = city.determineIncidentLocation(incident: incident!)
print("""
The city info:
  Name: \(city.name)
  The common number: \(city.commonNumber)

\(incident!.getIncidentInfo())

\(result)
""")

