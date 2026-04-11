import SwiftUI
import StoreKit

struct TipJarView: View {
    @ObservedObject var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    private let tipEmojis = ["☕", "🎞️", "🌟"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Support LightPad")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("LightPad is free with no ads. If it's useful for your film workflow, a tip helps keep it going.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 8)

                if store.products.isEmpty {
                    ProgressView("Loading…")
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(Array(store.products.enumerated()), id: \.element.id) { index, product in
                            tipButton(product: product, emoji: tipEmojis[safe: index] ?? "💰")
                        }
                    }
                    .padding(.horizontal)
                }

                switch store.purchaseState {
                case .purchased:
                    Label("Thank you!", systemImage: "heart.fill")
                        .font(.headline)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                case .failed(let message):
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 4)
                case .purchasing:
                    ProgressView()
                        .padding(.top, 4)
                case .idle:
                    EmptyView()
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
        .onChange(of: store.purchaseState) { state in
            if state == .purchased {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    dismiss()
                }
            }
        }
    }

    private func tipButton(product: Product, emoji: String) -> some View {
        Button {
            Task { await store.purchase(product) }
        } label: {
            HStack {
                Text(emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.headline)
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.headline)
                    .foregroundColor(.orange)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(store.purchaseState == .purchasing)
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
