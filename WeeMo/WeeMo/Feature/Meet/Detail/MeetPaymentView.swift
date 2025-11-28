//
//  MeetPaymentView.swift
//  WeeMo
//
//  Created by Watson22_YJ on 11/26/25.
//

import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios

// MARK: - Payment Info

struct PaymentInfo {
    let postId: String
    let title: String
    let price: Int
}

// MARK: - Meet Payment View

struct MeetPaymentView: UIViewControllerRepresentable {
    let paymentInfo: PaymentInfo
    let onValidatePayment: (String, String) -> Void  // (impUid, postId) -> Void
    @Environment(\.dismiss) private var dismiss

    /// MeetDetailView에서 사용하는 초기화 (Store 사용)
    init(meet: Meet, store: MeetDetailStore) {
        self.paymentInfo = PaymentInfo(
            postId: meet.id,
            title: meet.title,
            price: meet.pricePerPerson
        )
        self.onValidatePayment = { impUid, postId in
            store.send(.validatePayment(impUid: impUid, postId: postId))
        }
    }

    /// MeetEditView에서 사용하는 초기화 (Store 사용)
    init(postId: String, title: String, price: Int, store: MeetEditStore) {
        self.paymentInfo = PaymentInfo(
            postId: postId,
            title: title,
            price: price
        )
        self.onValidatePayment = { impUid, postId in
            store.send(.validatePayment(impUid: impUid, postId: postId))
        }
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = MeetPaymentViewController()
        viewController.paymentInfo = paymentInfo
        viewController.onValidatePayment = onValidatePayment
        viewController.onDismiss = { [dismiss] in
            dismiss()
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }
}

// MARK: - Meet Payment View Controller

class MeetPaymentViewController: UIViewController, WKNavigationDelegate {
    var paymentInfo: PaymentInfo?
    var onValidatePayment: ((String, String) -> Void)?
    var onDismiss: (() -> Void)?
    private var hasRequestedPayment = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 결제 요청을 한 번만 실행
        if !hasRequestedPayment {
            hasRequestedPayment = true
            requestPayment()
        }
    }

    // MARK: - Payment Request

    /// 아임포트 SDK 결제 요청
    func requestPayment() {
        guard let paymentInfo, let userCode = Bundle.main.object(forInfoDictionaryKey: "IAMPORT_USER_CODE") as? String else { return }

        // 결제 데이터 생성
        let payment = createPaymentData(paymentInfo: paymentInfo)

        // WebViewController 용 닫기버튼 생성
        Iamport.shared.useNavigationButton(enable: true)

        // 결제 요청
        Iamport.shared.payment(
            viewController: self,
            userCode: userCode,
            payment: payment
        ) { [weak self] response in
            self?.handlePaymentResponse(response)
        }
    }

    /// 결제 데이터 생성
    private func createPaymentData(paymentInfo: PaymentInfo) -> IamportPayment {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // 밀리초 단위
        let payment = IamportPayment(
            pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
            merchant_uid: "weemo_\(timestamp)",
            amount: "\(paymentInfo.price)"
        )
        payment.pay_method = PayMethod.card.rawValue
        payment.name = paymentInfo.title
        payment.buyer_name = "나영진"
        payment.app_scheme = "weemo"

        return payment
    }

    /// 결제 응답 처리
    private func handlePaymentResponse(_ response: IamportResponse?) {

        guard let response = response else {
            Task { @MainActor in
                onDismiss?()
            }
            return
        }

        // 결제 성공 여부 확인
        if response.success == true,
           let impUid = response.imp_uid,
           !impUid.isEmpty,
           let paymentInfo = paymentInfo {
            
            // Store를 통해 영수증 검증 요청
            Task { @MainActor in
                onValidatePayment?(impUid, paymentInfo.postId)
                onDismiss?()
            }
        } else {
            // 결제 실패
            Task { @MainActor in
                onDismiss?()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MeetDetailView(postId: "sample-post-id")
    }
}
