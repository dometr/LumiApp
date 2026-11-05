import SwiftUI
import PhotosUI

struct User: View {
    @AppStorage("savedUsername") private var savedUsername: String = ""

    var body: some View {
        if savedUsername.isEmpty {
            OnboardingFlowView()
        } else {
            MainView()
        }
    }
}

// 2. Onboarding Flow
struct OnboardingFlowView: View {
    @State private var showSetupStep = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            Group {
                if showSetupStep {
                    ProfileSetupView()
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    WelcomeScreen(showSetupStep: $showSetupStep)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
        }
    }
}

struct WelcomeScreen: View {
    @Binding var showSetupStep: Bool
    @AppStorage("savedUsername") private var savedUsername: String = ""

    var body: some View {
        VStack(spacing: 20) {
            // MARK: - Top Right Skip Button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut) {
                        savedUsername = ProfileSetupView.guestName
                    }
                }) {
                    Text("Skip")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.appDarkGreen)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            Text("Welcome!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("We're excited to have you here. Let's set up your profile to get started.")
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal)
            
            Spacer()
            
            // MARK: - Get Started Button
            Button(action: {
                withAnimation(.easeInOut) {
                    showSetupStep = true
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appDarkGreen)
        }
        .padding()
    }
}

struct ProfileSetupView: View {
    // Name used if left blank
    static let guestName = "Guest"

    @AppStorage("savedUsername") private var savedUsername: String = ""
    @AppStorage("savedProfileImageData") private var savedProfileImageData: Data?

    @State private var inputUsername: String = ""
    
    // Photo management
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    var body: some View {
        VStack(spacing: 25) {
            Text("Create Your Profile")
                .font(.title2)
                .fontWeight(.semibold)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 8) {
                    if let selectedImageData, let uiImage = UIImage(data: selectedImageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color.appTan.opacity(0.3))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "camera.fill")
                                .font(.title)
                                .foregroundColor(Color.appDarkGreen)
                        }
                    }

                    Text("Add Photo (Optional)")
                        .font(.footnote)
                        .foregroundColor(.black)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }

            //username
            VStack(spacing: 6) {
                TextField("Username (optional)", text: $inputUsername)
                    .textFieldStyle(.plain)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.black)
                    .tint(Color.appDarkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.appTan, lineWidth: 1)
                    )

                Text("Leave it empty to continue as \(Self.guestName).")
                    .font(.footnote)
                    .foregroundColor(.black)
            }

            // confirm button
            Button(action: {
                //save image
                if let selectedImageData {
                    savedProfileImageData = selectedImageData
                }
                
                // save username
                let name = inputUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                savedUsername = name.isEmpty ? Self.guestName : name
            }) {
                Text("Confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.appDarkGreen)
        }
        .padding()
    }
}

#Preview {
    User()
        .environment(TaskStore())
}
