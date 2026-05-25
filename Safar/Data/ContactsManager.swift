//
//  ContactsManager.swift
//  Safar
//
//  Utility for hashing phone numbers from the device contacts book.
//  Normalisation and SHA-256 happen entirely on-device; raw phone numbers
//  are never transmitted to the server.
//

import Contacts
import CryptoKit
import Foundation

// MARK: - Errors

enum ContactsPermissionError: LocalizedError {
    case denied
    case restricted

    var errorDescription: String? {
        switch self {
        case .denied:
            return "Contacts access was denied. Enable it in Settings to find friends."
        case .restricted:
            return "Contacts access is restricted on this device."
        }
    }
}

// MARK: - ContactsManager

struct ContactsManager {

    // MARK: Phone Normalisation

    /// Combine a country-code field (e.g. "+1") and a local number field
    /// (e.g. "613 555 1234") into an E.164-formatted string (e.g. "+16135551234").
    /// Returns `nil` when the combined digit count is outside the E.164 range (7–15).
    static func normalizePhone(countryCode: String, number: String) -> String? {
        let countryDigits = countryCode.filter(\.isNumber)
        let numberDigits = number.filter(\.isNumber)
        let combined = countryDigits + numberDigits
        guard combined.count >= 7, combined.count <= 15 else { return nil }
        return "+\(combined)"
    }

    /// Normalise a raw phone string that already contains a country code prefix.
    /// Useful when processing contacts from the address book where numbers are
    /// stored in mixed formats like "+1 (613) 555-1234" or "6135551234".
    static func normalizeRawPhone(_ raw: String) -> String? {
        let hasPlus = raw.trimmingCharacters(in: .whitespaces).hasPrefix("+")
        let digits = raw.filter(\.isNumber)

        guard !digits.isEmpty else { return nil }

        if hasPlus {
            // Already has a country code
            guard digits.count >= 7, digits.count <= 15 else { return nil }
            return "+\(digits)"
        } else if digits.count == 10 {
            // Assume North American (no country code provided)
            return "+1\(digits)"
        } else if digits.count == 11, digits.hasPrefix("1") {
            // 11-digit North American with leading 1
            return "+\(digits)"
        } else {
            guard digits.count >= 7, digits.count <= 15 else { return nil }
            return "+\(digits)"
        }
    }

    // MARK: Hashing

    /// Returns the lowercase hex-encoded SHA-256 digest of `input`.
    static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: Contact Enumeration

    /// Requests Contacts permission (if needed) then returns a deduplicated
    /// array of SHA-256 hashes of every E.164-normalised phone number found
    /// in the device address book.
    ///
    /// Throws `ContactsPermissionError` if access is denied or restricted.
    /// The `CNContactStore` enumeration is synchronous and runs on a detached
    /// background task to avoid blocking the MainActor.
    func hashedPhoneNumbers() async throws -> [String] {
        let store = CNContactStore()

        // Request access if not already determined
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .notDetermined {
            let granted = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Bool, Error>) in
                store.requestAccess(for: .contacts) { granted, error in
                    if let error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: granted)
                    }
                }
            }
            guard granted else { throw ContactsPermissionError.denied }
        } else if status == .denied {
            throw ContactsPermissionError.denied
        } else if status == .restricted {
            throw ContactsPermissionError.restricted
        }

        // Enumerate contacts on a background thread (enumerateContacts is blocking)
        let hashes: Set<String> = try await Task.detached(priority: .userInitiated) {
            var result: Set<String> = []
            let keys = [CNContactPhoneNumbersKey as CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keys)

            try store.enumerateContacts(with: request) { contact, _ in
                for phone in contact.phoneNumbers {
                    if let e164 = Self.normalizeRawPhone(phone.value.stringValue) {
                        result.insert(Self.sha256(e164))
                    }
                }
            }
            return result
        }.value

        return Array(hashes)
    }
}
