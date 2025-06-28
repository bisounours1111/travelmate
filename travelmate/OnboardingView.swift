import SwiftUI

struct OnboardingItem: Hashable {
    var imageName: String;
    var title: String;
    var description: String;
    var tag: Int;
}

struct OnboardingView: View {
    @State var activeSlide: Int = 0;
    @Environment(\.colorScheme) var colorScheme
    
    var slides: [OnboardingItem] = [
        OnboardingItem(
            imageName: "onboarding_slide_1",
            title: "Explorez les Destinations",
            description: "Découvrez les lieux pour votre voyage dans le monde et ressentez une grande satisfaction.",
            tag: 0
        ),
        OnboardingItem(
            imageName: "onboarding_slide_2",
            title: "Choisissez une Destination",
            description: "Sélectionnez facilement un lieu pour votre voyage et connaissez le coût exact du séjour.",
            tag: 1),
        OnboardingItem(
            imageName: "onboarding_slide_3",
            title: "Envolez-vous vers la Destination",
            description: "Enfin, préparez-vous pour le voyage et partez vers votre destination de rêve.",
            tag: 2),
    ]
    
    var body: some View {
        VStack {
            ZStack {
                TabView(selection: $activeSlide) {
                    ForEach(slides, id: \.self) {item in
                        OnboardingSlide(onboardingItem: item).tag(item.tag)
                    }
                    
                }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach(slides, id: \.self) { slide in
                            RoundedRectangle(cornerRadius: 13)
                                .frame(width: slide.tag == activeSlide ? 62 : 26, height: 11)
                                .foregroundColor(slide.tag == activeSlide ? Color("green") : Color("grey"))
                                .animation(.default, value: activeSlide)
                        }
                    }
                    .padding(.bottom, 16)
                    NavigationLink(destination: HomeView()) {
                        VStack {
                            Image(systemName: "arrow.right")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(Color("green"))
                                .frame(width: 20, height: 20)
                                .bold()
                        }
                        .frame(width: 64, height: 64)
                        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground) )
                        .cornerRadius(84)
                        .shadow(color: .primary.opacity(Double(0.1)), radius: 30, x: 4, y: 16)
                        .scaleEffect(activeSlide == 2 ? 1 : 0)
                        .animation(.default, value: activeSlide)
                    }
                }
                .padding(.bottom, 74)
            }
        }.ignoresSafeArea()
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .environmentObject(AuthService())
    }
}

struct OnboardingSlide: View {
    var onboardingItem: OnboardingItem;
    
    var body: some View {
        VStack {
            Image(onboardingItem.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.width * 0.65, height: UIScreen.main.bounds.width * 0.65)
            //            .frame(width: 300, height: 300)
            Text(onboardingItem.title)
                .bold()
                .font(.title2)
                .padding(.top, 42)
            
            Text(onboardingItem.description)
                .font(.body)
                .padding(.top, 12)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 62)
                .foregroundColor(Color(.gray))
        }
        .frame(maxHeight: .infinity)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
    }
}
