Stacks Prediction Market Smart Contract
A decentralized prediction market implementation built on the Stacks blockchain using Clarity smart contracts.

Overview
This smart contract enables users to create and participate in binary (yes/no) prediction markets using STX tokens. Users can place bets on outcomes, and winners receive proportional payouts minus platform fees.

Features
Create binary prediction events
Place bets using STX tokens
Oracle-based event resolution
Proportional payout system
Platform fee collection (5%)
Admin controls for market management
Contract Functions
Admin Functions
User Functions
Error Codes
Code	Description
ERR-NOT-ADMIN (u100)	Operation restricted to admin
ERR-EVENT-EXISTS (u101)	Event ID already exists
ERR-EVENT-NOT-FOUND (u110)	Event not found
ERR-ALREADY-RESOLVED (u111)	Event already resolved
ERR-NO-BALANCE (u112)	Insufficient balance
ERR-UNRESOLVED (u131)	Event not resolved yet
ERR-NO-BET (u132)	No bet found for user
ERR-ZERO-BET (u133)	Bet amount cannot be zero
ERR-NOT-AUTHORIZED (u140)	Unauthorized operation
Usage
Admin creates an event with unique ID
Users place bets on yes/no outcomes
Admin resolves event with oracle input
Winners claim their proportional share
Platform fees can be withdrawn by admin
