//
//  HomeHeader.swift
//  Formé
//
//  Created by Sean Hughes on 3/3/26.
//
import SwiftUI

// MARK: - Greeting Helper

private func timeOfDayGreeting() -> (text: String, emoji: String) {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 5..<12:  return ("Good morning", "👋")
    case 12..<17: return ("Good afternoon", "☀️")
    case 17..<21: return ("Good evening", "🌆")
    default:      return ("Good night", "🌙")
    }
}

private func formattedDate() -> String {
    let f = DateFormatter()
    f.dateFormat = "EEEE, MMMM d"
    return f.string(from: Date())
}

// MARK: - Home Header View

struct HomeHeaderView: View {
    /// Replace with your real user profile binding later
    var userName: String = "Alex"

    @State private var appeared = false

    private let greeting = timeOfDayGreeting()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Greeting ──────────────────────────────────────
            HStack(alignment: .bottom, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting.text + ",")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(Color(UIColor.label))

                    HStack(alignment: .center, spacing: 8) {
                        Text(userName)
                            .font(.system(size: 34, weight: .bold, design: .default))
                            .foregroundColor(Color(UIColor.label))

                        Text(greeting.emoji)
                            .font(.system(size: 30))
                            // Subtle wave animation on the emoji
                            .rotationEffect(.degrees(appeared ? 0 : -20), anchor: .bottom)
                            .animation(
                                .interpolatingSpring(stiffness: 180, damping: 8)
                                    .delay(0.4),
                                value: appeared
                            )
                    }
                }
                Spacer()
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.easeOut(duration: 0.4), value: appeared)

            // ── Date ─────────────────────────────────────────
            Text(formattedDate())
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(UIColor.secondaryLabel))
                .padding(.top, 10)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 6)
                .animation(.easeOut(duration: 0.4).delay(0.12), value: appeared)

            // ── Divider ───────────────────────────────────────
            HStack(spacing: 0) {
                // Accent nub
                RoundedRectangle(cornerRadius: 99)
                    .fill(Color(UIColor.label))
                    .frame(width: appeared ? 28 : 0, height: 2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.65).delay(0.25), value: appeared)

                Rectangle()
                    .fill(Color(UIColor.separator).opacity(0.4))
                    .frame(height: 1)
                    .padding(.leading, 6)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(0.3), value: appeared)
            }
            .padding(.top, 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
    }
}

// MARK: - Full Home Screen (Header + Card together)

struct HomeView: View {
    var userName: String = "Alex"

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HomeHeaderView(userName: userName)
                    .padding(.horizontal, 24)
                    .padding(.top, 56) // safe area breathing room

                SummaryCard()
                    .padding(.horizontal, 0) // card handles its own horizontal padding
            }
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Preview

#Preview("Header only") {
    ZStack {
        Color(UIColor.systemGroupedBackground).ignoresSafeArea()
        HomeHeaderView(userName: "Alex")
            .padding(24)
    }
}

#Preview("Full Home") {
    HomeView(userName: "Alex")
}
