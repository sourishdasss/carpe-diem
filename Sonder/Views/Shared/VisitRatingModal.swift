import SwiftUI

// MARK: - Binary insertion state (one new attraction into an existing ranked list)

struct InsertionCompareState {
    let category: AttractionCategory
    let inserting: Attraction
    var sorted: [Attraction]
    var low: Int
    var high: Int

    static func begin(inserting: Attraction, into existing: [Attraction]) -> InsertionCompareState {
        InsertionCompareState(
            category: inserting.category,
            inserting: inserting,
            sorted: existing,
            low: 0,
            high: existing.count - 1
        )
    }

    var isResolved: Bool { low > high }
    var insertionIndex: Int { low }

    func midIndex() -> Int { (low + high) / 2 }
    var opponent: Attraction { sorted[midIndex()] }

    mutating func preferNew() {
        high = midIndex() - 1
    }

    mutating func preferExisting() {
        low = midIndex() + 1
    }

    var result: [Attraction] {
        var list = sorted
        list.insert(inserting, at: insertionIndex)
        return list
    }

    var totalComparisons: Int {
        guard sorted.count > 0 else { return 0 }
        return Int(ceil(log2(Double(sorted.count + 1))))
    }
}

// MARK: - Beli-style comparison modal

struct AttractionCompareModal: View {
    let newAttraction: Attraction
    let existingRanked: [Attraction]
    let cityLabel: String
    var onComplete: ([Attraction]) -> Void
    var onSkip: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var state: InsertionCompareState?
    @State private var comparisonsDone = 0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sonderBackground.ignoresSafeArea()

                if let st = state, !st.isResolved {
                    comparisonContent(state: st)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(newAttraction.category.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.sonderBackground, for: .navigationBar)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        if let skip = onSkip {
                            skip()
                        } else {
                            var list = existingRanked
                            list.append(newAttraction)
                            onComplete(list)
                        }
                        dismiss()
                    }
                    .font(.georgia(15))
                    .foregroundStyle(Color.sonderAccent)
                }
            }
        }
        .onAppear {
            state = .begin(inserting: newAttraction, into: existingRanked)
            resolveIfDone()
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Comparison UI

    private func comparisonContent(state: InsertionCompareState) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Which do you prefer?")
                    .font(.georgiaBold(24))
                    .foregroundStyle(Color.sonderTextPrimary)

                HStack(spacing: 8) {
                    Image(systemName: state.category.icon)
                        .foregroundStyle(Color.sonderSage)
                    Text(state.category.rawValue)
                        .font(.georgia(14))
                        .foregroundStyle(Color.sonderTextSecond)
                    Spacer()
                    if state.totalComparisons > 0 {
                        Text("\(comparisonsDone + 1) of ~\(state.totalComparisons)")
                            .font(.georgia(12))
                            .foregroundStyle(Color.sonderTextSecond)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Spacer()

            VStack(spacing: 16) {
                attractionCard(state.inserting, isNew: true) {
                    var next = state
                    next.preferNew()
                    comparisonsDone += 1
                    self.state = next
                    resolveIfDone()
                }

                HStack {
                    Rectangle()
                        .fill(Color.sonderDivider)
                        .frame(height: 1)
                    Text("or")
                        .font(.georgia(13))
                        .foregroundStyle(Color.sonderTextSecond)
                    Rectangle()
                        .fill(Color.sonderDivider)
                        .frame(height: 1)
                }
                .padding(.horizontal, 8)

                attractionCard(state.opponent, isNew: false) {
                    var next = state
                    next.preferExisting()
                    comparisonsDone += 1
                    self.state = next
                    resolveIfDone()
                }
            }
            .padding(.horizontal, 20)

            Spacer()
            Spacer()
        }
    }

    private func attractionCard(_ att: Attraction, isNew: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: att.category.icon)
                    .font(.title2)
                    .foregroundStyle(Color.sonderAccent)
                    .frame(width: 40, height: 40)
                    .background(Color.sonderAccent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(att.name)
                        .font(.georgiaBold(17))
                        .foregroundStyle(Color.sonderTextPrimary)
                        .multilineTextAlignment(.leading)
                    if isNew {
                        Text("New")
                            .font(.georgia(11))
                            .foregroundStyle(Color.sonderAccent)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.sonderDivider)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sonderSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.sonderAccent.opacity(isNew ? 0.4 : 0.15), lineWidth: isNew ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Resolution

    private func resolveIfDone() {
        guard let st = state, st.isResolved else { return }
        onComplete(st.result)
        dismiss()
    }
}
