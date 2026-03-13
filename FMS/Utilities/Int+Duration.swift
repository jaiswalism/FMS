extension Int {
    var formattedDuration: String {
        let sign = self < 0 ? "-" : ""
        let totalMinutes = self.magnitude
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return "\(sign)\(hours)h \(minutes)m"
    }
}
