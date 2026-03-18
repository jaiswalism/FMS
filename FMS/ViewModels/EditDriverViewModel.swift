import Foundation
import Observation
import Supabase

// MARK: - EditDriverViewModel

/// ViewModel for the Edit Driver screen.
///
/// On load, fetches the full driver record from the `users` table so all
/// fields (email, licenseNumber, licenseExpiry) are pre-filled even if
/// they were not available in the lightweight `DriverDisplayItem`.
///
/// On save, writes the edited fields back to the `users` table directly.
@Observable
@MainActor
public final class EditDriverViewModel {

  // MARK: - Identity (immutable)
  public let driverId: String

  // MARK: - Editable Fields
  public var name: String
  public var phone: String
  public var licenseNumber: String = ""
  public var licenseExpiry: Date =
    Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

  // MARK: - Read-only Display
  public var email: String = ""

  // MARK: - State
  public var isFetching: Bool = false
  public var isSaving: Bool = false
  public var fetchError: String? = nil
  public var saveError: String? = nil
  public var saveSuccess: Bool = false

  // MARK: - Validation

  public var isValid: Bool {
    let nameOK = !name.trimmingCharacters(in: .whitespaces).isEmpty
    let licenseOK = !licenseNumber.trimmingCharacters(in: .whitespaces).isEmpty
    let today = Calendar.current.startOfDay(for: Date())
    let expiryDay = Calendar.current.startOfDay(for: licenseExpiry)
    let expiryOK = expiryDay >= today
    return nameOK && licenseOK && expiryOK
  }

  // MARK: - Init

  public init(driverId: String, name: String, phone: String?) {
    self.driverId = driverId
    self.name = name
    self.phone = phone ?? ""
  }

  // MARK: - Narrow Fetch Model
  //
  // Only selects the 5 columns we actually need.
  // All dates are decoded as String? to avoid DecodingErrors caused by
  // Postgres date/timestamptz format mismatches with Swift's default JSONDecoder.

  private struct DriverRecord: Decodable {
    let name: String
    let email: String?
    let phone: String?
    let license_number: String?
    let license_expiry: String?  // "YYYY-MM-DD" or ISO8601, decoded safely as String
  }

  // MARK: - Fetch Full Record

  /// Fetches only the 5 editable columns from the `users` row.
  /// Dates are decoded as raw strings and converted locally,
  /// preventing DecodingError crashes from Postgres date formats.
  public func fetchDriverDetails() async {
    isFetching = true
    do {
      let record: DriverRecord = try await SupabaseService.shared.client
        .from("users")
        .select("name, email, phone, license_number, license_expiry")
        .eq("id", value: driverId)
        .eq("is_deleted", value: false)
        .single()
        .execute()
        .value

      self.email = record.email ?? ""
      self.name = record.name
      self.phone = record.phone ?? ""
      self.licenseNumber = record.license_number ?? ""
      if let expiryStr = record.license_expiry,
        let parsed = Self.parseDate(expiryStr)
      {
        self.licenseExpiry = parsed
      }
    } catch {
      fetchError = error.localizedDescription
    }
    isFetching = false
  }

  // MARK: - Date Parsing Helper

  /// Tries multiple date formats returned by Supabase/Postgres:
  ///   1. "YYYY-MM-DD"  (date column)
  ///   2. ISO8601 with fractional seconds + offset ("YYYY-MM-DDTHH:mm:ss+00:00")
  ///   3. ISO8601 basic
  private static func parseDate(_ raw: String) -> Date? {
    // Try standard date-only format first (most common for license_expiry)
    let plain = DateFormatter()
    plain.locale = Locale(identifier: "en_US_POSIX")
    plain.dateFormat = "yyyy-MM-dd"
    if let d = plain.date(from: raw) { return d }

    // Try ISO8601 with fractional seconds
    let isoFrac = ISO8601DateFormatter()
    isoFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = isoFrac.date(from: raw) { return d }

    // Try ISO8601 without fractional seconds
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime]
    if let d = iso.date(from: raw) { return d }

    return nil
  }

  // MARK: - Update

  /// Updates `name`, `phone`, `license_number`, and `license_expiry`
  /// on the `users` table in Supabase.
  public func updateDriver() async {
    isSaving = true
    do {
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withFullDate]

      struct UpdatePayload: Encodable {
        let name: String
        let phone: String
        let license_number: String
        let license_expiry: String

        enum CodingKeys: String, CodingKey {
          case name
          case phone
          case license_number
          case license_expiry
        }
      }

      let payload = UpdatePayload(
        name: name.trimmingCharacters(in: .whitespaces),
        phone: phone.trimmingCharacters(in: .whitespaces),
        license_number: licenseNumber.trimmingCharacters(in: .whitespaces),
        license_expiry: formatter.string(from: licenseExpiry)
      )

      try await SupabaseService.shared.client
        .from("users")
        .update(payload)
        .eq("id", value: driverId)
        .eq("is_deleted", value: false)
        .execute()
      saveSuccess = true
    } catch {
      saveError = error.localizedDescription
    }
    isSaving = false
  }
}
