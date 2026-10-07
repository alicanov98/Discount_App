//
//  CarouselView.swift
//  Discount
//
//  Created by Malik Alijanov on 06.10.26.
//

import SwiftUI


struct CarouselView<Card: Identifiable, Content: View>: View {
    let cards: [Card]
    let isHorizontalScroll: Bool
    let spacing: CGFloat
    let scalesWithPosition: Bool
    let autoPlayInterval: TimeInterval?
    @Environment(\.scenePhase) private var scenePhase
    @State private var visibleCardID: Card.ID?
    @State private var isScrolling = false
    private let content: (Card) -> Content

    init(
        cards: [Card],
        isHorizontalScroll: Bool = true,
        spacing: CGFloat = 16,
        scalesWithPosition: Bool = false,
        autoPlayInterval: TimeInterval? = nil,
        @ViewBuilder content: @escaping (Card) -> Content
    ) {
        self.cards = cards
        self.isHorizontalScroll = isHorizontalScroll
        self.spacing = spacing
        self.scalesWithPosition = scalesWithPosition
        self.autoPlayInterval = autoPlayInterval
        self.content = content
    }

    var body: some View {
        if !cards.isEmpty {
            ScrollView(isHorizontalScroll ? .horizontal : .vertical, showsIndicators: false) {
                if isHorizontalScroll {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(cards) { card in
                            content(card)
                                .containerRelativeFrame(.horizontal)
                                .modifier(CarouselPositionScale(enabled: scalesWithPosition))
                        }
                    }
                    .scrollTargetLayout()
                } else {
                    VStack(alignment: .leading, spacing: spacing) {
                        ForEach(cards) { card in
                            content(card)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .scrollTargetLayout()
                }
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $visibleCardID, anchor: .center)
            .onScrollPhaseChange { _, phase in
                isScrolling = phase != .idle
            }
            .task(id: CarouselAutoPlayKey(cardIDs: cards.map(\.id), interval: autoPlayInterval)) {
                await autoPlay()
            }
        }
    }

    private func autoPlay() async {
        guard isHorizontalScroll, cards.count > 1,
              let interval = autoPlayInterval, interval.isFinite, interval > 0 else {
            return
        }
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(interval))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            guard !isScrolling, scenePhase == .active else { continue }
            let currentIndex = cards.firstIndex { $0.id == visibleCardID } ?? 0
            let nextIndex = (currentIndex + 1) % cards.count
            withAnimation(.easeInOut(duration: 0.45)) {
                visibleCardID = cards[nextIndex].id
            }
        }
    }

}


private struct CarouselAutoPlayKey<ID: Hashable>: Equatable {
    let cardIDs: [ID]
    let interval: TimeInterval?
}

private struct CarouselPositionScale: ViewModifier {
    let enabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if enabled {
            content
                .scrollTransition(
                    .interactive(timingCurve: .linear)
                        .threshold(.centered)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8)),
                    axis: .horizontal
                ) { effect, phase in
                    effect.scaleEffect(phase.isIdentity ? 1 : 0.8)
                }
        } else {
            content
        }
    }
}
