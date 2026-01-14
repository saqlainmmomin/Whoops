import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var healthKitManager: HealthKitManager
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentStep: OnboardingStep = .welcome
    @State private var userName: String = ""
    @FocusState private var isNameFieldFocused: Bool

    enum OnboardingStep {
        case welcome
        case nameInput
        case healthKit
        case complete
    }

    var body: some View {
        ZStack {
            Theme.Colors.sovereignBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<4) { index in
                        Capsule()
                            .fill(stepIndex >= index ? Theme.Colors.neonTeal : Theme.Colors.panelGray)
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)

                Spacer()

                // Content based on step
                Group {
                    switch currentStep {
                    case .welcome:
                        welcomeContent
                    case .nameInput:
                        nameInputContent
                    case .healthKit:
                        healthKitContent
                    case .complete:
                        completeContent
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Bottom button
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    private var stepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .nameInput: return 1
        case .healthKit: return 2
        case .complete: return 3
        }
    }

    // MARK: - Welcome Step

    private var welcomeContent: some View {
        VStack(spacing: 32) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(Theme.Colors.neonTeal.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 70))
                    .foregroundColor(Theme.Colors.neonTeal)
            }

            VStack(spacing: 16) {
                Text("WHOOPS")
                    .font(Theme.Fonts.header(size: 42))
                    .foregroundColor(.white)
                    .tracking(4)

                Text("Your body's data, decoded")
                    .font(Theme.Fonts.tensor(size: 16))
                    .foregroundColor(Theme.Colors.textGray)
            }

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "heart.fill", text: "Track Recovery & Strain", color: Theme.Colors.neonTeal)
                featureRow(icon: "bed.double.fill", text: "Analyze Sleep Quality", color: Theme.Colors.neonGreen)
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Build Better Habits", color: Theme.Colors.neonGold)
            }
            .padding(.top, 20)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Name Input Step

    private var nameInputContent: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Text("WHAT'S YOUR NAME?")
                    .font(Theme.Fonts.header(size: 24))
                    .foregroundColor(.white)
                    .tracking(2)

                Text("This helps personalize your experience")
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(Theme.Colors.textGray)
            }

            VStack(spacing: 8) {
                TextField("", text: $userName, prompt: Text("Enter your name").foregroundColor(Theme.Colors.textGray.opacity(0.5)))
                    .font(Theme.Fonts.tensor(size: 24))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($isNameFieldFocused)
                    .padding(.vertical, 16)

                Rectangle()
                    .fill(isNameFieldFocused ? Theme.Colors.neonTeal : Theme.Colors.panelGray)
                    .frame(height: 2)
                    .animation(.easeInOut, value: isNameFieldFocused)
            }
            .padding(.horizontal, 40)
        }
        .padding(.horizontal, 32)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }

    // MARK: - HealthKit Step

    private var healthKitContent: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.neonRed.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .blur(radius: 15)

                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.neonRed)
            }

            VStack(spacing: 16) {
                Text("CONNECT APPLE HEALTH")
                    .font(Theme.Fonts.header(size: 20))
                    .foregroundColor(.white)
                    .tracking(2)

                Text("We'll read your health data to calculate Recovery, Strain, and personalized insights")
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(Theme.Colors.textGray)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                healthDataRow(icon: "heart.fill", text: "Heart Rate & HRV")
                healthDataRow(icon: "bed.double.fill", text: "Sleep Analysis")
                healthDataRow(icon: "figure.run", text: "Workouts & Activity")
                healthDataRow(icon: "flame.fill", text: "Energy Burned")
            }
            .padding(20)
            .background(Theme.Colors.panelGray)
            .cornerRadius(16)

            Text("All data stays on your device")
                .font(Theme.Fonts.label(size: 12))
                .foregroundColor(Theme.Colors.textGray)
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Complete Step

    private var completeContent: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.neonGreen.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.neonGreen)
            }

            VStack(spacing: 16) {
                Text("YOU'RE ALL SET")
                    .font(Theme.Fonts.header(size: 28))
                    .foregroundColor(.white)
                    .tracking(2)

                if !userName.isEmpty {
                    Text("Welcome, \(userName)")
                        .font(Theme.Fonts.tensor(size: 18))
                        .foregroundColor(Theme.Colors.neonTeal)
                }

                Text("Your health analytics are ready")
                    .font(Theme.Fonts.tensor(size: 14))
                    .foregroundColor(Theme.Colors.textGray)
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Bottom Button

    private var bottomButton: some View {
        Button {
            handleButtonTap()
        } label: {
            Text(buttonTitle)
                .font(Theme.Fonts.header(size: 18))
                .foregroundColor(buttonTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(buttonBackground)
                .cornerRadius(14)
        }
        .disabled(isButtonDisabled)
        .opacity(isButtonDisabled ? 0.5 : 1)
    }

    private var buttonTitle: String {
        switch currentStep {
        case .welcome: return "Get Started"
        case .nameInput: return "Continue"
        case .healthKit: return "Connect Apple Health"
        case .complete: return "Start Using Whoops"
        }
    }

    private var buttonTextColor: Color {
        currentStep == .complete ? .black : .white
    }

    private var buttonBackground: some View {
        Group {
            if currentStep == .complete {
                Theme.Colors.neonTeal
            } else {
                Theme.Colors.panelGray
            }
        }
    }

    private var isButtonDisabled: Bool {
        currentStep == .nameInput && userName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func handleButtonTap() {
        switch currentStep {
        case .welcome:
            withAnimation {
                currentStep = .nameInput
            }
        case .nameInput:
            withAnimation {
                currentStep = .healthKit
            }
        case .healthKit:
            Task {
                await healthKitManager.requestAuthorization()
                if healthKitManager.authorizationStatus == .authorized {
                    // Save user profile
                    saveUserProfile()
                    // Fetch characteristics
                    await healthKitManager.fetchUserCharacteristics(modelContext: modelContext)
                    withAnimation {
                        currentStep = .complete
                    }
                }
            }
        case .complete:
            saveUserProfile()
            hasCompletedOnboarding = true
        }
    }

    private func saveUserProfile() {
        let trimmedName = userName.trimmingCharacters(in: .whitespaces)
        let profile = UserProfile(name: trimmedName.isEmpty ? "User" : trimmedName)
        modelContext.insert(profile)
        try? modelContext.save()
    }

    // MARK: - Helper Views

    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)

            Text(text)
                .font(Theme.Fonts.tensor(size: 16))
                .foregroundColor(.white)
        }
    }

    private func healthDataRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.neonRed)
                .frame(width: 24)

            Text(text)
                .font(Theme.Fonts.tensor(size: 14))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environmentObject(HealthKitManager())
}
