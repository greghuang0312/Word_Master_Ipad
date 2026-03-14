import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var context: AppContext
    @State private var selectedTab: MainTab = .review

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            ZStack {
                ForEach(MainTab.allCases) { tab in
                    NavigationStack {
                        adaptiveContainer(isLandscape: isLandscape) {
                            tabContent(for: tab)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(selectedTab == tab ? 1 : 0)
                    .allowsHitTesting(selectedTab == tab)
                    .accessibilityHidden(selectedTab != tab)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                bottomBar(isLandscape: isLandscape)
            }
            .animation(.easeInOut(duration: 0.18), value: selectedTab)
        }
    }

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .review:
            ReviewView(context: context, isActive: selectedTab == .review)
        case .add:
            AddWordView(context: context)
        case .library:
            LibraryView(context: context, isActive: selectedTab == .library)
        case .stats:
            StatsView(context: context, isActive: selectedTab == .stats)
        case .profile:
            ProfileView(context: context)
        }
    }

    private func bottomBar(isLandscape: Bool) -> some View {
        HStack(spacing: 8) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 17, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? .white : .secondary)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(
                        selectedTab == tab
                            ? AnyShapeStyle(Color.blue)
                            : AnyShapeStyle(Color.clear),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        .padding(.horizontal, isLandscape ? 120 : 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private func adaptiveContainer<Content: View>(isLandscape: Bool, @ViewBuilder content: () -> Content) -> some View {
        if isLandscape {
            HStack(spacing: 0) {
                Spacer(minLength: 24)
                content()
                    .frame(maxWidth: 900)
                Spacer(minLength: 24)
            }
        } else {
            content()
        }
    }
}
