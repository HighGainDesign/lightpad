import StoreKit

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let productIDs: [String] = [
        "design.highgain.lightpad.tip.small",
        "design.highgain.lightpad.tip.medium",
        "design.highgain.lightpad.tip.large"
    ]

    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    @Published var loadError: String?

    enum PurchaseState: Equatable {
        case idle
        case purchasing
        case purchased
        case failed(String)
    }

    private init() {}

    func loadProducts() async {
        loadError = nil
        do {
            let fetched = try await Product.products(for: Self.productIDs)
            products = fetched.sorted { $0.price < $1.price }
        } catch {
            products = []
            loadError = error.localizedDescription
        }
    }

    func resetPurchaseState() {
        purchaseState = .idle
    }

    func purchase(_ product: Product) async {
        purchaseState = .purchasing
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    purchaseState = .purchased
                case .unverified:
                    purchaseState = .failed("Purchase could not be verified.")
                }
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }
}
