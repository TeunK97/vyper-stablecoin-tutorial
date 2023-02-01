from ape import *
import pytest

def test_repay_exists(minter):
    assert hasattr(minter, "repay_amount")

def test_open_loan_exists(minter):
    assert hasattr(minter, "open_loans")

def test_repay_amount_works(minter, owner, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, sender=owner)
    expected_price = minter.price_usd() * 0.8 / 10**18
    assert round(minter.repay_amount(owner.address) / 10**18, 10) == round(
        expected_price, 10
    )

def test_open_loan_works(minter, owner, is_forked):
    if not is_forked:
        pytest.skip()
    quantity = 10**18
    minter.mint(quantity, sender=owner)

   # Test Liquidation Price
    assert round(minter.open_loans(owner.address)[0] / 10**18, 5) == round(
        minter.price_usd() * 0.8 / 10**18, 5
    )

    # Check Deposit Amount
    assert minter.open_loans(owner.address)[1] == quantity

def test_repay_works(minter, owner, is_forked, token, collateral):
    if not is_forked:
        pytest.skip()
    quantity = 10 ** 18

    init_collat = collateral.balanceOf(owner.address)
    init_token = token.balanceOf(owner.address)
    expected = minter.get_dy(quantity)

    # collateral.approve(minter.address, quantity, sender=owner)
    minter.mint(quantity, sender=owner)

    assert token.balanceOf(owner.address) == init_token + expected
    assert collateral.balanceOf(owner.address) == init_collat - quantity

    token.approve(minter.address, token.balanceOf(owner.address), sender=owner)
    minter.repay(sender=owner)

    assert token.balanceOf(owner.address) == init_token
    assert collateral.balanceOf(owner.address) == init_collat

def test_liquidate_event(minter, owner, alice, is_forked, token, collateral):
    if not is_forked:
        pytest.skip()
    
    quantity = 10 ** 18
    init_crv = collateral.balanceOf(alice.address)
    init_token = token.balanceOf(alice.address)
    expected = minter.get_dy(quantity)

    collateral.approve(minter.address, quantity, user=alice)
    


    
