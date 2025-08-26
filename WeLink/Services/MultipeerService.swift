//
//  MultipeerService.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import MultipeerConnectivity
import SwiftData

class MultipeerService: NSObject, ObservableObject {
    private let serviceType = "welink-share"
    private var myPeerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    
    private var currentInvitationHandler: ((Bool, MCSession?) -> Void)?
    private var currentInvitationPeer: MCPeerID?
    private var invitationTimeoutTimer: Timer?
    
    private var cardsSentTo: Set<String> = []
    private var cardsReceivedFrom: Set<String> = []
    private var modelContext: ModelContext?
    
    // MARK: - Public Properties
    @Published var receivedCard: CardModel?
    @Published var isConnected: Bool = false
    @Published var discoveredPeers: [MCPeerID] = []
    @Published var connectedPeers: [MCPeerID] = []
    @Published var cardSentSuccessfully: Bool = false
    @Published var waitingForResponse: MCPeerID?
    @Published var incomingInvitation: (peer: MCPeerID, handler: (Bool) -> Void)?
    @Published var connectionRejected: String?
    @Published var cardExchangeCompleted: Bool = false
    
    // MARK: - Initialization
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func setupPeerWithUserName(_ userName: String) {
        let displayName = userName.isEmpty ? UIDevice.current.name : userName
        myPeerID = MCPeerID(displayName: displayName)
        setupSession()
        setupAdvertiser()
        setupBrowser()
        print("피어 ID 설정 완료: \(displayName)")
    }
    
    override init() {
        super.init()
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
        setupSession()
        setupAdvertiser()
        setupBrowser()
    }
    
    // MARK: - Private Setup Methods
    private func setupSession() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        print("Session 설정 완료: \(myPeerID.displayName)")
    }
    
    private func setupAdvertiser() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        print("Advertiser 설정 완료")
    }
    
    private func setupBrowser() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser.delegate = self
        print("Browser 설정 완료")
    }
    
    // MARK: - Public Methods
    func startHosting() {
        print("광고 시작: \(myPeerID.displayName)")
        advertiser.startAdvertisingPeer()
    }
    
    func startBrowsing() {
        print("검색 시작")
        browser.startBrowsingForPeers()
    }
    
    func stopHosting() {
        print("광고 중지")
        advertiser.stopAdvertisingPeer()
    }
    
    func stopBrowsing() {
        print("검색 중지")
        browser.stopBrowsingForPeers()
    }
    
    func disconnect() {
        session.disconnect()
        stopHosting()
        stopBrowsing()
        
        cardsSentTo.removeAll()
        cardsReceivedFrom.removeAll()
        
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll()
            self.connectedPeers.removeAll()
            self.isConnected = false
        }
    }
    
    func invitePeer(_ peerID: MCPeerID) {
        print("초대 전송: \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
    }
    
    func sendCard(_ card: CardModel, to peer: MCPeerID) {
        guard session.connectedPeers.contains(peer) else {
            print("피어가 연결되지 않음: \(peer.displayName)")
            return
        }
        
        do {
            let cardData = CardTransferData(card: card, senderID: myPeerID.displayName)
            let data = try JSONEncoder().encode(cardData)
            try session.send(data, toPeers: [peer], with: .reliable)
            print("카드 전송 성공 to \(peer.displayName)")
            
            cardsSentTo.insert(peer.displayName)
            
            DispatchQueue.main.async {
                self.cardSentSuccessfully = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.cardSentSuccessfully = false
                }
            }
        } catch {
            print("카드 전송 실패 \(peer.displayName): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Methods
    private func saveReceivedCard(_ card: CardModel, from senderID: String) {
        guard let context = modelContext else {
            print("ModelContext가 설정되지 않음")
            return
        }
        
        let newCard = CardModel(
            id: UUID(),
            name: card.name,
            age: card.age,
            description: card.cardDescription,
            birthDate: card.birthDate,
            mbti: card.mbti,
            tag: card.tag,
            dDay: card.dDay,
            imageData: card.imageData
        )
        
        context.insert(newCard)
        
        do {
            try context.save()
            print("카드 저장 완료: \(card.name)")
            
            cardsReceivedFrom.insert(senderID)
            checkExchangeCompletion(with: senderID)
            
        } catch {
            print("카드 저장 실패: \(error)")
        }
    }
    
    private func checkExchangeCompletion(with peerID: String) {
        if cardsSentTo.contains(peerID) && cardsReceivedFrom.contains(peerID) {
            print("양방향 카드 교환 완료: \(peerID)")
            
            DispatchQueue.main.async {
                self.cardExchangeCompleted = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.cardExchangeCompleted = false
                }
            }
        }
    }
}

// MARK: - MCSessionDelegate
extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("세션 상태 변경 \(peerID.displayName): \(state.description)")
        
        DispatchQueue.main.async {
            self.isConnected = !session.connectedPeers.isEmpty
            self.connectedPeers = session.connectedPeers
            
            switch state {
            case .connected:
                print("연결됨: \(peerID.displayName)")
                
                if self.waitingForResponse == peerID {
                    self.waitingForResponse = nil
                }
                
            case .connecting:
                print("연결 중: \(peerID.displayName)")
                
            case .notConnected:
                print("연결 해제됨: \(peerID.displayName)")
                
                self.cardsSentTo.remove(peerID.displayName)
                self.cardsReceivedFrom.remove(peerID.displayName)
                
                if let waitingPeer = self.waitingForResponse,
                   waitingPeer.displayName == peerID.displayName {
                    self.connectionRejected = peerID.displayName
                    print("연결 거절됨: \(peerID.displayName)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.connectionRejected = nil
                    }
                    
                    self.waitingForResponse = nil
                }
                
            @unknown default:
                print("알 수 없는 상태: \(peerID.displayName)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("데이터 수신: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            do {
                let cardData = try JSONDecoder().decode(CardTransferData.self, from: data)
                self.receivedCard = cardData.card
                print("카드 디코딩 성공: \(cardData.card.name) from \(cardData.senderID)")
                
                self.saveReceivedCard(cardData.card, from: cardData.senderID)
                
            } catch {
                print("카드 디코딩 실패: \(error)")
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("초대 수신: \(peerID.displayName)")
        
        invitationTimeoutTimer?.invalidate()
        
        currentInvitationHandler = invitationHandler
        currentInvitationPeer = peerID
        
        invitationTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            print("초대 타임아웃: \(peerID.displayName)")
            self?.forceCloseInvitation()
        }
        
        DispatchQueue.main.async {
            self.incomingInvitation = (peer: peerID, handler: { accept in
                print("초대에 응답: \(accept ? "수락" : "거절")")
                
                self.invitationTimeoutTimer?.invalidate()
                self.invitationTimeoutTimer = nil
                
                invitationHandler(accept, accept ? self.session : nil)
                
                self.currentInvitationHandler = nil
                self.currentInvitationPeer = nil
            })
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("광고 시작 실패: \(error.localizedDescription)")
    }
    
    private func forceCloseInvitation() {
        print("강제로 초대 화면 닫기")
        
        invitationTimeoutTimer?.invalidate()
        invitationTimeoutTimer = nil
        
        DispatchQueue.main.async {
            self.incomingInvitation = nil
        }
        
        if let handler = currentInvitationHandler {
            print("초대 핸들러에 거절 응답 전송")
            handler(false, nil)
        }
        
        currentInvitationHandler = nil
        currentInvitationPeer = nil
    }
}

// MARK: - MCNearbyServiceBrowserDelegate
extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("피어 발견: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(where: { $0.displayName == peerID.displayName }) {
                self.discoveredPeers.append(peerID)
                print("피어 목록에 추가: \(peerID.displayName)")
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("피어 손실: \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0.displayName == peerID.displayName }
            
            self.cardsSentTo.remove(peerID.displayName)
            self.cardsReceivedFrom.remove(peerID.displayName)
            
            if let currentPeer = self.currentInvitationPeer,
               currentPeer.displayName == peerID.displayName,
               self.incomingInvitation != nil {
                print("피어 손실로 인한 초대 화면 닫기: \(peerID.displayName)")
                self.forceCloseInvitation()
            }
            
            if self.waitingForResponse?.displayName == peerID.displayName {
                print("피어 손실로 인한 대기 상태 취소: \(peerID.displayName)")
                self.waitingForResponse = nil
            }
            
            print("피어 목록에서 제거: \(peerID.displayName)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("검색 시작 실패: \(error.localizedDescription)")
        
        if error.localizedDescription.contains("denied") || error.localizedDescription.contains("permission") {
            print("네트워크 권한 거부됨")
        }
    }
}

// MARK: - Supporting Types
struct CardTransferData: Codable {
    let card: CardModel
    let senderID: String
    
    init(card: CardModel, senderID: String) {
        self.card = card
        self.senderID = senderID
    }
}

extension MCSessionState {
    var description: String {
        switch self {
        case .notConnected: return "notConnected"
        case .connecting: return "connecting"
        case .connected: return "connected"
        @unknown default: return "unknown"
        }
    }
}
