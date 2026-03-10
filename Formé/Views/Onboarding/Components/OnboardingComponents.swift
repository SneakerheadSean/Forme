//
//  OnboardingComponents.swift
//  Formé
//
//  Created by Sean Hughes on 3/5/26.
//  Shared UI primitives used across all onboarding steps.

import Foundation
import SwiftUI

// MARK: - Color Palette

extension Color {
    static let appBackground    = Color(hex: "0A0A0A")
    static let appCard          = Color(hex: "1C1C1E")
    static let appAccent        = Color(hex: "FF6B35")      // Orange accent
    static let appAccentSoft    = Color(hex: "FF6B35").opacity(0.15)
    static let appTextPrimary   = Color.white
    static let appTextSecondary = Color(hex: "8E8E93")
    static let appBorder        = Color(hex: "2C2C2E")
}

// MARK: - Progress Bar

struct OnboardingProgressBar: View {
    let progress: Double    // 0.0 → 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.appBorder)
                    .frame(height: 3)

                Capsule()
                    .fill(Color.appAccent)
                    .frame(width: geo.size.width * progress, height: 3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    init(
        title: String,
        isLoading: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title     = title
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action    = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(isEnabled ? Color.appAccent : Color.appBorder)

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 56)
        }
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

// MARK: - Ghost / Secondary Button

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.appTextSecondary)
                .frame(height: 44)
        }
    }
}

// MARK: - Selection Card (Goal / Activity cards)

struct SelectionCard<T: Equatable>: View {
    let value: T
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selection: T

    var isSelected: Bool { selection == value }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = value
            }
        } label: {
            HStack(spacing: 16) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.appAccent : Color.appCard)
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(isSelected ? .white : Color.appTextSecondary)
                }

                // Labels
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appTextPrimary)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.appTextSecondary)
                }

                Spacer()

                // Checkmark
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.appAccent : Color.appBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.appAccent)
                            .frame(width: 22, height: 22)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.appAccent : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Labeled Text Field

struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            TextField(placeholder, text: $text)
                .font(.system(size: 17))
                .foregroundColor(.appTextPrimary)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(text.isEmpty ? Color.appBorder : Color.appAccent.opacity(0.6), lineWidth: 1)
                        )
                )
        }
    }
}

// MARK: - Step Header

struct StepHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.appTextPrimary)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Macro Badge

struct MacroBadge: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.appTextPrimary)
            + Text(unit)
                .font(.system(size: 13))
                .foregroundColor(.appTextSecondary)

            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(color.opacity(0.1))
        )
    }
}

