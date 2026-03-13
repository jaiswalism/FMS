import Foundation

extension Trip {
    var routeTexts: (startText: String, endText: String) {
        let start = startName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let end = endName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let startText = start.isEmpty ? "Start" : start
        let endText = end.isEmpty ? "End" : end
        return (startText, endText)
    }
    
    var displayRoute: String {
        let startRaw = startName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let endRaw = endName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !startRaw.isEmpty && !endRaw.isEmpty {
            let texts = routeTexts
            return "\(texts.startText) to \(texts.endText)"
        }
        return "Trip"
    }
    
    var displayTitle: String {
        let shipment = shipmentDescription?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !shipment.isEmpty { return shipment }
        return displayRoute
    }
}
