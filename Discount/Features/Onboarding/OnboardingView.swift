//
//  OnboardingView.swift
//  Discount
//
//  Created by Malik Alijanov on 17.09.26.
//

import SwiftUI

struct OnboardingView: View {
    let onCompleted: () -> Void

    @State private var selectedPage = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let pages = OnboardingPage.allCases

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("discount.", systemImage: "tag.fill")
                    .font(AppTypography.sectionTitle)
                    .foregroundStyle(Color.appPrimary)

                Spacer()

                Button("Keç", action: onCompleted)
                    .font(AppTypography.button)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Tanıtımı keç")
            }
            .padding(.horizontal, 24)

            TabView(selection: $selectedPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    ScrollView {
                        VStack(spacing: 28) {
                            OnboardingArtwork(page: page)
                                .frame(height: 310)
                                .accessibilityHidden(true)

                            VStack(spacing: 16) {
                                Text(page.eyebrow)
                                    .font(AppTypography.caption)
                                    .tracking(2)
                                    .foregroundStyle(Color.appPrimary)

                                Text(page.title)
                                    .font(AppTypography.largeTitle)
                                    .foregroundStyle(Color.appTextPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(page.subtitle)
                                    .font(AppTypography.body)
                                    .foregroundStyle(Color.appTextSecondary)
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        }
                        .frame(maxWidth: 500)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 22) {
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Capsule()
                            .fill(
                                index == selectedPage
                                    ? Color.appPrimary
                                    : Color.appBorder
                            )
                            .frame(
                                width: index == selectedPage ? 28 : 8,
                                height: 8
                            )
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Səhifə \(selectedPage + 1), cəmi \(pages.count)"
                )

                Button(action: advance) {
                    HStack(spacing: 10) {
                        Text(
                            selectedPage == pages.count - 1
                                ? "Başlayaq"
                                : "Davam et"
                        )

                        Image(systemName: "arrow.right")
                    }
                    .font(AppTypography.button)
                    .foregroundStyle(Color.appOnPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        Color.appPrimary,
                        in: RoundedRectangle(cornerRadius: 18)
                    )
                }
                .buttonStyle(.plain)

                Button("Artıq hesabım var", action: onCompleted)
                    .font(AppTypography.button)
                    .foregroundStyle(Color.appPrimary)
                    .frame(minHeight: 44)
            }
            .frame(maxWidth: 450)
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(Color.appBackground.ignoresSafeArea())
    }

    private func advance() {
        guard selectedPage < pages.count - 1 else {
            onCompleted()
            return
        }

        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
            selectedPage += 1
        }
    }
}

private enum OnboardingPage: Int, CaseIterable {
    case discover
    case nearby
    case favorites

    var eyebrow: String {
        switch self {
        case .discover:
            "KƏŞF ET"
        case .nearby:
            "YAXINLIĞINDA"
        case .favorites:
            "SƏNİN ÜÇÜN"
        }
    }

    var title: String {
        switch self {
        case .discover:
            "Sevdiyin yerlər.\nDaha sərfəli təkliflər."
        case .nearby:
            "Yaxındakı fürsətləri\nqaçırma."
        case .favorites:
            "Bəyəndiklərini saxla.\nSonra rahat tap."
        }
    }

    var subtitle: String {
        switch self {
        case .discover:
            "Moda, gözəllik, yemək və daha çoxu. Müxtəlif məkanların endirimlərini bir yerdə kəşf et."
        case .nearby:
            "Məkanını seç, ətrafındakı kampaniyalara bax və bəyəndiyin yerə yolunu tap."
        case .favorites:
            "Təklifləri seçilmişlərinə əlavə et. Maraqlarını seçərək sənə uyğun kampaniyaları kəşf et."
        }
    }
}


private struct OnboardingArtwork: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.appPrimarySoft)
                .frame(width: 270, height: 270)

            Circle()
                .stroke(
                    Color.appPrimary.opacity(0.12),
                    style: StrokeStyle(lineWidth: 1, dash: [5, 7])
                )
                .frame(width: 300, height: 300)

            switch page {
            case .discover:
                offerCard(
                    symbol: "bag.fill",
                    title: "Moda",
                    detail: "Yeni sevimlilərini kəşf et",
                    badge: "−30%"
                )
                .rotationEffect(.degrees(-7))
                .offset(y: -15)

                floatingIcon("sparkles", color: Color.appPrimary)
                    .offset(x: 112, y: -105)

                pill("Hər gün yeni fürsətlər", symbol: "tag.fill")
                    .rotationEffect(.degrees(4))
                    .offset(y: 132)

            case .nearby:
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.appCardBackground)
                    .frame(width: 235, height: 225)
                    .rotationEffect(.degrees(6))
                    .shadow(
                        color: Color.appShadow.opacity(0.1),
                        radius: 20,
                        y: 10
                    )

                mapRoads
                    .frame(width: 215, height: 195)
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 76))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.appOnPrimary, Color.appPrimary)
                    .offset(y: -24)

                floatingIcon("cup.and.saucer.fill", color: Color.appPrimary)
                    .offset(x: -103, y: -75)

                floatingIcon("fork.knife", color: Color.appViolet)
                    .offset(x: 102, y: 45)

                pill("Yaxınlıqdakı təkliflər", symbol: "location.fill")
                    .offset(y: 132)

            case .favorites:
                offerCard(
                    symbol: "cup.and.saucer.fill",
                    title: "Seçilmiş təklif",
                    detail: "Bir toxunuşla yadda saxla",
                    badge: "−20%"
                )
                .rotationEffect(.degrees(5))
                .offset(y: -15)

                floatingIcon("heart.fill", color: Color.appPink)
                    .offset(x: 104, y: -99)

                pill(
                    "Sevdiklərin bir yerdə",
                    symbol: "checkmark.circle.fill"
                )
                .rotationEffect(.degrees(-4))
                .offset(y: 132)
            }
        }
        .frame(maxWidth: .infinity)
        .allowsHitTesting(false)
    }

    private func offerCard(
        symbol: String,
        title: String,
        detail: String,
        badge: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 42, weight: .medium))
                    .foregroundStyle(Color.appPrimary)

                Spacer()

                Text(badge)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appOnPrimary)
                    .padding(12)
                    .background(
                        Color.appPrimary,
                        in: RoundedRectangle(cornerRadius: 16)
                    )
            }
            .frame(height: 88)

            Rectangle()
                .fill(Color.appBorder)
                .frame(height: 1)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(Color.appTextPrimary)

                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
        .padding(22)
        .frame(width: 244)
        .background(
            Color.appCardBackground,
            in: RoundedRectangle(cornerRadius: 26)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .shadow(
            color: Color.appShadow.opacity(0.12),
            radius: 20,
            y: 12
        )
    }

    private func floatingIcon(
        _ symbol: String,
        color: Color
    ) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 25, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 58, height: 58)
            .background(
                Color.appCardBackground,
                in: RoundedRectangle(cornerRadius: 18)
            )
            .shadow(
                color: Color.appShadow.opacity(0.1),
                radius: 12,
                y: 6
            )
    }

    private func pill(
        _ title: String,
        symbol: String
    ) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.appPrimary)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(Color.appCardBackground, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.appBorder, lineWidth: 1)
            )
            .shadow(
                color: Color.appShadow.opacity(0.08),
                radius: 10,
                y: 5
            )
    }

    private var mapRoads: some View {
        ZStack {
            Color.appPrimarySoft

            ForEach(-1...1, id: \.self) { index in
                Rectangle()
                    .fill(Color.appCardBackground)
                    .frame(width: 14, height: 300)
                    .rotationEffect(.degrees(30))
                    .offset(x: CGFloat(index) * 85)

                Rectangle()
                    .fill(Color.appCardBackground)
                    .frame(width: 300, height: 12)
                    .rotationEffect(.degrees(-20))
                    .offset(y: CGFloat(index) * 75)
            }
        }
    }
}

#Preview {
    OnboardingView(onCompleted: {})
}
