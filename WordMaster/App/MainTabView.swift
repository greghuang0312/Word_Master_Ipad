import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var context: AppContext

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height

            TabView {
                NavigationStack {
                    adaptiveContainer(isLandscape: isLandscape) {
                        ReviewView(context: context)
                    }
                }
                .tabItem { Label("复习", systemImage: "book") }

                NavigationStack {
                    adaptiveContainer(isLandscape: isLandscape) {
                        AddWordView(context: context)
                    }
                }
                .tabItem { Label("添加", systemImage: "plus.circle") }

                NavigationStack {
                    adaptiveContainer(isLandscape: isLandscape) {
                        LibraryView(context: context)
                    }
                }
                .tabItem { Label("库", systemImage: "books.vertical") }

                NavigationStack {
                    adaptiveContainer(isLandscape: isLandscape) {
                        StatsView(context: context)
                    }
                }
                .tabItem { Label("统计", systemImage: "chart.bar") }

                NavigationStack {
                    adaptiveContainer(isLandscape: isLandscape) {
                        ProfileView(context: context)
                    }
                }
                .tabItem { Label("我的", systemImage: "person.crop.circle") }
            }
        }
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
