import SwiftUI

// MARK: - EditDriverView

/// Sheet presented from `DriverDetailView` when the fleet manager taps "Edit Driver".
///
/// Fetches the full driver record from Supabase on load, pre-fills all fields,
/// and writes changes back via `EditDriverViewModel.updateDriver()`.
struct EditDriverView: View {

  @Environment(\.dismiss) private var dismiss
  @State private var vm: EditDriverViewModel

  var onDriverUpdated: ((_ name: String, _ phone: String?) -> Void)?

  init(
    driverId: String,
    name: String,
    phone: String?,
    onDriverUpdated: ((_ name: String, _ phone: String?) -> Void)? = nil
  ) {
    _vm = State(initialValue: EditDriverViewModel(driverId: driverId, name: name, phone: phone))
    self.onDriverUpdated = onDriverUpdated
  }

  // MARK: - Body

  var body: some View {
    VStack(spacing: 0) {
      navBar
        .zIndex(1)

      if vm.isFetching {
        fetchingPlaceholder
      } else {
        formContent
      }
    }
    .background(FMSTheme.backgroundPrimary.ignoresSafeArea())
    .task { await vm.fetchDriverDetails() }
    .alert(
      "Error",
      isPresented: Binding(
        get: { vm.saveError != nil },
        set: { if !$0 { vm.saveError = nil } }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(vm.saveError ?? "")
    }
    .alert(
      "Failed to Load",
      isPresented: Binding(
        get: { vm.fetchError != nil },
        set: { if !$0 { vm.fetchError = nil } }
      )
    ) {
      Button("Retry") { Task { await vm.fetchDriverDetails() } }
      Button("Cancel", role: .cancel) { dismiss() }
    } message: {
      Text(vm.fetchError ?? "")
    }
    .overlay {
      if vm.isSaving {
        Color.black.opacity(0.25).ignoresSafeArea()
        ProgressView("Saving...")
          .padding(20)
          .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
      }
    }
    .onChange(of: vm.saveSuccess) { _, success in
      guard success else { return }
      let trimmedName = vm.name.trimmingCharacters(in: .whitespacesAndNewlines)
      let trimmedPhone = vm.phone.trimmingCharacters(in: .whitespacesAndNewlines)
      onDriverUpdated?(trimmedName, trimmedPhone.isEmpty ? nil : trimmedPhone)
      dismiss()
    }
    }
  }

  // MARK: - Nav Bar

  private var navBar: some View {
    HStack {
      Button {
        dismiss()
      } label: {
        Text("Cancel")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(FMSTheme.textPrimary)
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .background(FMSTheme.cardBackground)
          .clipShape(Capsule())
          .overlay(Capsule().strokeBorder(FMSTheme.borderLight, lineWidth: 1))
      }

      Spacer()

      Button {
        Task { await vm.updateDriver() }
      } label: {
        let canSave = vm.isValid && !vm.isFetching
        Text("Save")
          .font(.subheadline.weight(.semibold))
          .foregroundColor(canSave ? FMSTheme.amber : Color(.tertiaryLabel))
          .padding(.horizontal, 20)
          .padding(.vertical, 10)
          .background(canSave ? FMSTheme.amber.opacity(0.15) : FMSTheme.cardBackground)
          .clipShape(Capsule())
      }
      .disabled(!vm.isValid || vm.isSaving || vm.isFetching)
    }
    .padding(.horizontal, 16)
    .padding(.top, 24)
    .padding(.bottom, 16)
    .background(
      FMSTheme.backgroundPrimary
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    )
  }

  // MARK: - Fetching Placeholder

  private var fetchingPlaceholder: some View {
    VStack {
      Spacer()
      ProgressView("Loading driver details...")
        .foregroundStyle(FMSTheme.textSecondary)
      Spacer()
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Form Content

  private var formContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        Text("Edit Driver")
          .font(.title2.weight(.bold))
          .foregroundStyle(FMSTheme.textPrimary)
          .padding(.horizontal, 16)
          .padding(.top, 8)

        VStack(spacing: 32) {

          // MARK: Personal Information
          EditSectionGroup(title: "Personal Information") {
            VStack(spacing: 16) {

              EditFormField(
                label: "Full Name (Required)",
                text: $vm.name,
                placeholder: "Enter driver's full name"
              )
              .textInputAutocapitalization(.words)

              // Email is read-only (tied to auth account)
              if !vm.email.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                  Text("Email Address")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(FMSTheme.textSecondary)
                  HStack {
                    Text(vm.email)
                      .foregroundStyle(FMSTheme.textTertiary)
                    Spacer()
                    Text("Read-only")
                      .font(.caption)
                      .foregroundStyle(FMSTheme.textTertiary)
                  }
                  .padding(14)
                  .background(
                    RoundedRectangle(cornerRadius: 12)
                      .fill(FMSTheme.cardBackground.opacity(0.5))
                      .overlay(
                        RoundedRectangle(cornerRadius: 12)
                          .strokeBorder(FMSTheme.borderLight, lineWidth: 1)
                      )
                  )
                }
              }

              EditFormField(
                label: "Phone Number",
                text: $vm.phone,
                placeholder: "+91 9876543210"
              )
              .keyboardType(.phonePad)
            }
          }

          // MARK: License Verification
          EditSectionGroup(title: "License Verification") {
            VStack(spacing: 16) {

              EditFormField(
                label: "License Number (Required)",
                text: $vm.licenseNumber,
                placeholder: "DL-XXXXXXX"
              )
              .textInputAutocapitalization(.characters)
              .autocorrectionDisabled()

              VStack(alignment: .leading, spacing: 6) {
                Text("License Expiry")
                  .font(.footnote.weight(.semibold))
                  .foregroundStyle(FMSTheme.textSecondary)
                DatePicker(
                  "",
                  selection: $vm.licenseExpiry,
                  in: Calendar.current.startOfDay(for: Date())...,
                  displayedComponents: .date
                )
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(FMSTheme.cardBackground)
                    .overlay(
                      RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(FMSTheme.borderLight, lineWidth: 1)
                    )
                )
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 40)
      }
    }
    .background(FMSTheme.backgroundPrimary)
  }
}

// MARK: - Private Subviews

private struct EditSectionGroup<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 2)
          .fill(FMSTheme.amber)
          .frame(width: 4, height: 18)
        Text(title)
          .font(.headline)
          .foregroundStyle(FMSTheme.textPrimary)
      }
      content
    }
  }
}

private struct EditFormField: View {
  let label: String
  @Binding var text: String
  let placeholder: String

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.footnote.weight(.semibold))
        .foregroundStyle(FMSTheme.textSecondary)
      TextField(placeholder, text: $text)
        .foregroundStyle(FMSTheme.textPrimary)
        .padding(14)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(FMSTheme.cardBackground)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .strokeBorder(FMSTheme.borderLight, lineWidth: 1)
            )
        )
    }
  }
}
