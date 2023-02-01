# @version 0.3.7

"""
@title BUCK Stablecoin Minter
@license MIT
@author TeunK97
@notice Mint a stablecoin backed by CRV
@dev Sample implementation of an ERC20 backed stablecoin
"""

import stablecoin.Token as Token
from vyper.interfaces import ERC20

# Interfaces
interface CRVOracle:
    def price_oracle() -> uint256: view

interface ETHOracle:
    def price_oracle(arg: uint256) -> uint256: view

struct Loan:
    liquidation_price: uint256
    deposit_amount: uint256

event Liquidation:
    user: address
    loan: Loan



# Token addresses
stablecoin: public(Token)  # $buckUSD
lending_token: public(ERC20)  # $CRV

# Oracle addresses
crv_eth_oracle: public(CRVOracle)
eth_usd_oracle: public(ETHOracle)

# Collateralization
collateral_pct: public(uint256)
open_loans: public(HashMap[address, Loan])


@external
def __init__(token_address: address, lending_token_address: address):
    # Set Tokens
    self.lending_token = ERC20(lending_token_address)
    self.stablecoin = Token(token_address)

    # Set Oracles
    self.crv_eth_oracle = CRVOracle(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511)
    self.eth_usd_oracle = ETHOracle(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46)

    self.collateral_pct = 10 ** 18 * 4 / 5

@internal
@view
def _price_usd() -> uint256:
    token_price_eth: uint256 = self.crv_eth_oracle.price_oracle()
    eth_price_usd: uint256 = self.eth_usd_oracle.price_oracle(1)
    return token_price_eth * eth_price_usd / 10 ** 18

@internal
@view
def _get_dy(quantity: uint256) -> uint256:
    liq_price: uint256 = self._price_usd() * self.collateral_pct / 10 ** 18  
    return quantity * liq_price / 10 ** 18  

@internal
@view
def _repay_amount(addr: address) -> uint256:
    loan: Loan = self.open_loans[addr]
    return loan.liquidation_price * loan.deposit_amount / 10 ** 18

@internal
@view
def _can_liquidate(user: address) -> bool:
    return self._price_usd() < self.open_loans[user].liquidation_price

@external
@view
def get_dy(quantity: uint256) -> uint256:
    """
    @notice Get the amount of stablecoins for a deposit.
    @param quantity The amount of collateral tokens deposited. 
    @return Number of stablecoins returned
    """
    return self._get_dy(quantity)

@external
@view
def price_usd() -> uint256:
    """
    @notice Price oracle reading for token price in usd
    @return USD price, 18 decimals
    """
    return self._price_usd()

@external
@view
def repay_amount(addr: address) -> uint256:
    """
    @notice Get repay amount.
    @param addr Address to look up
    @return Amount of collateral tokens required to repay the loan.
    """
    return self._repay_amount(addr)

@external
def mint(quantity: uint256):
    """
    @notice Intended to mint stablecoins with collateral.
    @param quantity Quantitiy to mint. 
    """
    assert self.lending_token.allowance(msg.sender, self) >= quantity, "Lacks Allowance"
    assert self.lending_token.balanceOf(msg.sender) >= quantity, "Lacks Balance"
    self.lending_token.transferFrom(msg.sender, self, quantity)
    self.stablecoin.mint(msg.sender, self._get_dy(quantity))
    liq_price: uint256 = self._price_usd() * self.collateral_pct / 10 ** 18
    self.open_loans[msg.sender] = Loan({liquidation_price: liq_price, deposit_amount: quantity})

@external
def repay():
    """
    @notice Repay loan in full.
    @dev Will revert if the user lacks approval or balance to repay.
    """
    # Checks
    user: address = msg.sender
    assert self.stablecoin.balanceOf(user) >= self._repay_amount(user)

    # Try to transfer stablecoins
    self.stablecoin.transferFrom(user, self, self._repay_amount(user))

    # Clear out the loan
    quantity: uint256 = self.open_loans[user].deposit_amount
    self.open_loans[user] = Loan({liquidation_price: 0, deposit_amount: 0})

    # Return users' collateral
    self.lending_token.transfer(user, quantity)

@external
@view
def can_liquidate(user: address) -> bool:
    """
    @notice Checks whether a given user is subject for liquidation.
    @param user Address of user to check.
    @return True or False.
    """
    return self._can_liquidate(user)

@external
def liquidate(user: address):
    """
    @notice External function that can be called by anyone to liquidate a given user.
    @param user Address that needs to be liquidated.
    """
    # verify price is below liquidition
    assert self._can_liquidate(user)

    # clear out loan data
    log Liquidation(user, self.open_loans[user])
    self.open_loans[user] = Loan({liquidation_price: 0, deposit_amount: 0})

    # liquidate
    transfer_val: uint256 = self.open_loans[user].deposit_amount
    self.lending_token.transfer(msg.sender, transfer_val)
