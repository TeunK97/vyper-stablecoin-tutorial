from ape import reverts
import pytest

def test_minter_deployed(minter):
    assert hasattr(minter, "mint")

def test_token_balance_update_on_mint(token, minter, owner, collateral):
    quantity = 10
    initial_balance = token.balanceOf(owner.address)
    minter.mint(quantity, sender=owner)
    assert token.balanceOf(owner.address) == initial_balance + (quantity * (minter.collateral_pct() / 10 ** 18))

def test_total_token_supply_update_on_mint(token, minter, owner, collateral):
    quantity = 10
    total_supply = token.totalSupply()
    minter.mint(quantity, sender=owner)
    assert token.totalSupply() == total_supply + (quantity * (minter.collateral_pct() / 10 ** 18))

def test_owner_can_set_minter(token, owner, receiver, minter):
    assert token.minter() == minter.address
    assert token.minter() != receiver.address

    token.setMinter(receiver.address, sender=owner)
    assert token.minter() == receiver.address

def test_nonowner_cannot_set_minter(token, alice, receiver):
    assert token.owner() != alice.address
    with reverts("Access is denied."):
        token.setMinter(receiver.address, sender=alice)


def test_nonminter_cannot_mint(token, alice):
    assert token.owner() != alice.address and token.minter() != alice.address
    with reverts():
        token.mint(alice.address, 10**18, sender=alice)

def test_collateral_transfers_on_mint(token, collateral, owner, minter):
    init_bal = collateral.balanceOf(owner.address)
    minter.mint(10, sender=owner)
    assert collateral.balanceOf(owner.address) < init_bal