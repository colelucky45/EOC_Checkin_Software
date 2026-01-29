//
//  KioskContainerView.swift
//  EMACheckIn
//
//  Created by Cole Lucky on 12/12/25.
//

import SwiftUI

struct KioskContainerView: View {

    @ObservedObject private var session: SessionManager

    @StateObject private var modeVM: KioskModeSelectorViewModel
    @StateObject private var scanVM: KioskScanViewModel

    init(session: SessionManager) {
        self.session = session

        let service = KioskService(sessionManager: session)
        _modeVM = StateObject(wrappedValue: KioskModeSelectorViewModel(kioskService: service))
        _scanVM = StateObject(wrappedValue: KioskScanViewModel(kioskService: service))
    }

    var body: some View {
        Group {
            if modeVM.kioskContext != nil {
                KioskScanView(viewModel: scanVM)
            } else {
                KioskModeSelectorView(viewModel: modeVM)
            }
        }
        .ignoresSafeArea()
        .brandedBackground()
        .task {
            await modeVM.load()
        }
    }
}
