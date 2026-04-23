//
//  DocereeAdView+Loading.swift
//  DocereeAdsSdk
//
//  Created by Muqeem Ahmad on 18/06/25.
//

import Foundation
import UIKit

extension DocereeAdView {

    func fetchAd(_ size: String, _ uId: String) {
        adFetchTask?.cancel()
        adFetchTask = Task { [weak self] in
            guard let self else { return }
            do {
                guard let request = self.docereeAdRequest else {
                    await MainActor.run { [weak self] in
                        guard let self, self.window != nil else { return }
                        self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: .invalidRequest)
                    }
                    return
                }

                let (results, isRichMediaAd) = try await request.requestAd(userId: uId, adUnitId: self.docereeAdUnitId, size: size)
                guard let data = results.data else {
                    await MainActor.run { [weak self] in
                        guard let self, self.window != nil else { return }
                        self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: .invalidResponse)
                        self.removeAllViews()
                        self.startTimer(adFound: false)
                    }
                    return
                }

                let rs = try JSONDecoder().decode(AdResponseMain.self, from: data)
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    self.isRichMediaAd = isRichMediaAd
                    self.adResponseData = rs.response.first

                    if self.adResponseData?.status == -1 {
                        guard self.window != nil else { return }
                        self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: .adNotFound)
                        self.removeAllViews()
                    } else {
                        self.createAdUI()
                    }

                    self.startTimer(adFound: true)
                }
            } catch is CancellationError {
                DocereeLog.debug("Ad fetch cancelled")
            } catch {
                DocereeLog.debug("Ad fetch failed: \(error.localizedDescription)")
                await MainActor.run { [weak self] in
                    guard let self, self.window != nil else { return }
                    self.delegate?.docereeAdView(self, didFailToReceiveAdWithError: error as? DocereeAdRequestError ?? .failedToCreateRequest)
                    self.removeAllViews()
                    self.startTimer(adFound: false)
                }
            }
        }
    }

    func createAdUI() {
        if let tag = adResponseData?.passbackTag, !tag.isEmpty {
            createPassbackAd(tag: tag)
            return
        }

        self.cbId = adResponseData?.CBID?.split(separator: "_").first.map(String.init)
        self.docereeAdUnitId = adResponseData?.adUnit ?? ""
        self.ctaLink = adResponseData?.clickURL?.replacingOccurrences(of: "DOCEREE_CLICK_URL_UNESC", with: "")
        if var adRenderURL = adResponseData?.adRenderURL, !adRenderURL.isEmpty {
            adRenderURL = adRenderURL.replacingOccurrences(of: "{{EVENT_CLIENT_TIME}}", with: Date.currentTimeMillis())
            self.docereeAdRequest?.sendImpression(to: adRenderURL)
        }

        if !isRichMediaAd {
            createSimpleAd(imagePath: adResponseData?.imagePath)
        } else {
            if var script = adResponseData?.script {
                script = script.replacingOccurrences(of: "[timestamp]", with: Date.currentTimeMillis())
                script = script.replacingOccurrences(of: "[TIMESTAMP]", with: Date.currentTimeMillis())
                script = script.replacingOccurrences(of: "[CACHE_BUSTER]", with: Date.currentTimeMillis())
                script = script.replacingOccurrences(of: "[cache_buster]", with: Date.currentTimeMillis())
                createRichMediaAd(script: script)
            }
        }
    }

}
