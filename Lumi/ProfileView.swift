import SwiftUI
import PhotosUI

struct ProfileView: View {
    @AppStorage("savedUsername") private var savedUsername: String = ""
    // same key used in onboarding and ready by AvatarView and HomeView
    @AppStorage("savedProfileImageData") private var savedProfileImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    // Change username
    @State private var showRenameAlert = false
    @State private var draftUsername = ""
    @Environment(TaskStore.self) private var store
    @State private var preference1: String = "Romance"
    @State private var preference2: String = "History"
    @State private var preference3: String = "Drama"
    
    //Genres on the menu
    let availableGenres = ["Romance", "Action", "Comedy", "Drama", "Sci-Fi", "Horror", "Documentary", "Thriller","Crime","History"]
    
    var body: some View {
        NavigationStack {
        ScrollView {
            
            VStack(spacing: 50) {
                
                //Profile
                VStack(spacing: 16) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            AvatarView()
                                .frame(width: 160, height: 160)
                                .clipShape(Circle())
                                .background(
                                    Circle().fill(Color.white)
                                )
                                .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Circle().fill(Color.appGreen))
                                .overlay(Circle().stroke(Color.appBackground, lineWidth: 3))
                        }
                    }
                    .buttonStyle(.plain)
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data),
                               let jpeg = Self.downscaled(uiImage, maxSide: 600).jpegData(compressionQuality: 0.8) {
                                savedProfileImageData = jpeg
                            }
                            selectedPhotoItem = nil
                        }
                    }

    
                    Spacer()
              
                    // Tap the name to change it
                    Button {
                        // "Guest" is not a real name: start from an empty field so you can just type
                        draftUsername = savedUsername == ProfileSetupView.guestName ? "" : savedUsername
                        showRenameAlert = true
                    } label: {
                        HStack(spacing: 8) {
                            Text(savedUsername)
                                .font(.title.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)

                            Image(systemName: "pencil")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.black)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Change username")
                    .padding(.horizontal, 30)
                }
                .padding(.top, 60)
                .alert("Change username", isPresented: $showRenameAlert) {
                    TextField("Username", text: $draftUsername)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save") {
                        // same rule as the onboarding: empty = Guest
                        let name = draftUsername.trimmingCharacters(in: .whitespacesAndNewlines)
                        savedUsername = name.isEmpty ? ProfileSetupView.guestName : name
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Leave it empty to continue as \(ProfileSetupView.guestName).")
                }
                
                //  History (Horizontal scrolling)
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text("HISTORY")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        NavigationLink(destination: HistoryView()) {
                            Image(systemName: "chevron.right")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.appDarkGreen)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    if store.completedTasks.isEmpty {
                        // until you complete a task
                        Text("Complete a task to see it here.")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .fill(Color.appTan.opacity(0.15))
                            )
                            .padding(.horizontal, 30)
                    } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(store.completedTasks) { completed in
                                VStack(spacing: 12) {
                                    PhotoView(name: completed.item.photo, url: completed.item.imageURL)
                                        .frame(width: 100, height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                                    Text(completed.item.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.black)
                                        .lineLimit(1)
                                        .frame(width: 110)
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom, 10)
                    }
                    }
                }

                Spacer(minLength: 140)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        }
    }
}

extension ProfileView {
    static func downscaled(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxSide else { return image }
        let scale = maxSide / longest
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

struct PreferenceMenu: View {
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Menu {
            Picker("Genre", selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
        } label: {
            Text(selection.isEmpty ? "       " : selection)
                //adjusting font for better readibility
                .font(.callout.weight(.medium))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(selection.isEmpty ? Color.appLightGray.opacity(0.5) : Color.appTan.opacity(0.3))
                )
        }
    }
}
