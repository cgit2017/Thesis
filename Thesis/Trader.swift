//
//  trader.swift
//  Thesis
//
//  Created by Charlie on 1/8/19.
//  Copyright © 2019 Charlie. All rights reserved.
//

import Foundation


class Trader {
    var quoteCollector: [Order]
    let traderID: Int
    var orderID: Int
    
    init(trader: Int) {
        self.traderID = trader
        self.quoteCollector = []
        self.orderID = 0
    }
    
    func makeAddOrder(time: Int, side: Int, price: Int, quantity: Int) -> Order {
        orderID += 1
        let addOrder = Order(orderID: orderID, ID: 0, traderID: traderID, timeStamp: time, type: 1, quantity: quantity, side: side, price: price)
        return addOrder
    }
}

class MarketMaker {
    let traderID: Int
    let cancelProb: Float
    var localBook: [Int:Order]
    var cancelCollector: [Order]
    var numQuotes: Int
    var quoteRange: Int
    var position: Int
    var cashFlow: Int
    var cashFlowTimeStamps: [Int]
    var cashFlows: [Int]
    var positions: [Int]
    var quoteCollector: [Order]
    var orderID: Int
    var maxQuantity: Int
    
    init(trader: Int, numQuotes: Int, quoteRange: Int, cancelProb: Float) {
        self.traderID = trader
        self.localBook = [:]
        self.cancelCollector = []
        self.numQuotes = numQuotes
        self.quoteRange = quoteRange
        self.position = 0
        self.cashFlow = 0
        self.cashFlowTimeStamps = []
        self.cashFlows = []
        self.positions = []
        self.quoteCollector = []
        self.orderID = 0
        self.cancelProb = cancelProb
        self.maxQuantity = 50
    }
    
    func makeAddOrder(time: Int, side: Int, price: Int, quantity: Int) -> Order {
        orderID += 1
        let addOrder = Order(orderID: orderID, ID: 0, traderID: traderID, timeStamp: time, type: 1, quantity: quantity, side: side, price: price)
        return addOrder
    }
    
    func makeCancelOrder(existingOrder: Order, time: Int) -> Order {
        let cancelOrder = Order(orderID: existingOrder.orderID, ID: existingOrder.ID, traderID: traderID, timeStamp: time, type: 2, quantity: existingOrder.quantity, side: existingOrder.side, price: existingOrder.price)
        return cancelOrder
    }
    
    func cumulateCashFlow(timeStamp: Int) {
        cashFlowTimeStamps.append(timeStamp)
        cashFlows.append(cashFlow)
        positions.append(position)
    }
    
    func confirmTradeLocal(confirmOrder: Order) {
        // Update cashflow and position
        if confirmOrder.side == 1 {
            cashFlow -= confirmOrder.price * confirmOrder.quantity
            position += confirmOrder.quantity
        }
        else {
            cashFlow += confirmOrder.price * confirmOrder.quantity
            position -= confirmOrder.quantity
        }
        // Modify/remove order from local book
        let localOrder = localBook[confirmOrder.orderID]
        if confirmOrder.quantity == localOrder!.quantity {
            localBook.removeValue(forKey: localOrder!.orderID)
        }
        else {
            localBook[localOrder!.orderID]!.quantity -= confirmOrder.quantity
        }
        cumulateCashFlow(timeStamp: confirmOrder.timeStamp)
    }
    
    func bulkCancel(timeStamp: Int) {
        cancelCollector.removeAll()
        for x in localBook.keys {
            if Float.random(in: 0..<1) < cancelProb {
                cancelCollector.append(makeCancelOrder(existingOrder: localBook[x]!, time: timeStamp))
            }
        }
        for c in cancelCollector {
            localBook.removeValue(forKey: c.orderID)
        }
    }
    
    func processSignal(timeStamp: Int, topOfBook: [String:Int], buySellProb:Float) {
        quoteCollector.removeAll()
        var prices = Array<Int>()
        var side: Int
        // This creates a buy order (buySellProb = .5 is equal probability of buy or sell)
        if Float.random(in: 0..<1) < buySellProb {
            let maxBidPrice = topOfBook["bestBid"]
            let minBidPrice = maxBidPrice! - quoteRange
            for _ in 1 ... numQuotes {
                prices.append(Int.random(in: minBidPrice...maxBidPrice!))
            }
            side = 1
        }
        // This creates a sell order
        else {
            let minAskPrice = topOfBook["bestAsk"]
            let maxAskPrice = minAskPrice! + quoteRange
            for _ in 1 ... numQuotes {
                prices.append(Int.random(in: minAskPrice!...maxAskPrice))
            }
            side = 2
        }
        for price in prices {
            let order = makeAddOrder(time: timeStamp, side: side, price: price, quantity: Int.random(in: 1...maxQuantity))
            localBook[order.orderID] = order
            quoteCollector.append(order)
        }
    }
}

class Taker {
    let traderID: Int
    let maxQuantity: Int
    let buySellProb: Float
    var orderID: Int
    
    init(traderID: Int, maxQuantity: Int, buySellProb: Float) {
        self.traderID = traderID
        self.maxQuantity = maxQuantity
        self.buySellProb = buySellProb
        self.orderID = 0
    }
    
    func makeAddOrder(time: Int, side: Int, price: Int, quantity: Int) -> Order {
        orderID += 1
        let addOrder = Order(orderID: orderID, ID: 0, traderID: traderID, timeStamp: time, type: 1, quantity: quantity, side: side, price: price)
        return addOrder
    }
    
    func processSignal(timeStamp: Int) -> Order {
        if Float.random(in: 0..<1) < buySellProb {
            let order = makeAddOrder(time: timeStamp, side: 1, price: 200000, quantity: Int.random(in: 1...maxQuantity))
            return order
        }
        else {
            let order = makeAddOrder(time: timeStamp, side: 2, price: 0, quantity: Int.random(in: 1...maxQuantity))
            return order
        }
    }
}