import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseService: PurchaseService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        IconBadge(systemName: "lock.open", color: .green, size: 58)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Unlock Evidence Archive")
                                .font(.title3.weight(.semibold))
                            Text("Free plan includes 2 case files and 3 evidence items per case. Unlock unlimited case files and evidence items on this device.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section {
                    Button {
                        Task {
                            await purchaseService.purchaseFullAccess()
                            if purchaseService.hasFullAccess {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack {
                            Label(unlockButtonTitle, systemImage: "checkmark.seal")
                            Spacer()
                            if purchaseService.isPurchasing {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(purchaseService.isPurchasing || purchaseService.fullAccessProduct == nil)

                    Button {
                        Task {
                            await purchaseService.restorePurchases()
                            if purchaseService.hasFullAccess {
                                dismiss()
                            }
                        }
                    } label: {
                        Label("Restore Purchase", systemImage: "arrow.clockwise")
                    }
                    .disabled(purchaseService.isPurchasing)
                }

                if purchaseService.isLoadingProducts {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Loading purchase…")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .evidenceScreenBackground()
            .navigationTitle("Full Version")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .task {
                if purchaseService.fullAccessProduct == nil {
                    await purchaseService.loadProducts()
                }
            }
            .alert("Error", isPresented: Binding(
                get: { purchaseService.lastError != nil },
                set: { if !$0 { purchaseService.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {
                    purchaseService.lastError = nil
                }
            } message: {
                Text(purchaseService.lastError ?? L10n.text("Unknown error"))
            }
        }
    }

    private var unlockButtonTitle: String {
        guard let product = purchaseService.fullAccessProduct else {
            return L10n.text("Unlock Full Version")
        }

        return L10n.format("Unlock for %@", product.displayPrice)
    }
}
