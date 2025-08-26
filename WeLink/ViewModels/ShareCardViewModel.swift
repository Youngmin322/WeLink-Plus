//
//  ShareCardViewModel.swift
//  WeLink
//
//  Created by Youngmin Cho on 8/26/25.
//

import Foundation
import MultipeerConnectivity
import SwiftData

@MainActor
class ShareCardViewModel: ObservableObject {
    @Published var dotCount: Int = 0
    @Published var pendingCardSends: Set<String> = []
    @Published var rejectedPeers: Set<String> = []
    @Published var showSuccessMessage = false
    @Published var currentScreenState: ScreenState = .searching
    
    private let multipeerService: MultipeerService
    private let cardViewModel: CardViewModel
    
    enum ScreenState {
        case searching
        case peerList
        case waitingForResponse
        case incomingInvitation
        case exchangeSuccess
    }
    
    init(multipeerService: MultipeerService, cardViewModel: CardViewModel) {
        self.multipeerService = multipeerService
        self.cardViewModel = cardViewModel
    }
    
    // MARK: - Computed Properties
    var discoveredPeers: [MCPeerID] {
        multipeerService.discoveredPeers
    }
    
    var connectedPeers: [MCPeerID] {
        multipeerService.connectedPeers
    }
    
    var waitingForResponse: MCPeerID? {
        multipeerService.waitingForResponse
    }
    
    var incomingInvitation: (peer: MCPeerID, handler: (Bool) -> Void)? {
        multipeerService.incomingInvitation
    }
    
    var receivedCard: CardModel? {
        multipeerService.receivedCard
    }
    
    var cardExchangeCompleted: Bool {
        multipeerService.cardExchangeCompleted
    }
    
    // MARK: - Screen State Management
    func updateScreenState() {
        if showSuccessMessage {
            currentScreenState = .exchangeSuccess
        } else if incomingInvitation != nil {
            currentScreenState = .incomingInvitation
        } else if waitingForResponse != nil {
            currentScreenState = .waitingForResponse
        } else if discoveredPeers.isEmpty {
            currentScreenState = .searching
        } else {
            currentScreenState = .peerList
        }
    }
    
    // MARK: - Setup and Connection
    func setupMultipeerManager(with card: CardModel, context: ModelContext) {
        multipeerService.setModelContext(context)
        multipeerService.setupPeerWithUserName(card.name)
        multipeerService.startHosting()
        multipeerService.startBrowsing()
    }
    
    func restartSearch() {
        print("수동으로 검색 재시작")
        multipeerService.stopBrowsing()
        multipeerService.stopHosting()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.multipeerService.startHosting()
            self.multipeerService.startBrowsing()
        }
    }
    
    func disconnect() {
        multipeerService.disconnect()
    }
    
    // MARK: - Peer Interaction
    func invitePeerAndSendCard(_ peer: MCPeerID, card: CardModel) {
        print("연결 시도: \(peer.displayName)")
        pendingCardSends.insert(peer.displayName)
        multipeerService.invitePeer(peer)
        
        // Store card for sending after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.connectedPeers.contains(peer) {
                self.multipeerService.sendCard(card, to: peer)
            }
        }
    }
    
    func cancelInvitation() {
        multipeerService.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.multipeerService.startHosting()
            self.multipeerService.startBrowsing()
        }
    }
    
    func respondToInvitation(accept: Bool, myCard: CardModel?) {
        guard let invitation = incomingInvitation else { return }
        
        invitation.handler(accept)
        
        if accept, let card = myCard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.multipeerService.sendCard(card, to: invitation.peer)
            }
        }
    }
    
    // MARK: - UI State Management
    func updateDotCount() {
        dotCount = (dotCount + 1) % 4
    }
    
    func handleConnectedPeersChange(oldValue: [MCPeerID], newValue: [MCPeerID]) {
        for peer in newValue {
            pendingCardSends.remove(peer.displayName)
        }
        updateScreenState()
    }
    
    func handleConnectionRejected(rejectedPeerName: String?) {
        guard let rejectedPeerName = rejectedPeerName else { return }
        
        rejectedPeers.insert(rejectedPeerName)
        pendingCardSends.remove(rejectedPeerName)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.rejectedPeers.remove(rejectedPeerName)
        }
    }
    
    func handleCardExchangeCompleted(completed: Bool) {
        if completed {
            showSuccessMessage = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.showSuccessMessage = false
            }
        }
        updateScreenState()
    }
    
    func handleNewExchange() {
        showSuccessMessage = false
        multipeerService.disconnect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.multipeerService.startHosting()
            self.multipeerService.startBrowsing()
        }
    }
    
    // MARK: - Peer Status
    func isPeerConnected(_ peer: MCPeerID) -> Bool {
        connectedPeers.contains { $0.displayName == peer.displayName }
    }
    
    func isPeerConnecting(_ peer: MCPeerID) -> Bool {
        pendingCardSends.contains(peer.displayName) || waitingForResponse?.displayName == peer.displayName
    }
    
    func isPeerRejected(_ peer: MCPeerID) -> Bool {
        rejectedPeers.contains(peer.displayName)
    }
    
    // MARK: - Card Creation
    func createDefaultCard() -> CardModel {
        return CardModel(
            id: UUID(),
            name: "홍길동",
            age: 30,
            description: "반갑습니다!",
            birthDate: "1994-01-01",
            mbti: "ISFJ",
            tag: "일반",
            dDay: 365,
            imageData: Data()
        )
    }
    
    func getActualMyCard(from allCards: [CardModel], myIDs: [MyUUID]) -> CardModel? {
        return cardViewModel.findMyCard(from: allCards, myIDs: myIDs)
    }
}
